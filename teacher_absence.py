"""
Gr0ve Teacher Absence Scraper — GitHub Actions version.

Uses real Playwright + Chromium (confirmed necessary: Google rejects
cookie-replay from plain HTTP clients like `requests`/`fetch` for this
doc, but accepts the same cookies from an actual browser engine).

Runs as a single-shot script triggered by a GitHub Actions scheduled
workflow (see .github/workflows/scrape.yml) — no long-running process,
no server to maintain.

IMPORTANT — statelessness: GitHub Actions runners are ephemeral, so there
is no local disk to persist a "last known state" cache between runs.
Firestore's existing `public_data/teacher_absences` document IS that
state — we read it back at the start of each run instead of a local
cache file. FCM tokens are queried fresh each run rather than cached,
since a Firestore read at this frequency is cheap and it avoids a whole
class of "stale cache on a fresh container" bugs.
"""

from __future__ import annotations

import hashlib
import json
import os
import random
from datetime import datetime
from typing import Dict, List, Optional

import pytz
from playwright.sync_api import sync_playwright, TimeoutError as PlaywrightTimeoutError

import firebase_admin
from firebase_admin import credentials, firestore, messaging


# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

GOOGLE_DOC_URL = "https://docs.google.com/document/d/e/2PACX-1vRkhySmwAiTtY88tcshckpV4F0vRrULccaGrYl_Sf2ubWpyyXA4l8c-KAOuMzSwFe-qyAQhLqXzVsbA/pub"

FIREBASE_CONFIG = os.path.join(SCRIPT_DIR, "firebase.json")
CHROME_STATE_PATH = os.path.join(SCRIPT_DIR, "chrome_state.json")

TIMEZONE = pytz.timezone("US/Eastern")
START_HOUR = 7
END_HOUR = 17

NAV_TIMEOUT_MS = 30_000
TABLE_WAIT_TIMEOUT_MS = 15_000

FUN_TEACHER_MESSAGES = [
    "Did your prayers to the Almighty Gr0ve Keeper go unanswered? \U0001f64f",
    "New absences detected. Time to plan your day? \U0001f4cb",
    "A wild substitute has appeared! \U0001f3ae",
    "Teacher update incoming! Stay in the know. \U0001f96f",
    "Something's different on the absence board... \U0001f50d",
    "Teacher changes detected! Stay alert, Grove. \U0001f6a8",
    "Fresh info on the teacher front. Knowledge is power! \u26a1\ufe0f",
    "The absence lottery has been updated! \U0001f39f\ufe0f",
    "Teacher shuffle in progress... check the app! \U0001f0cf",
    "The Gr0ve gods have spoken... and someone called out. \U0001f33f",
    "Teacher status changed. Chaos level rising. \U0001f4c8",
    "Substitute spotted roaming the halls. Proceed carefully. \U0001f575\ufe0f",
    "The absence board has shifted once again... \U0001f504",
    "Looks like the teacher roulette wheel spun again. \U0001f3a1",
    "Fresh teacher intel just dropped. Stay sharp. \U0001f9e0",
    "An unexpected teacher plot twist has appeared. \U0001f3ac",
    "Schedule disturbance detected in the Gr0ve ecosystem. \U0001f331",
    "Another day, another mysterious absence. \U0001f440",
    "The substitute economy is booming today. \U0001f4bc",
    "Teacher migration patterns have changed. \U0001f4e1",
    "Alert: the classroom meta has shifted. \u26a0\ufe0f",
    "Someone vanished from the roster again. \U0001fae5",
    "Teacher swap detected. Adapt accordingly. \U0001f9e9",
    "The absence gods demand you check the app. \U0001f4f1",
    "Faculty shuffle underway. Expect the unexpected. \U0001f3b2",
    "A new challenger enters the classroom. \U0001f94a",
    "Attendance anomalies detected across the district. \U0001f4ca",
    "The board has been updated. Fate awaits. \U0001f52e",
    "Classroom conditions are evolving in real time. \U0001f32a\ufe0f",
]

DEBUG_HTML_PATH = os.path.join(SCRIPT_DIR, "debug_last_page.html")
DEBUG_META_PATH = os.path.join(SCRIPT_DIR, "debug_last_response.json")

ALLOW_USER_TOKEN_SCAN = os.getenv("GR0VE_ALLOW_USER_TOKEN_SCAN", "").lower() in {
    "1",
    "true",
    "yes",
    "on",
}


cred = credentials.Certificate(FIREBASE_CONFIG)
firebase_admin.initialize_app(cred)

db = firestore.client()


# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------

def log(message: str, level="INFO"):
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"[{timestamp}] [{level}] {message}")


# ---------------------------------------------------------------------------
# Text / hashing helpers
# ---------------------------------------------------------------------------

def normalize_text(text: str) -> str:
    return " ".join(text.replace("\n", " ").split()).strip()


