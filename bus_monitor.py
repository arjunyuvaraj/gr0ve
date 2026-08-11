import gspread
from google.oauth2.service_account import Credentials
import firebase_admin
from firebase_admin import credentials, firestore, messaging
import sys
import random
from datetime import datetime
import pytz
import os


SPREADSHEET_ID = '1S5v7kTbSiqV8GottWVi5tzpqLdTrEgWEY4ND4zvyV3o'
WORKSHEET_TITLE = 'Locations'
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
GSHEETS_CREDS_PATH = os.path.join(SCRIPT_DIR, 'gsheets.json')
FIREBASE_CREDS_PATH = os.path.join(SCRIPT_DIR, 'firebase.json')

START_HOUR = 11
END_HOUR = 17
TIMEZONE = pytz.timezone('US/Eastern')

GOODBYE_MESSAGES = [
    "The final bell has spoken. Freedom awaits. \U0001f514",
    "Another school day survives the history books. \U0001f4da",
    "Escape sequence initiated... \U0001f3c3",
    "The buses are hungry. Feed them students. \U0001f68c",
    "You made it out alive. Barely. \U0001f62e\u200d\U0001f4a8",
    "School mode: disabled. \U0001f50c",
    "Time to disappear until tomorrow morning. \U0001f319",
    "The halls grow quiet once more... \U0001f463",
    "Mission complete. Return to base. \U0001f3af",
    "Congratulations on surviving academic combat. \U0001f6e1\ufe0f",
    "The backpack can finally rest. \U0001f392",
    "Dismissal achieved. Go touch grass. \U0001f331",
    "Another productive day of pretending to listen. \U0001f3a7",
    "The cafeteria fades into memory... \U0001f355",
    "You are now entering after-school hours. \u23f0",
    "Your academic responsibilities have expired for today. \U0001f4c4",
    "The great student migration has begun. \U0001f41f",
    "Clocking out of the educational simulation. \U0001f5a5\ufe0f",
    "The school grind pauses... temporarily. \u23f8\ufe0f",
    "Tomorrow's problems are officially tomorrow's problems. \U0001f634",
    "Catch you on the flip side! \U0001f68c",
    "Don't let the bus doors hit ya! \U0001f609",
    "Hope you made today a great day!",
    "Off to find where the sidewalk ends... \U0001f6b6",
    "See ya later, alligator! \U0001f40a",
    "May your commute be short and your snacks be plentiful. \U0001f968",
    "Vanishing into the mist... \U0001f32b\ufe0f",
    "Peace out, scout! \u270c\ufe0f",
    "Remember: A bus in the hand is worth two in the depot. \U0001f68c",
    "Buh-bye now \U0001f44b",
    "Fianlly nap time \U0001f634",
    "Outta here like a bandit! \U0001f920",
    "Making like a tree and leaving... \U0001f333",
    "The final destination awaits! \U0001f3c1",
    "Adios, amigos! Hasta ma\u00f1ana! \u270c\ufe0f",
    "Commencing departure sequence... \U0001f680",
    "Heading for the homestead! \U0001f3e1",
    "Fare thee well, fellow travelers! \U0001f4dc",
    "Gone like the wind! \U0001f4a8",
    "Catch you on the flip side! \U0001f501",
    "Don't miss the bus tomorrow! \u23f0",
    "The journey home begins! \U0001f305",
    "See you on the route again soon! \U0001f4cd",
    "Heading for the sunset! \U0001f307",
    "Vanishing into the horizon... \U0001f32b\ufe0f",
    "Onward to adventure! \U0001f3de\ufe0f",
    "Signing off for the day! \u23f9\ufe0f",
    "Making like a migratory bird and heading south... \U0001f426",
    "The GR0ve gods have granted you freedom! \U0001f64f",
    "Peace out, stay safe on the roads! \U0001f6a6",
    "Catch you on the flip side! \U0001f504",
    "Don't let the doors hit ya! \U0001f44b",
    "Hope you had a great day!",
    "See you on the next leg of the journey! \U0001f5fa\ufe0f",
    "The bus has spoken... time to go! \U0001f68c",
    "Making my exit! \U0001f6aa",
    "Farewell, fellow students! \U0001f393",
]


def init_firebase():
    """Initialize Firebase Admin SDK"""
    try:
        cred = credentials.Certificate(FIREBASE_CREDS_PATH)
        if not firebase_admin._apps:
            firebase_admin.initialize_app(cred)
        print("\u2713 Firebase initialized")
        return firestore.client()
    except Exception as e:
        print(f"\u2717 Error initializing Firebase: {e}")
        sys.exit(1)


def get_current_time():
    return datetime.now(TIMEZONE)


def is_within_window():
    now = get_current_time()
    if now.weekday() > 4:
        return False
    if now.hour < START_HOUR or now.hour >= END_HOUR:
        return False
    return True


