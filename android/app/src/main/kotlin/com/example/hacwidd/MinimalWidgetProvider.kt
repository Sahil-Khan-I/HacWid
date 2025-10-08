package com.example.hacwidd

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import android.widget.RemoteViews

/**
 * MINIMAL widget provider - absolutely simplest version possible
 * This MUST work or there's a device/Android issue
 */
class MinimalWidgetProvider : AppWidgetProvider() {
    private val TAG = "MinimalWidget"
    private val PREFS_NAME = "HomeWidgetPreferences"
    
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        Log.d(TAG, "🚀 MinimalWidget onUpdate called")
        
        for (widgetId in appWidgetIds) {
            Log.d(TAG, "Updating widget ID: $widgetId")
            
            try {
                // Create the simplest possible widget
                val views = RemoteViews(context.packageName, R.layout.minimal_widget_layout)
                
                // Try to read from SharedPreferences
                val prefs: SharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                val streak = prefs.getString("streak", "N/A") ?: "N/A"
                val today = prefs.getString("today", "N/A") ?: "N/A"
                
                Log.d(TAG, "Data: streak=$streak, today=$today")
                
                // Set text
                views.setTextViewText(R.id.widget_status, "Widget Working!")
                views.setTextViewText(R.id.widget_streak_value, streak)
                views.setTextViewText(R.id.widget_today_value, today)
                
                // Update widget
                appWidgetManager.updateAppWidget(widgetId, views)
                Log.d(TAG, "✅ Widget $widgetId updated successfully")
                
            } catch (e: Exception) {
                Log.e(TAG, "❌ Error: ${e.message}", e)
            }
        }
    }
    
    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        Log.d(TAG, "✅ MinimalWidget ENABLED")
    }
    
    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        Log.d(TAG, "❌ MinimalWidget DISABLED")
    }
}
