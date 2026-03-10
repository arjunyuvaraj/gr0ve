package com.arjunyuvaraj.gr0ve

// ══════════════════════════════════════════════════════════════
// Gr0veWidgetProvider.kt
//
// home_widget calls this class when Flutter pushes new data.
// It fans out updates to all three widget types.
//
// In your Flutter code:
//   HomeWidget.registerBackgroundCallback(backgroundCallback);
//   await HomeWidget.saveWidgetData('bus_data', jsonString);
//   await HomeWidget.updateWidget(
//     androidName: 'Gr0veWidgetProvider',
//   );
// ══════════════════════════════════════════════════════════════

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class Gr0veWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences,
    ) {
        // Fan out to each typed widget
        refreshAll(context)
    }

    companion object {
        fun refreshAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)

            // Bus
            val busIds = manager.getAppWidgetIds(
                ComponentName(context, BusWidget::class.java)
            )
            busIds.forEach { BusWidget.updateBusWidget(context, manager, it) }

            // Teacher
            val teacherIds = manager.getAppWidgetIds(
                ComponentName(context, TeacherWidget::class.java)
            )
            teacherIds.forEach { TeacherWidget.updateTeacherWidget(context, manager, it) }

            // Schedule
            val scheduleIds = manager.getAppWidgetIds(
                ComponentName(context, ScheduleWidget::class.java)
            )
            scheduleIds.forEach { ScheduleWidget.updateScheduleWidget(context, manager, it) }
        }
    }
}
