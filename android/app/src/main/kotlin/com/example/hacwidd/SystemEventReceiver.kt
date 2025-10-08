package com.example.hacwidd

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.util.Log

/**
 * Receives system broadcasts and updates the widget
 */
class SystemEventReceiver : BroadcastReceiver() {
    private val TAG = "SystemEventReceiver"
    
    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "SystemEventReceiver received action: ${intent.action}")
        
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_TIME_TICK,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED -> {
                // Start the auto-update service
                try {
                    val serviceIntent = Intent(context, WidgetUpdateService::class.java)
                    context.startService(serviceIntent)
                    Log.d(TAG, "Started widget service from system event")
                } catch (e: Exception) {
                    Log.e(TAG, "Error starting widget service: ${e.message}", e)
                }
                
                // Force immediate update of all widgets
                forceWidgetUpdate(context)
            }
        }
    }
    
    private fun forceWidgetUpdate(context: Context) {
        try {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            
            // Update SimpleWidgetProvider
            val simpleIds = appWidgetManager.getAppWidgetIds(
                ComponentName(context, SimpleWidgetProvider::class.java)
            )
            
            if (simpleIds.isNotEmpty()) {
                val updateIntent = Intent(context, SimpleWidgetProvider::class.java)
                updateIntent.action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                updateIntent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, simpleIds)
                context.sendBroadcast(updateIntent)
                Log.d(TAG, "Update sent to SimpleWidgetProvider for ${simpleIds.size} widgets")
            }
            
            // Also try updating directly
            val simpleProvider = SimpleWidgetProvider()
            simpleProvider.onUpdate(context, appWidgetManager, simpleIds)
            
        } catch (e: Exception) {
            Log.e(TAG, "Error forcing widget update: ${e.message}", e)
        }
    }
}