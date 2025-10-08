package com.example.hacwidd

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import es.antonborri.home_widget.HomeWidgetPlugin

/**
 * A broadcast receiver to monitor and log widget data changes
 * This will help debug widget update issues
 */
class WidgetDataDebugReceiver : BroadcastReceiver() {
    private val TAG = "WidgetDataDebug"

    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "Debug receiver triggered with action: ${intent.action}")
        
        // Log all shared preference data
        try {
            val sharedPrefs = HomeWidgetPlugin.getData(context)
            Log.d(TAG, "🔍 WIDGET DATA DUMP - START")
            
            if (sharedPrefs.all.isEmpty()) {
                Log.d(TAG, "  ⚠️ NO DATA FOUND IN SHARED PREFERENCES")
            } else {
                sharedPrefs.all.forEach { (key, value) ->
                    Log.d(TAG, "  📊 $key = $value")
                }
            }
            
            Log.d(TAG, "🔍 WIDGET DATA DUMP - END")
        } catch (e: Exception) {
            Log.e(TAG, "⚠️ Error accessing SharedPreferences: ${e.message}", e)
        }
        
        // Force update of both widget types
        try {
            val appWidgetManager = android.appwidget.AppWidgetManager.getInstance(context)
            
            // Update HacwiddWidgetProvider
            val hacwiddIds = appWidgetManager.getAppWidgetIds(
                android.content.ComponentName(context, HacwiddWidgetProvider::class.java)
            )
            
            if (hacwiddIds.isNotEmpty()) {
                Log.d(TAG, "Forcing update of ${hacwiddIds.size} HacwiddWidgetProvider widgets")
                val widgetProvider = HacwiddWidgetProvider()
                widgetProvider.onUpdate(context, appWidgetManager, hacwiddIds)
            } else {
                Log.d(TAG, "⚠️ No HacwiddWidgetProvider widgets found")
            }
            
            // Update AppWidgetProvider
            val appIds = appWidgetManager.getAppWidgetIds(
                android.content.ComponentName(context, AppWidgetProvider::class.java)
            )
            
            if (appIds.isNotEmpty()) {
                Log.d(TAG, "Forcing update of ${appIds.size} AppWidgetProvider widgets")
                val appProvider = AppWidgetProvider()
                appProvider.onUpdate(context, appWidgetManager, appIds)
            } else {
                Log.d(TAG, "⚠️ No AppWidgetProvider widgets found")
            }
            
            if (hacwiddIds.isEmpty() && appIds.isEmpty()) {
                Log.w(TAG, "❌ NO WIDGETS FOUND TO UPDATE - make sure widgets are added to home screen")
            }
        } catch (e: Exception) {
            Log.e(TAG, "⚠️ Error forcing widget update: ${e.message}", e)
        }
        
        // Also try direct view update for debugging purposes when using our custom action
        if (intent.action == "com.example.hacwidd.DEBUG_WIDGET_UPDATE") {
            try {
                Log.d(TAG, "Trying direct view update for all widgets as last resort")
                
                val appWidgetManager = android.appwidget.AppWidgetManager.getInstance(context)
                val widgetIds = appWidgetManager.getInstalledProviders()
                    .filter { it.provider.packageName == context.packageName }
                    .flatMap { appWidgetManager.getAppWidgetIds(it.provider).toList() }
                
                if (widgetIds.isNotEmpty()) {
                    Log.d(TAG, "Found ${widgetIds.size} total widgets to update")
                    
                    for (widgetId in widgetIds) {
                        // Create views and update directly
                        val views = android.widget.RemoteViews(context.packageName, R.layout.hacwidd_widget_layout)
                        views.setTextViewText(R.id.widget_title, "UPDATED!")
                        views.setTextViewText(R.id.last_updated, "DEBUG: ${java.util.Date()}")
                        
                        // Use some bright colors for the cells to make changes obvious
                        for (i in 1..28) {
                            val cellId = context.resources.getIdentifier("cell_$i", "id", context.packageName)
                            if (cellId != 0) {
                                val color = when (i % 5) {
                                    0 -> 0xFFFF0000.toInt() // Red
                                    1 -> 0xFF00FF00.toInt() // Green
                                    2 -> 0xFF0000FF.toInt() // Blue
                                    3 -> 0xFFFFFF00.toInt() // Yellow
                                    else -> 0xFFFF00FF.toInt() // Magenta
                                }
                                views.setInt(cellId, "setBackgroundColor", color)
                            }
                        }
                        
                        // Apply update
                        appWidgetManager.updateAppWidget(widgetId, views)
                        Log.d(TAG, "Direct update applied to widget ID: $widgetId")
                    }
                } else {
                    Log.w(TAG, "❌ No widgets found for direct update")
                }
            } catch (e: Exception) {
                Log.e(TAG, "⚠️ Error in direct widget update: ${e.message}", e)
            }
        }
    }
}