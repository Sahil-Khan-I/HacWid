package com.example.hacwidd

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Intent
import android.os.Bundle
import android.util.Log
import android.view.View
import android.widget.Button
import android.widget.EditText
import android.widget.TextView
import android.widget.Toast
import es.antonborri.home_widget.HomeWidgetPlugin

/**
 * The configuration activity for the Hacwidd Widget.
 * This allows users to configure the widget settings when it's added to the home screen.
 */
class HacwiddWidgetConfigureActivity : Activity() {
    private val TAG = "WidgetConfigActivity"
    
    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID
    private lateinit var editText: EditText
    private lateinit var saveButton: Button
    private lateinit var cancelButton: Button

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Set the result to CANCELED in case the user backs out
        setResult(RESULT_CANCELED)
        
        // Set content view
        setContentView(R.layout.widget_configure_activity)
        
        // Find views
        editText = findViewById(R.id.slack_id_input)
        saveButton = findViewById(R.id.save_button)
        cancelButton = findViewById(R.id.cancel_button)
        
        // Set up the save button click listener
        saveButton.setOnClickListener {
            saveWidgetConfiguration()
        }
        
        // Set up the cancel button click listener
        cancelButton.setOnClickListener {
            // Just close the activity without saving
            finish()
        }
        
        // Get the widget ID from the intent
        val intent = intent
        val extras = intent.extras
        if (extras != null) {
            appWidgetId = extras.getInt(
                AppWidgetManager.EXTRA_APPWIDGET_ID,
                AppWidgetManager.INVALID_APPWIDGET_ID
            )
        }
        
        // If widget ID is invalid, close the activity
        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            Log.e(TAG, "Invalid widget ID")
            finish()
            return
        }
        
        // Load the existing Slack ID if available
        val widgetData = HomeWidgetPlugin.getData(this)
        val slackId = widgetData.getString("slackId", "")
        editText.setText(slackId)
    }
    
    private fun saveWidgetConfiguration() {
        val slackId = editText.text.toString().trim()
        
        if (slackId.isEmpty()) {
            Toast.makeText(this, "Please enter a valid ID", Toast.LENGTH_SHORT).show()
            return
        }
        
        try {
            // Save the Slack ID
            val widgetData = HomeWidgetPlugin.getData(this)
            widgetData.edit().putString("slackId", slackId).apply()
            
            Log.d(TAG, "Saved Slack ID: $slackId")
            
            // Update the widget
            val appWidgetManager = AppWidgetManager.getInstance(this)
            val widgetProvider = HacwiddWidgetProvider()
            widgetProvider.onUpdate(this, appWidgetManager, intArrayOf(appWidgetId))
            
            // Create the result intent
            val resultValue = Intent()
            resultValue.putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            setResult(RESULT_OK, resultValue)
            
            Toast.makeText(this, "Widget configured successfully", Toast.LENGTH_SHORT).show()
            
            // Close the activity
            finish()
        } catch (e: Exception) {
            Log.e(TAG, "Error saving widget configuration: ${e.message}")
            Toast.makeText(this, "Error saving configuration", Toast.LENGTH_SHORT).show()
        }
    }
}