def compute_hash(data: Dict[str, str]) -> str:
    payload = json.dumps(data, sort_keys=True)
    return hashlib.sha256(payload.encode()).hexdigest()


def apply_special_overrides(absences: Dict[str, str]) -> Dict[str, str]:
    for teacher in list(absences.keys()):
        if "bonanomi" in teacher.lower():
            absences[teacher] = "1-5, 7-9"
            log(f"Override applied: {teacher} -> 1-5, 7-9")
    return absences


# ---------------------------------------------------------------------------
# Firestore-backed "previous state" (replaces the local cache file)
# ---------------------------------------------------------------------------

def get_previous_firestore_state() -> Optional[Dict]:
    """
    Reads back public_data/teacher_absences instead of a local cache file —
    there's no persistent disk between GitHub Actions runs, so Firestore
    itself is the only durable place "what we uploaded last" can live.
    """
    try:
        snap = db.collection("public_data").document("teacher_absences").get()
        if not snap.exists:
            log("No previous Firestore document found (first run)")
            return None
        return snap.to_dict()
    except Exception as e:
        log(f"Could not read previous Firestore state: {e}", "WARNING")
        return None


def data_changed(new_absences: Dict[str, str], previous: Optional[Dict]) -> bool:
    if not previous or "hash" not in previous:
        return True
    return previous["hash"] != compute_hash(new_absences)


def _save_debug_artifacts(html: Optional[str], meta: Dict):
    try:
        if html is not None:
            with open(DEBUG_HTML_PATH, "w", encoding="utf-8") as f:
                f.write(html)
        with open(DEBUG_META_PATH, "w", encoding="utf-8") as f:
            json.dump(meta, f, indent=2)
        log(f"Saved debug artifacts -> {DEBUG_HTML_PATH}, {DEBUG_META_PATH}")
    except Exception as e:
        log(f"Could not write debug artifacts: {e}", "WARNING")


# ---------------------------------------------------------------------------
# Scraping — real Chromium via Playwright (confirmed necessary; requests/
# fetch get an auth wall from Google regardless of cookie validity)
# ---------------------------------------------------------------------------

def _looks_like_login_wall(html: str) -> bool:
    """
    Locale-independent detection. Google's cookie-gated-doc auth wall
    renders visible text in whatever locale it infers ("Sign in" vs.
    "Anmelden" etc.), so don't key off English strings — key off the
    template's structural markers instead, which don't change with locale.
    """
    lowered = html.lower()
    if "<table" in lowered:
        return False
    markers = ("accounts.google.com/servicelogin", "requeststorageaccess", "document-root")
    return any(marker in lowered for marker in markers)


def scrape_table_from_google_doc() -> Dict[str, str]:
    if not os.path.exists(CHROME_STATE_PATH):
        log(f"Missing {CHROME_STATE_PATH}", "ERROR")
        return {}

    absences: Dict[str, str] = {}

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        try:
            context = browser.new_context(storage_state=CHROME_STATE_PATH)
            page = context.new_page()

            log("Requesting published Google Doc...")

            try:
                page.goto(GOOGLE_DOC_URL, timeout=NAV_TIMEOUT_MS, wait_until="domcontentloaded")
            except PlaywrightTimeoutError as e:
                log(f"Navigation timed out: {e}", "ERROR")
                _save_debug_artifacts(None, {"note": f"navigation timeout: {e}"})
                return {}

            try:
                page.wait_for_selector("table", timeout=TABLE_WAIT_TIMEOUT_MS)
            except PlaywrightTimeoutError:
                # No table in time — could be an empty doc, or an auth wall.
                # Fall through and let the content check below decide.
                pass

            html = page.content()

            if _looks_like_login_wall(html):
                log(
                    "Response looks like a login/consent page, not the document. "
                    "Cookies are likely expired — re-run your login-capture script "
                    "and update the CHROME_STATE_JSON secret.",
                    "ERROR",
                )
                _save_debug_artifacts(html, {"note": "auth wall shown even to real browser"})
                return {}

            tables = page.query_selector_all("table")

            if not tables:
                log("No tables found", "ERROR")
                _save_debug_artifacts(html, {"note": "200 OK but no <table> found"})
                return {}

            log(f"Found {len(tables)} table(s)")

            for table_index, table in enumerate(tables):
                rows = table.query_selector_all("tr")
                log(f"Parsing table {table_index + 1} ({len(rows)} rows)")

                for row in rows:
                    cells = row.query_selector_all("td, th")

                    row_data = [normalize_text(cell.inner_text() or "") for cell in cells]

                    if len(row_data) < 2:
                        continue

                    teacher, status = row_data[0], row_data[1]

                    if not teacher or not status:
                        continue
                    if teacher.lower() == "teacher":
                        continue

                    absences[teacher] = status
                    print(f"\u2713 {teacher} -> {status}")

            _save_debug_artifacts(html, {"note": "successful parse"})

        finally:
            browser.close()

    absences = apply_special_overrides(absences)
    log(f"Parsed {len(absences)} absences")

    return absences