def fetch_bus_routes():
    """Fetch bus routes from Google Sheets"""
    try:
        scopes = ['https://www.googleapis.com/auth/spreadsheets.readonly']
        creds = Credentials.from_service_account_file(GSHEETS_CREDS_PATH, scopes=scopes)
        client = gspread.authorize(creds)

        spreadsheet = client.open_by_key(SPREADSHEET_ID)
        worksheet = spreadsheet.worksheet(WORKSHEET_TITLE)
        all_values = worksheet.get_all_values()

        if len(all_values) < 2:
            return {}

        rows_to_process = all_values[1:24]

        routes = {}
        for row in rows_to_process:
            if len(row) >= 2 and row[0].strip():
                location = row[1].strip() or ""
                if location.lower() == 'missing':
                    location = ""
                routes[row[0].strip()] = location

            if len(row) >= 4 and row[2].strip():
                location = row[3].strip() or ""
                if location.lower() == 'missing':
                    location = ""
                routes[row[2].strip()] = location

        return routes
    except Exception as e:
        print(f"\u2717 Error fetching from Sheets: {e}")
        return None


def get_previous_routes_from_firestore(db):
    """
    Reads back public_data/bus_routes instead of a local cache file —
    there's no persistent disk between GitHub Actions runs, so Firestore
    itself is the only durable place "what we had last cycle" can live.
    Returns a plain {town: code} map to match fetch_bus_routes()'s shape.
    """
    try:
        snap = db.collection('public_data').document('bus_routes').get()
        if not snap.exists:
            return {}
        stored_routes = (snap.to_dict() or {}).get('routes', {})
        return {
            town: info.get('code', '')
            for town, info in stored_routes.items()
            if isinstance(info, dict)
        }
    except Exception as e:
        print(f"\u26a0\ufe0f Could not read previous Firestore routes: {e}")
        return {}


def get_starred_user_tokens(db, town):
    """Queried fresh each time — only called on the rare cycle where a
    town's code actually changed, so there's no meaningful cost to not
    caching this on an ephemeral runner."""
    tokens = []
    try:
        docs = (
            db.collection('notification_tokens')
            .where('starredTowns', 'array_contains', town)
            .stream()
        )
        for doc in docs:
            data = doc.to_dict() or {}
            if isinstance(data.get('token'), str):
                tokens.append(data['token'])
            if isinstance(data.get('tokens'), list):
                tokens.extend(data['tokens'])
        return sorted(set(tokens))
    except Exception as e:
        print(f"\u2717 Error fetching starred tokens: {e}")
        return []


def push_enabled():
    return os.getenv("GR0VE_SEND_PUSH", "").lower() not in {"0", "false", "no", "off"}


def send_notification(tokens, town, location):
    """Send FCM notifications for one town's update, batched rather than
    one-by-one — a sequential per-token loop is what caused the teacher
    absence workflow to nearly time out with a larger token list."""
    if not tokens:
        return

    title = "\U0001f68c Bus Update"
    bye_note = random.choice(GOODBYE_MESSAGES)
    body = f"{town}: {location}. {bye_note}"

    def build_message(token):
        return messaging.Message(
            notification=messaging.Notification(title=title, body=body),
            token=token,
            android=messaging.AndroidConfig(
                priority='high',
                notification=messaging.AndroidNotification(channel_id='gr0ve_channel'),
            ),
            apns=messaging.APNSConfig(
                payload=messaging.APNSPayload(
                    aps=messaging.Aps(
                        alert=messaging.ApsAlert(title=title, body=body),
                        sound='default',
                    ),
                ),
            ),
        )

    CHUNK_SIZE = 500  # FCM's per-call cap
    for i in range(0, len(tokens), CHUNK_SIZE):
        chunk = tokens[i:i + CHUNK_SIZE]
        messages = [build_message(token) for token in chunk]
        try:
            response = messaging.send_each(messages)
            print(f"   Sent {response.success_count}/{len(chunk)} to {town}")
        except Exception as e:
            print(f"  \u2717 Batch send failed for {town}: {e}")


def update_firestore(db, routes):
    """Update bus routes in Firestore only when they've actually changed."""
    doc_ref = db.collection('public_data').document('bus_routes')
    old_routes = get_previous_routes_from_firestore(db)

    if old_routes == routes:
        print("\u2713 No bus route changes detected. Skipping Firestore update.")
        return

    for town, code in routes.items():
        old_code = old_routes.get(town)
        if push_enabled() and old_code is not None and code != old_code and code != "":
            print(f"\U0001f514 Change detected for {town}: {old_code} -> {code}")
            tokens = get_starred_user_tokens(db, town)
            if tokens:
                print(f"   Sending to {len(tokens)} users...")
                send_notification(tokens, town, code)

    bus_data = {
        'updated_at': datetime.now().isoformat(),
        'routes': {
            town: {'town': town, 'code': code, 'status': 'Arrived' if code else 'Not here yet'}
            for town, code in routes.items()
        },
    }
    doc_ref.set(bus_data)
    print(f"\u2713 Firestore updated at {bus_data['updated_at']}")


def main():
    print("\U0001f68c gr0ve Bus Monitor (GitHub Actions single-run)")

    if not is_within_window():
        now = get_current_time()
        print(f"Outside operation window ({now.strftime('%a %I:%M %p')}). Exiting.")
        return

    db = init_firebase()

    print(f"\n--- Run at {get_current_time().strftime('%I:%M:%S %p')} ---")

    new_routes = fetch_bus_routes()
    if new_routes is None:
        print("\u2717 Fetch failed, nothing to update this cycle.")
        sys.exit(1)

    update_firestore(db, new_routes)


if __name__ == "__main__":
    main()