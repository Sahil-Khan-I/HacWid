import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:flutter/foundation.dart';

/// Comprehensive helper for widget data operations to ensure type safety and error handling
class WidgetDataFixer {
  /// Android widget provider name
  static const String androidWidgetProvider = 'com.example.hacwidd.AppWidgetProvider';
  
  /// iOS widget provider name
  static const String iOSWidgetProvider = 'HacwiddWidget';
  
  /// Save widget data safely by ensuring all values are properly converted to strings
  static Future<bool?> saveWidgetData(String id, dynamic value) async {
    try {
      // Convert any value to string to ensure widget can handle it
      String? stringValue;
      if (value == null) {
        stringValue = null;
      } else {
        stringValue = value.toString();
      }
      
      debugPrint('Attempting to save widget data for $id. Length: ${stringValue?.length ?? 0}');
      
      // Use the home_widget package with safe string values
      final result = await HomeWidget.saveWidgetData(id, stringValue);
      
      if (result == true) {
        debugPrint('✓ Successfully saved widget data for $id');
      } else {
        debugPrint('⚠ Failed to save widget data for $id');
      }
      
      return result;
    } catch (e) {
      debugPrint('❌ Error saving widget data for $id: $e');
      // Print the full stack trace for debugging
      debugPrint('Stack trace: ${StackTrace.current}');
      return false;
    }
  }
  
  /// Update the widget with the changes
  static Future<void> updateWidget() async {
    try {
      debugPrint('Attempting to update widget with provider: $androidWidgetProvider');
      
      await HomeWidget.updateWidget(
        androidName: androidWidgetProvider,
        iOSName: iOSWidgetProvider,
      );
      
      debugPrint('✓ Widget updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating widget: $e');
      // Print the full stack trace for debugging
      debugPrint('Stack trace: ${StackTrace.current}');
    }
  }
}