# ---------------------------------------------------------------------------
# FCM tokens (queried fresh each run — no persistent cache on ephemeral runners)
# ---------------------------------------------------------------------------

def get_all_fcm_tokens() -> List[str]:
    tokens = []

    try:
        docs = db.collection("notification_tokens").stream()

        for doc in docs:
            data = doc.to_dict()
            if isinstance(data.get("token"), str):
                tokens.append(data["token"])
            if isinstance(data.get("tokens"), list):
                tokens.extend(data["tokens"])

        if not tokens and ALLOW_USER_TOKEN_SCAN:
            log("No notification token index found; falling back to users scan", "WARNING")
            for doc in db.collection("users").stream():
                data = doc.to_dict() or {}
                if isinstance(data.get("fcmToken"), str):
                    tokens.append(data["fcmToken"])
                if isinstance(data.get("fcmTokens"), list):
                    tokens.extend(data["fcmTokens"])

        unique_tokens = list(set(tokens))
        log(f"Found {len(unique_tokens)} unique FCM tokens")
        return unique_tokens

    except Exception as e:
        log(f"Error fetching tokens: {e}", "ERROR")
        return []


def push_enabled() -> bool:
    return os.getenv("GR0VE_SEND_PUSH", "").lower() not in {"0", "false", "no", "off"}


def send_teacher_absence_notification(tokens: List[str]):
    if not tokens:
        log("No FCM tokens found", "WARNING")
        return

    success = 0
    failure = 0

    body_text = random.choice(FUN_TEACHER_MESSAGES)

    for token in tokens:
        try:
            message = messaging.Message(
                notification=messaging.Notification(
                    title="\U0001f9d1\u200d\U0001f3eb Teacher Absence Update",
                    body=body_text,
                ),
                data={"payload": "teacher_absence"},
                token=token,
                android=messaging.AndroidConfig(
                    priority="high",
                    notification=messaging.AndroidNotification(channel_id="gr0ve_channel"),
                ),
                apns=messaging.APNSConfig(
                    payload=messaging.APNSPayload(
                        aps=messaging.Aps(
                            alert=messaging.ApsAlert(
                                title="\U0001f9d1\u200d\U0001f3eb Teacher Absence Update",
                                body=body_text,
                            ),
                            sound="default",
                        ),
                    ),
                ),
            )
            messaging.send(message)
            success += 1
        except Exception:
            failure += 1

    log(f'Notifications sent: {success} using message: "{body_text}"')
    if failure:
        log(f"Failed notifications: {failure}", "WARNING")


# ---------------------------------------------------------------------------
# Firestore upload
# ---------------------------------------------------------------------------

def upload_absences(absences: Dict[str, str], send_push: bool = True) -> bool:
    if not absences:
        log("No absences to upload", "WARNING")
        return False

    hash_value = compute_hash(absences)

    payload = {
        "date": datetime.now().strftime("%B %d, %Y"),
        "teachers": absences,
        "hash": hash_value,
        "lastUpdated": firestore.SERVER_TIMESTAMP,
        "uploadedBy": "auto_scraper",
    }

    try:
        db.collection("public_data").document("teacher_absences").set(payload)
        log(f"Uploaded {len(absences)} absences")

        if send_push and push_enabled():
            tokens = get_all_fcm_tokens()
            send_teacher_absence_notification(tokens)
        elif not send_push:
            log("Push notifications skipped for initial bootstrap upload")
        else:
            log("Push notifications disabled")

        return True

    except Exception as e:
        log(f"Upload failed: {e}", "ERROR")
        return False


# ---------------------------------------------------------------------------
# Orchestration
# ---------------------------------------------------------------------------

def check_and_update():
    log("=" * 80)
    log("Running scheduled scrape")
    log("=" * 80)

    absences = scrape_table_from_google_doc()

    if not absences:
        log("No absences parsed", "WARNING")
        return

    previous = get_previous_firestore_state()
    had_previous = previous is not None

    if not data_changed(absences, previous):
        log("No changes detected")
        return

    log("Changes detected")
    upload_absences(absences, send_push=had_previous)
    log("=" * 80)


def _within_tracking_window(now: datetime) -> bool:
    if now.weekday() > 4:
        return False
    return START_HOUR <= now.hour < END_HOUR


def main():
    print("\n" + "=" * 80)
    print("GR0VE AUTO TEACHER ABSENCE SCRAPER (GitHub Actions / Playwright)")
    print("=" * 80)

    now = datetime.now(TIMEZONE)

    if not _within_tracking_window(now):
        log(f"Outside tracking window ({now.strftime('%I:%M %p %Z')}). Exiting.")
        return

    try:
        check_and_update()
    except Exception as e:
        log(f"Run error: {e}", "ERROR")
        raise  # non-zero exit so the Actions run is visibly marked failed


if __name__ == "__main__":
    main()