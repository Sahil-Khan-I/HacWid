package com.example.hacwidd

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.util.Log
import android.widget.RemoteViews
import android.view.View
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONObject
import org.json.JSONException

/**
 * Simple implementation of App Widget functionality for Hacwidd heatmap
 */
class HacwiddWidgetProvider : AppWidgetProvider() {
    private val TAG = "HacwiddWidgetProvider"
    
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        Log.d(TAG, "Widget update called for ${appWidgetIds.size} widgets")
        
        // Get shared preferences from HomeWidgetPlugin
        val widgetData = HomeWidgetPlugin.getData(context)
        
        // Log all available shared preference keys
        Log.d(TAG, "Available SharedPreferences keys in widget provider:")
        widgetData.all.forEach { (key, value) ->
            Log.d(TAG, "  Key: $key, Value: $value")
        }
        
        // Update all widgets
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId, widgetData)
        }
    }
    
    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        Log.d(TAG, "Widget provider enabled - first widget instance added")
    }
    
    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        Log.d(TAG, "Widget provider disabled - last widget instance removed")
    }
    
    /**
     * Update a single widget instance - ultra simplified implementation
     */
    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        widgetData: SharedPreferences
    ) {
        try {
            Log.d(TAG, "Starting widget update for ID: $appWidgetId")
            
            // Log all available shared preference keys for debugging
            Log.d(TAG, "Available SharedPreferences keys:")
            widgetData.all.forEach { (key, value) ->
                Log.d(TAG, "  Key: $key, Value: $value")
            }
            
            // Create remote views for widget layout
            val views = RemoteViews(context.packageName, R.layout.hacwidd_widget_layout)
            
            // Get basic widget data
            val active = widgetData.getString("active", null)
            val timestamp = widgetData.getString("time", null) 
            val streak = widgetData.getString("streak", "0")
            val today = widgetData.getString("today", "0h")
            
            // Format current time 
            val currentTime = java.text.SimpleDateFormat("HH:mm:ss", java.util.Locale.getDefault())
                .format(java.util.Date())
            
            // Set text fields with data from shared preferences
            views.setTextViewText(R.id.widget_title, "Hackatime")
            
            if (active == "true") {
                views.setTextViewText(R.id.slack_id_text, "Active")
            } else {
                views.setTextViewText(R.id.slack_id_text, "Tap to activate")
            }
            
            views.setTextViewText(R.id.last_updated, "Updated: $currentTime")
            views.setTextViewText(R.id.widget_streak_value, streak)
            views.setTextViewText(R.id.widget_today_value, today)
            
            // Add click handler to launch app when widget is clicked
            try {
                // Create an intent that launches the MainActivity
                val intent = Intent(context, MainActivity::class.java).apply {
                    // Add widget URI for tracking 
                    data = Uri.parse("hacwidd://widget")
                    // Add flags for proper launch behavior
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                
                // Get pending intent with proper flags for Android 12+
                val pendingIntentFlags = android.app.PendingIntent.FLAG_UPDATE_CURRENT or 
                                         android.app.PendingIntent.FLAG_IMMUTABLE
                
                val pendingIntent = android.app.PendingIntent.getActivity(
                    context,
                    0,
                    intent,
                    pendingIntentFlags
                )
                
                views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)
                Log.d(TAG, "Widget click handler set with explicit flags")
            } catch (e: Exception) {
                Log.e(TAG, "Error setting click handler: ${e.message}", e)
            }
            
            // Add click handler for refresh button
            try {
                // Create an intent for widget refresh
                val refreshIntent = Intent(context, HacwiddWidgetProvider::class.java).apply {
                    action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, intArrayOf(appWidgetId))
                    data = Uri.parse("hacwidd://refresh")
                }
                
                // Get pending intent with proper flags for Android 12+
                val pendingIntentFlags = android.app.PendingIntent.FLAG_UPDATE_CURRENT or 
                                         android.app.PendingIntent.FLAG_IMMUTABLE
                                         
                val refreshPendingIntent = android.app.PendingIntent.getBroadcast(
                    context,
                    appWidgetId,
                    refreshIntent,
                    pendingIntentFlags
                )
                
                views.setOnClickPendingIntent(R.id.refresh_button, refreshPendingIntent)
                Log.d(TAG, "Refresh button handler set with explicit flags")
            } catch (e: Exception) {
                Log.e(TAG, "Error setting refresh handler: ${e.message}", e)
            }
            
            // Get cell data from shared preferences
            try {
                // Set colors for each cell based on heat level
                for (i in 1..28) {
                    val cellKey = "cell_$i"
                    val heatLevel = widgetData.getString(cellKey, (i % 5).toString())?.toIntOrNull() ?: (i % 5)
                    
                    val cellColor = when (heatLevel) {
                        0 -> 0xFF263238.toInt() // Dark Gray (no activity)
                        1 -> 0xFF81C784.toInt() // Light Green (low activity)
                        2 -> 0xFF4CAF50.toInt() // Green (medium activity)
                        3 -> 0xFFFF9800.toInt() // Orange (high activity)
                        4 -> 0xFFE53935.toInt() // Red (very high activity)
                        else -> 0xFF263238.toInt() // Default dark gray
                    }
                    
                    val cellId = context.resources.getIdentifier("cell_$i", "id", context.packageName)
                    if (cellId != 0) {
                        views.setInt(cellId, "setBackgroundColor", cellColor)
                        // Add fixed size to make cells visible and consistent
                        views.setInt(cellId, "setMinimumWidth", 10)
                        views.setInt(cellId, "setMinimumHeight", 10)
                    } else {
                        Log.e(TAG, "Could not find cell_$i in layout")
                    }
                }
                Log.d(TAG, "Cell colors set successfully")
            } catch (e: Exception) {
                Log.e(TAG, "Error setting cell colors: ${e.message}", e)
            }
            
            // Make everything visible
            views.setViewVisibility(R.id.widget_content, View.VISIBLE)
            views.setViewVisibility(R.id.error_text, View.GONE)
            views.setViewVisibility(R.id.loading_indicator, View.GONE)
            
            // Update the widget
            appWidgetManager.updateAppWidget(appWidgetId, views)
            Log.d(TAG, "Widget updated successfully")
            
        } catch (e: Exception) {
            Log.e(TAG, "Error updating widget: ${e.message}", e)
        }
    }
}
