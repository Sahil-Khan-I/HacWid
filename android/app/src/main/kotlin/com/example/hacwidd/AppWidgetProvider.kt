package com.example.hacwidd

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.util.Log

/**
 * Simple AppWidgetProvider that redirects to HacwiddWidgetProvider
 * This class name matches what is referenced in widget_utils.dart
 */
class AppWidgetProvider : AppWidgetProvider() {
    private val TAG = "AppWidgetProvider"
    
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        Log.d(TAG, "Redirecting to HacwiddWidgetProvider")
        
        // Redirect to our main widget provider implementation
        val widgetProvider = HacwiddWidgetProvider()
        widgetProvider.onUpdate(context, appWidgetManager, appWidgetIds)
    }
}
