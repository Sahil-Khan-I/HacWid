package com.example.hacwidd

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant
import es.antonborri.home_widget.HomeWidgetPlugin
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import android.os.Bundle
import android.util.Log

class MainActivity : FlutterActivity() {
    private val TAG = "MainActivity"
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Add method channel for direct widget updates
        val channel = io.flutter.plugin.common.MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger, 
            "com.example.hacwidd/widget_update"
        )
        
        channel.setMethodCallHandler { call, result ->
            if (call.method == "updateWidget") {
                val success = forceWidgetUpdate()
                result.success(success)
            } else {
                result.notImplemented()
            }
        }
        
        Log.d(TAG, "HomeWidgetPlugin and MethodChannel registered successfully")
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Force widget update when app starts
        forceWidgetUpdate()
        
        // Start the widget auto-update service
        try {
            val serviceIntent = Intent(this, WidgetUpdateService::class.java)
            startService(serviceIntent)
            Log.d(TAG, "Widget auto-update service started")
        } catch (e: Exception) {
            Log.e(TAG, "Error starting widget service: ${e.message}", e)
        }
    }
    
    /**
     * Force an update of all app widgets
     */
    private fun forceWidgetUpdate(): Boolean {
        try {
            Log.d(TAG, "Forcing widget update from MainActivity")
            
            // Update HacwiddWidgetProvider widgets
            val appWidgetManager = AppWidgetManager.getInstance(this)
            
            // Try to update the main widget provider
            val hacwiddComponent = ComponentName(this, HacwiddWidgetProvider::class.java)
            val hacwiddIds = appWidgetManager.getAppWidgetIds(hacwiddComponent)
            
            if (hacwiddIds.isNotEmpty()) {
                val updateIntent = Intent(this, HacwiddWidgetProvider::class.java)
                updateIntent.action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                updateIntent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, hacwiddIds)
                sendBroadcast(updateIntent)
                Log.d(TAG, "HacwiddWidgetProvider update broadcast sent for ${hacwiddIds.size} widgets")
            } else {
                Log.w(TAG, "No HacwiddWidgetProvider widgets found")
            }
            
            // Also try updating AppWidgetProvider
            val appComponent = ComponentName(this, AppWidgetProvider::class.java)
            val appIds = appWidgetManager.getAppWidgetIds(appComponent)
            
            if (appIds.isNotEmpty()) {
                val updateIntent = Intent(this, AppWidgetProvider::class.java)
                updateIntent.action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                updateIntent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, appIds)
                sendBroadcast(updateIntent)
                Log.d(TAG, "AppWidgetProvider update broadcast sent for ${appIds.size} widgets")
                return true
            }
            
            // Also try direct update with WidgetDataDebugReceiver
            val debugIntent = Intent(this, WidgetDataDebugReceiver::class.java)
            debugIntent.action = "com.example.hacwidd.DEBUG_WIDGET_UPDATE"
            sendBroadcast(debugIntent)
            Log.d(TAG, "Debug update broadcast sent")
            
            return hacwiddIds.isNotEmpty() || appIds.isNotEmpty()
        } catch (e: Exception) {
            Log.e(TAG, "Error updating widgets: ${e.message}", e)
            return false
        }
    }
}
