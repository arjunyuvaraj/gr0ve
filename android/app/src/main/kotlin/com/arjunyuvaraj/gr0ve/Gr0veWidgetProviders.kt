package com.arjunyuvaraj.gr0ve

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import org.json.JSONObject
import kotlin.math.max

private const val GREEN = "#33E580"
private const val RED = "#F87070"
private const val AMBER = "#FABF24"
private const val ACCENT = "#4A90D9"

private fun launchIntent(context: Context) =
    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)

private fun rowsFor(options: Bundle?): Int {
    val height = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT) ?: 110
    return max(1, ((height - 56) / 56).coerceAtMost(5))
}

private fun JSONArray.objects(): List<JSONObject> =
    (0 until length()).mapNotNull { index -> optJSONObject(index) }

private fun prefsArray(widgetData: SharedPreferences, key: String): List<JSONObject> {
    val raw = widgetData.getString(key, "[]") ?: "[]"
    return try {
        JSONArray(raw).objects()
    } catch (_: Exception) {
        emptyList()
    }
}

private fun prefsObject(widgetData: SharedPreferences, key: String): JSONObject {
    val raw = widgetData.getString(key, "{}") ?: "{}"
    return try {
        JSONObject(raw)
    } catch (_: Exception) {
        JSONObject()
    }
}

class Gr0veBusWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_bus)
            views.setOnClickPendingIntent(R.id.widget_root, launchIntent(context))

            val buses = prefsArray(widgetData, "bus_data")
            views.removeAllViews(R.id.bus_items)
            views.setViewVisibility(R.id.bus_empty_text, if (buses.isEmpty()) View.VISIBLE else View.GONE)

            val rowCount = rowsFor(appWidgetManager.getAppWidgetOptions(widgetId))
            buses.take(rowCount).forEach { bus ->
                val row = RemoteViews(context.packageName, R.layout.widget_bus_item)
                val code = bus.optString("code").ifBlank { "?" }
                val status = bus.optString("status", "Not here yet")
                val color = if (status.equals("Arrived", true)) GREEN else if (code == "?") RED else AMBER

                row.setTextViewText(R.id.bus_item_code, code)
                row.setTextColor(R.id.bus_item_code, Color.parseColor(color))
                row.setTextViewText(R.id.bus_item_town, bus.optString("town"))
                row.setTextViewText(R.id.bus_item_status, status)
                row.setTextColor(R.id.bus_item_status, Color.parseColor(color))
                views.addView(R.id.bus_items, row)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}

class Gr0veTeacherWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_teacher)
            views.setOnClickPendingIntent(R.id.widget_root, launchIntent(context))

            val teachers = prefsArray(widgetData, "teacher_data")
            views.removeAllViews(R.id.teacher_items)
            views.setViewVisibility(
                R.id.teacher_empty_text,
                if (teachers.isEmpty()) View.VISIBLE else View.GONE,
            )

            val rowCount = rowsFor(appWidgetManager.getAppWidgetOptions(widgetId))
            teachers.take(rowCount).forEach { teacher ->
                val row = RemoteViews(context.packageName, R.layout.widget_teacher_item)
                val status = teacher.optString("status", "Present")
                val color = if (status.equals("Present", true)) GREEN else RED

                row.setTextViewText(R.id.teacher_item_name, teacher.optString("name"))
                row.setTextViewText(R.id.teacher_item_dept, teacher.optString("department"))
                row.setTextViewText(R.id.teacher_item_status, status)
                row.setTextColor(R.id.teacher_item_status, Color.parseColor(color))
                row.setInt(R.id.teacher_item_dot, "setColorFilter", Color.parseColor(color))
                views.addView(R.id.teacher_items, row)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}

class Gr0veScheduleWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_schedule)
            views.setOnClickPendingIntent(R.id.widget_root, launchIntent(context))

            val data = prefsObject(widgetData, "schedule_data")
            val phase = data.optString("phase", "pre")
            val label = data.optString("label", "Before school")
            val seconds = data.optInt("secs", 0)
            val progress = (data.optDouble("prog", 0.0) * 100).toInt().coerceIn(0, 100)
            val next = data.optString("next", "")
            val color = when (phase) {
                "done" -> GREEN
                "passing" -> AMBER
                "pre" -> "#8E8E93"
                else -> ACCENT
            }

            views.setTextViewText(R.id.schedule_label, label.uppercase())
            views.setInt(R.id.schedule_dot, "setColorFilter", Color.parseColor(color))
            views.setTextColor(R.id.schedule_countdown, Color.parseColor(color))
            views.setProgressBar(R.id.schedule_progress, 100, progress, false)

            when (phase) {
                "done" -> {
                    views.setTextViewText(R.id.schedule_countdown, "Done")
                    views.setTextViewText(R.id.schedule_subtitle, "School day complete")
                    views.setViewVisibility(R.id.schedule_progress_container, View.GONE)
                }
                "pre" -> {
                    views.setTextViewText(R.id.schedule_countdown, "8:00 AM")
                    views.setTextViewText(R.id.schedule_subtitle, "School starts soon")
                    views.setViewVisibility(R.id.schedule_progress_container, View.GONE)
                }
                "passing" -> {
                    views.setTextViewText(R.id.schedule_countdown, formatSeconds(seconds))
                    views.setTextViewText(R.id.schedule_subtitle, "until $next")
                    views.setViewVisibility(R.id.schedule_progress_container, View.VISIBLE)
                }
                "countdown" -> {
                    views.setTextViewText(R.id.schedule_countdown, formatSeconds(seconds))
                    views.setTextViewText(R.id.schedule_subtitle, "until school")
                    views.setViewVisibility(R.id.schedule_progress_container, View.VISIBLE)
                }
                else -> {
                    views.setTextViewText(R.id.schedule_countdown, formatSeconds(seconds))
                    views.setTextViewText(R.id.schedule_subtitle, "remaining in $label")
                    views.setViewVisibility(R.id.schedule_progress_container, View.VISIBLE)
                }
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}

class Gr0veEventsWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_events)
            views.setOnClickPendingIntent(R.id.widget_root, launchIntent(context))

            val events = prefsArray(widgetData, "events_data")
            views.removeAllViews(R.id.event_items)
            views.setViewVisibility(R.id.events_empty_text, if (events.isEmpty()) View.VISIBLE else View.GONE)

            val rowCount = rowsFor(appWidgetManager.getAppWidgetOptions(widgetId))
            events.take(rowCount).forEach { event ->
                val row = RemoteViews(context.packageName, R.layout.widget_event_item)
                val category = event.optString("category", "event")
                val color = when (category) {
                    "personal" -> AMBER
                    "club" -> GREEN
                    else -> ACCENT
                }

                row.setTextViewText(R.id.event_item_title, event.optString("title"))
                row.setTextViewText(R.id.event_item_category, category.replaceFirstChar { it.uppercase() })
                row.setTextViewText(R.id.event_item_time, event.optString("time", "All day"))
                row.setTextColor(R.id.event_item_time, Color.parseColor(color))
                row.setInt(R.id.event_item_dot, "setColorFilter", Color.parseColor(color))
                views.addView(R.id.event_items, row)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}

private fun formatSeconds(seconds: Int): String {
    val safe = seconds.coerceAtLeast(0)
    val hours = safe / 3600
    val minutes = (safe % 3600) / 60
    val secs = safe % 60
    return if (hours > 0) {
        "%02d:%02d:%02d".format(hours, minutes, secs)
    } else {
        "%02d:%02d".format(minutes, secs)
    }
}
