package com.example.hacwidd

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.util.Log
import android.widget.RemoteViews
import java.text.SimpleDateFormat
import java.util.*

/**
 * Ultra-simple widget provider designed to work in all situations
 * Now reads data from SharedPreferences set by home_widget plugin
 */
class SimpleWidgetProvider : AppWidgetProvider() {
    private val TAG = "SimpleWidgetProvider"
    private val PREFS_NAME = "HomeWidgetPreferences"
    
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        Log.d(TAG, "SimpleWidgetProvider.onUpdate() called with ${appWidgetIds.size} widgets")
        
        // Update each widget ID
        for (widgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, widgetId)
        }
    }
    
    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        Log.d(TAG, "SimpleWidgetProvider: Widget enabled")
    }
    
    private fun updateWidget(context: Context, appWidgetManager: AppWidgetManager, widgetId: Int) {
        try {
            Log.d(TAG, "========================================")
            Log.d(TAG, "🔄 Updating widget ID: $widgetId")
            
            // Read data from SharedPreferences (home_widget stores data here)
            val prefs: SharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            
            // Log all stored keys for debugging
            val allKeys = prefs.all.keys
            Log.d(TAG, "📦 Total keys in SharedPreferences: ${allKeys.size}")
            if (allKeys.isEmpty()) {
                Log.w(TAG, "⚠️ WARNING: No data in SharedPreferences! Widget will show defaults.")
            } else {
                Log.d(TAG, "✅ Data found in local storage")
            }
            
            // Create remote views using the simplified layout
            val views = RemoteViews(context.packageName, R.layout.simple_widget_layout)
            
            // Set current time
            val dateFormat = SimpleDateFormat("HH:mm:ss", Locale.getDefault())
            val currentTime = dateFormat.format(Date())
            
            // Read data from SharedPreferences or use defaults
            val streak = prefs.getString("streak", "0") ?: "0"
            val today = prefs.getString("today", "0h 0m") ?: "0h 0m"
            val timestamp = prefs.getString("timestamp", "0") ?: "0"
            val dataReady = prefs.getString("data_ready", "false") ?: "false"
            
            Log.d(TAG, "📊 Widget data from LOCAL STORAGE:")
            Log.d(TAG, "  Streak: $streak")
            Log.d(TAG, "  Today: $today")
            Log.d(TAG, "  Timestamp: $timestamp")
            Log.d(TAG, "  Data Ready: $dataReady")
            
            // Update text fields
            views.setTextViewText(R.id.widget_title, "Hackatime")
            views.setTextViewText(R.id.slack_id_text, "TS: $timestamp")
            views.setTextViewText(R.id.last_updated, "Updated: $currentTime")
            views.setTextViewText(R.id.widget_streak_value, streak)
            views.setTextViewText(R.id.widget_today_value, today)
            
            // Update all cells with colors based on heat level from SharedPreferences
            Log.d(TAG, "🎨 Updating 28 heatmap cells from local storage...")
            var cellsUpdated = 0
            var cellsWithData = 0
            
            for (i in 1..28) {
                val cellId = context.resources.getIdentifier("cell_$i", "id", context.packageName)
                if (cellId != 0) {
                    val heatLevel = prefs.getString("cell_$i", "0")?.toIntOrNull() ?: 0
                    val color = getHeatmapColor(heatLevel)
                    views.setInt(cellId, "setBackgroundColor", color)
                    cellsUpdated++
                    
                    if (heatLevel > 0) {
                        cellsWithData++
                    }
                    
                    // Log only first and last cell to avoid spam
                    if (i == 1 || i == 28) {
                        Log.d(TAG, "  Cell $i: level=$heatLevel, color=#${Integer.toHexString(color)}")
                    }
                }
            }
            
            Log.d(TAG, "✅ Updated $cellsUpdated cells ($cellsWithData have activity)")
            
            // Update the widget
            appWidgetManager.updateAppWidget(widgetId, views)
            Log.d(TAG, "✅ Widget $widgetId updated successfully from LOCAL STORAGE")
            Log.d(TAG, "========================================")
            
        } catch (e: Exception) {
            Log.e(TAG, "Error updating widget: ${e.message}", e)
        }
    }
    
    /**
     * Get color based on heat level (0-4)
     */
    private fun getHeatmapColor(level: Int): Int {
        return when (level) {
            0 -> Color.parseColor("#161B22") // Very dark gray (no activity)
            1 -> Color.parseColor("#0E4429") // Dark green
            2 -> Color.parseColor("#006D32") // Medium green
            3 -> Color.parseColor("#26A641") // Light green
            4 -> Color.parseColor("#39D353") // Bright green
            else -> Color.parseColor("#161B22")
        }
    }
}