import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

/// Class to manage the Android home screen widget
/// Note: This class is deprecated - use WidgetUtils instead
@Deprecated('Use WidgetUtils class instead')
class HacwidWidget {
  /// Widget key
  static const String widgetKey = "hacwidd_widget_data";
  
  /// Background task name
  static const String backgroundTaskName = "hacwidd.updateWidget";
  
  /// Background task input parameter
  static const String backgroundTaskInputData = "slackId";
  
  /// Initialize widget services - call this in main.dart
  static Future<void> initializeWidget() async {
    debugPrint('HacwidWidget is deprecated. Use WidgetUtils.initializeWidget() instead.');
    try {
      await HomeWidget.setAppGroupId('hacwidd_group');
      debugPrint('Widget initialized successfully');
    } catch (e) {
      debugPrint('Error initializing widget: $e');
    }
  }
  
  /// Register for widget updates
  static Future<void> registerForUpdates() async {
    debugPrint('HacwidWidget is deprecated. Use WidgetUtils.registerForUpdates() instead.');
    try {
      // This is a stub method - functionality moved to WidgetUtils
      debugPrint('Widget updates registered successfully');
    } catch (e) {
      debugPrint('Error registering for widget updates: $e');
    }
  }
  
  /// Update widget with latest data
  static Future<void> updateWidgetData(String slackId) async {
    debugPrint('HacwidWidget is deprecated. Use WidgetUtils.updateWidgetData() instead.');
    try {
      // This is a stub method - functionality moved to WidgetUtils
      await HomeWidget.saveWidgetData('slackId', slackId);
      await HomeWidget.updateWidget(
        androidName: 'com.example.hacwidd.HacwidWidgetProvider',
        iOSName: 'HacwiddWidgetProvider',
      );
      debugPrint('Widget data updated successfully');
    } catch (e) {
      debugPrint('Error updating widget data: $e');
    }
  }
}