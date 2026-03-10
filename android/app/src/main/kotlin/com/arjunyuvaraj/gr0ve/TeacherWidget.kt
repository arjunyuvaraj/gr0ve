package com.arjunyuvaraj.gr0ve

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import org.json.JSONArray

// ── AppWidgetProvider ─────────────────────────────────────────────────────────

class TeacherWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (id in appWidgetIds) {
            updateTeacherWidget(context, appWidgetManager, id)
        }
    }

    companion object {
        internal const val PREFS = "HomeWidgetPreferences"
        internal const val KEY   = "teacher_data"

        fun updateTeacherWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
        ) {
            val prefs    = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val raw      = prefs.getString(KEY, null)
            val teachers = parseTeachers(raw)

            val views = RemoteViews(context.packageName, R.layout.widget_teacher)

            if (teachers.isEmpty()) {
                views.setViewVisibility(R.id.teacher_empty_text, android.view.View.VISIBLE)
                views.setViewVisibility(R.id.teacher_list_view,  android.view.View.GONE)
            } else {
                views.setViewVisibility(R.id.teacher_empty_text, android.view.View.GONE)
                views.setViewVisibility(R.id.teacher_list_view,  android.view.View.VISIBLE)

                val intent = Intent(context, TeacherWidgetService::class.java).apply {
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                }
                views.setRemoteAdapter(R.id.teacher_list_view, intent)
                views.setEmptyView(R.id.teacher_list_view, R.id.teacher_empty_text)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
            appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetId, R.id.teacher_list_view)
        }

        internal fun parseTeachers(raw: String?): List<TeacherEntry> {
            if (raw == null) return emptyList()
            return try {
                val arr = JSONArray(raw)
                (0 until arr.length()).map { i ->
                    val obj = arr.getJSONObject(i)
                    TeacherEntry(
                        name   = obj.optString("name", ""),
                        dept   = obj.optString("department", ""),
                        status = obj.optString("status", "Present"),
                    )
                }
            } catch (e: Exception) { emptyList() }
        }

        internal fun teacherColor(context: Context, status: String): Int =
            if (status.lowercase() == "present")
                context.getColor(R.color.gr0ve_green)
            else
                context.getColor(R.color.gr0ve_red)
    }
}

internal data class TeacherEntry(val name: String, val dept: String, val status: String)

// ── RemoteViewsService ────────────────────────────────────────────────────────

class TeacherWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory =
        TeacherRemoteViewsFactory(applicationContext)
}

// ── RemoteViewsFactory ────────────────────────────────────────────────────────

class TeacherRemoteViewsFactory(private val context: Context) : RemoteViewsService.RemoteViewsFactory {

    private var teachers: List<TeacherEntry> = emptyList()

    override fun onCreate() { load() }
    override fun onDataSetChanged() { load() }
    override fun onDestroy() {}

    private fun load() {
        val prefs = context.getSharedPreferences(TeacherWidget.PREFS, Context.MODE_PRIVATE)
        teachers = TeacherWidget.parseTeachers(prefs.getString(TeacherWidget.KEY, null))
    }

    override fun getCount() = teachers.size
    override fun getItemId(position: Int) = position.toLong()
    override fun hasStableIds() = true
    override fun getLoadingView() = null
    override fun getViewTypeCount() = 1

    override fun getViewAt(position: Int): RemoteViews {
        val teacher = teachers[position]
        val views   = RemoteViews(context.packageName, R.layout.widget_teacher_item)
        val color   = TeacherWidget.teacherColor(context, teacher.status)

        views.setTextViewText(R.id.teacher_item_name,   teacher.name)
        views.setTextViewText(R.id.teacher_item_dept,   teacher.dept)
        views.setTextViewText(R.id.teacher_item_status, teacher.status)
        views.setInt(R.id.teacher_item_dot,    "setColorFilter", color)
        views.setInt(R.id.teacher_item_status, "setTextColor",   color)

        return views
    }
}