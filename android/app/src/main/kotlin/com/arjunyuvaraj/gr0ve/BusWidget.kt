package com.arjunyuvaraj.gr0ve

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import org.json.JSONArray

// ── AppWidgetProvider ─────────────────────────────────────────────────────────

class BusWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (id in appWidgetIds) {
            updateBusWidget(context, appWidgetManager, id)
        }
    }

    companion object {
        internal const val PREFS = "HomeWidgetPreferences"
        internal const val KEY   = "bus_data"

        fun updateBusWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
        ) {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val raw   = prefs.getString(KEY, null)
            val buses = parseBuses(raw)

            val views = RemoteViews(context.packageName, R.layout.widget_bus)

            if (buses.isEmpty()) {
                views.setViewVisibility(R.id.bus_empty_text, android.view.View.VISIBLE)
                views.setViewVisibility(R.id.bus_list_view,  android.view.View.GONE)
            } else {
                views.setViewVisibility(R.id.bus_empty_text, android.view.View.GONE)
                views.setViewVisibility(R.id.bus_list_view,  android.view.View.VISIBLE)

                val intent = Intent(context, BusWidgetService::class.java).apply {
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                }
                views.setRemoteAdapter(R.id.bus_list_view, intent)
                views.setEmptyView(R.id.bus_list_view, R.id.bus_empty_text)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
            appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetId, R.id.bus_list_view)
        }

        internal fun parseBuses(raw: String?): List<BusEntry> {
            if (raw == null) return emptyList()
            return try {
                val arr = JSONArray(raw)
                (0 until arr.length()).map { i ->
                    val obj = arr.getJSONObject(i)
                    BusEntry(
                        code   = obj.optString("code", "?"),
                        town   = obj.optString("town", ""),
                        status = obj.optString("status", ""),
                    )
                }
            } catch (e: Exception) { emptyList() }
        }

        internal fun busColor(context: Context, status: String): Int =
            when (status.lowercase()) {
                "arrived" -> context.getColor(R.color.gr0ve_green)
                ""        -> context.getColor(R.color.gr0ve_red)
                else      -> context.getColor(R.color.gr0ve_amber)
            }

        internal fun busStatusLabel(status: String): String =
            when (status.lowercase()) {
                "arrived" -> "Arrived"
                ""        -> "Unknown"
                else      -> status
            }
    }
}

internal data class BusEntry(val code: String, val town: String, val status: String)

// ── RemoteViewsService ────────────────────────────────────────────────────────

class BusWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory =
        BusRemoteViewsFactory(applicationContext)
}

// ── RemoteViewsFactory ────────────────────────────────────────────────────────

class BusRemoteViewsFactory(private val context: Context) : RemoteViewsService.RemoteViewsFactory {

    private var buses: List<BusEntry> = emptyList()

    override fun onCreate() { load() }
    override fun onDataSetChanged() { load() }
    override fun onDestroy() {}

    private fun load() {
        val prefs = context.getSharedPreferences(BusWidget.PREFS, Context.MODE_PRIVATE)
        buses = BusWidget.parseBuses(prefs.getString(BusWidget.KEY, null))
    }

    override fun getCount() = buses.size
    override fun getItemId(position: Int) = position.toLong()
    override fun hasStableIds() = true
    override fun getLoadingView() = null
    override fun getViewTypeCount() = 1

    override fun getViewAt(position: Int): RemoteViews {
        val bus   = buses[position]
        val views = RemoteViews(context.packageName, R.layout.widget_bus_item)

        views.setTextViewText(R.id.bus_item_code,   bus.code)
        views.setTextViewText(R.id.bus_item_town,   bus.town)
        views.setTextViewText(R.id.bus_item_status, BusWidget.busStatusLabel(bus.status))
        views.setInt(R.id.bus_item_code,   "setTextColor", BusWidget.busColor(context, bus.status))
        views.setInt(R.id.bus_item_status, "setTextColor", BusWidget.busColor(context, bus.status))

        return views
    }
}