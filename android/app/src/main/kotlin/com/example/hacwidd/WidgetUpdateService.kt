package com.example.hacwidd

import android.app.AlarmManager
import android.app.PendingIntent
import android.app.Service
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.IBinder
import android.os.SystemClock
import android.util.Log

/**
 * Background service to force widget updates at regular intervals
 */
class WidgetUpdateService : Service() {
    private val TAG = "WidgetUpdateService"
    
    override fun onBind(intent: Intent?): IBinder? {
        return null
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "WidgetUpdateService started")
        
        // Force update all widgets
        updateAllWidgets()
        
        // Schedule next update in 5 minutes
        scheduleNextUpdate()
        
        return START_STICKY
    }
    
    private fun updateAllWidgets() {
        try {
            val appWidgetManager = AppWidgetManager.getInstance(this)
            
            // Update SimpleWidgetProvider widgets
            val simpleIds = appWidgetManager.getAppWidgetIds(
                ComponentName(this, SimpleWidgetProvider::class.java)
            )
            
            if (simpleIds.isNotEmpty()) {
                val updateIntent = Intent(this, SimpleWidgetProvider::class.java)
                updateIntent.action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                updateIntent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, simpleIds)
                sendBroadcast(updateIntent)
                Log.d(TAG, "Update broadcast sent to SimpleWidgetProvider for ${simpleIds.size} widgets")
            }
            
            // Update HacwiddWidgetProvider widgets
            val hacwiddIds = appWidgetManager.getAppWidgetIds(
                ComponentName(this, HacwiddWidgetProvider::class.java)
            )
            
            if (hacwiddIds.isNotEmpty()) {
                val updateIntent = Intent(this, HacwiddWidgetProvider::class.java)
                updateIntent.action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                updateIntent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, hacwiddIds)
                sendBroadcast(updateIntent)
                Log.d(TAG, "Update broadcast sent to HacwiddWidgetProvider for ${hacwiddIds.size} widgets")
            }
            
            // Update AppWidgetProvider widgets
            val appIds = appWidgetManager.getAppWidgetIds(
                ComponentName(this, AppWidgetProvider::class.java)
            )
            
            if (appIds.isNotEmpty()) {
                val updateIntent = Intent(this, AppWidgetProvider::class.java)
                updateIntent.action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                updateIntent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, appIds)
                sendBroadcast(updateIntent)
                Log.d(TAG, "Update broadcast sent to AppWidgetProvider for ${appIds.size} widgets")
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "Error updating widgets: ${e.message}", e)
        }
    }
    
    private fun scheduleNextUpdate() {
        try {
            val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
            
            val intent = Intent(this, WidgetUpdateService::class.java)
            val pendingIntent = PendingIntent.getService(
                this,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            
            // Schedule next update in 5 minutes
            alarmManager.set(
                AlarmManager.ELAPSED_REALTIME,
                SystemClock.elapsedRealtime() + (5 * 60 * 1000), // 5 minutes
                pendingIntent
            )
            
            Log.d(TAG, "Next widget update scheduled in 5 minutes")
        } catch (e: Exception) {
            Log.e(TAG, "Error scheduling next update: ${e.message}", e)
        }
    }
}