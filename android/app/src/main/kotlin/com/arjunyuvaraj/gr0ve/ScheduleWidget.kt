package com.arjunyuvaraj.gr0ve

// ══════════════════════════════════════════════════════════════
// ScheduleWidget.kt
//
// Refreshes every minute via updatePeriodMillis in xml config.
// Flutter writes "schedule_data" JSON via home_widget package.
//
// Payload keys (match Dart side):
//   phase : "pre" | "countdown" | "period" | "passing" | "done"
//   label : String  (e.g. "Period 4")
//   secs  : Int     (seconds remaining)
//   prog  : Double  (0.0 – 1.0 progress through period)
//   next  : String  (next period label, used in passing phase)
// ══════════════════════════════════════════════════════════════

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import org.json.JSONObject

class ScheduleWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (id in appWidgetIds) {
            updateScheduleWidget(context, appWidgetManager, id)
        }
    }

    companion object {
        private const val PREFS = "HomeWidgetPreferences"
        private const val KEY   = "schedule_data"

        fun updateScheduleWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
        ) {
            val prefs   = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val raw     = prefs.getString(KEY, null)
            val payload = parsePayload(raw)

            val phase = payload.optString("phase", "pre")
            val label = payload.optString("label", "")
            val secs  = payload.optInt("secs", 0)
            val prog  = payload.optDouble("prog", 0.0)
            val next  = payload.optString("next", "")

            val views = RemoteViews(context.packageName, R.layout.widget_schedule)

            // ── Phase dot color ────────────────────────────────
            val accentColor = when (phase) {
                "done"    -> context.getColor(R.color.gr0ve_green)
                "passing" -> context.getColor(R.color.gr0ve_amber)
                "pre"     -> context.getColor(android.R.color.darker_gray)
                else      -> context.getColor(R.color.gr0ve_accent)
            }
            views.setInt(R.id.schedule_dot, "setColorFilter", accentColor)

            // ── Label ──────────────────────────────────────────
            views.setTextViewText(
                R.id.schedule_label,
                label.uppercase(),
            )

            // ── Big countdown text ─────────────────────────────
            val countdownText = when (phase) {
                "done"    -> "Done! 🎉"
                "pre"     -> "8:00 AM"
                else      -> fmtSec(secs)
            }
            views.setTextViewText(R.id.schedule_countdown, countdownText)
            views.setInt(R.id.schedule_countdown, "setTextColor", accentColor)

            // ── Subtitle ───────────────────────────────────────
            val subtitle = when (phase) {
                "done"      -> "School's out"
                "pre"       -> "School starts soon"
                "passing"   -> if (next.isNotEmpty()) "→ $next" else "Passing period"
                "period"    -> "remaining in $label"
                "countdown" -> "until school"
                else        -> ""
            }
            views.setTextViewText(R.id.schedule_subtitle, subtitle)

            // ── Progress bar ───────────────────────────────────
            val progressVisible = phase == "period" || phase == "countdown" || phase == "passing"
            views.setViewVisibility(
                R.id.schedule_progress_container,
                if (progressVisible) android.view.View.VISIBLE else android.view.View.GONE,
            )
            if (progressVisible) {
                val pct = if (phase == "passing") 50 else (prog * 100).toInt().coerceIn(0, 100)
                views.setProgressBar(R.id.schedule_progress, 100, pct, false)
                views.setInt(R.id.schedule_progress, "setProgressTintList", accentColor)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun parsePayload(raw: String?): JSONObject {
            if (raw == null) return JSONObject()
            return try { JSONObject(raw) } catch (e: Exception) { JSONObject() }
        }

        private fun fmtSec(s: Int): String {
            val h  = s / 3600
            val m  = (s % 3600) / 60
            val sc = s % 60
            return if (h > 0)
                "%02d:%02d:%02d".format(h, m, sc)
            else
                "%02d:%02d".format(m, sc)
        }
    }
}

/*
 ── MANIFEST SNIPPET ─────────────────────────────────────────────
    <receiver
        android:name=".ScheduleWidget"
        android:exported="true">
        <intent-filter>
            <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
        </intent-filter>
        <meta-data
            android:name="android.appwidget.provider"
            android:resource="@xml/schedule_widget_info" />
    </receiver>
 */
