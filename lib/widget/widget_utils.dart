import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'dart:io' show Platform;

/// Utility class to safely handle widget data operations
class WidgetUtils {
  /// Initialize widget functionality
  static Future<void> initializeWidget() async {
    // Only run on mobile platforms
    if (!_isMobilePlatform()) {
      debugPrint('Skipping widget initialization - not on mobile platform');
      return;
    }
    
    try {
      await HomeWidget.setAppGroupId('group.com.example.hacwidd');
      
      HomeWidget.widgetClicked.listen((uri) {
        debugPrint('Widget clicked: $uri');
      });
    } catch (e) {
      debugPrint('Error initializing widget: $e');
    }
  }
  
  /// Register for widget updates
  static Future<void> registerForUpdates() async {
    // Only run on mobile platforms
    if (!_isMobilePlatform()) {
      debugPrint('Skipping widget update registration - not on mobile platform');
      return;
    }
    
    try {
      // Use the recommended method instead of the deprecated one
      await HomeWidget.registerInteractivityCallback(backgroundCallback);
    } catch (e) {
      debugPrint('Error registering for widget updates: $e');
    }
  }
  
  /// Check if running on a mobile platform
  static bool _isMobilePlatform() {
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (e) {
      // If we can't access Platform, we're probably on web
      return false;
    }
  }
  
  /// Background callback for widget updates
  @pragma('vm:entry-point')
  static Future<void> backgroundCallback(Uri? uri) async {
    if (uri == null) return;
    
    debugPrint('Background callback received: $uri');
    
    // Handle background updates here
    if (uri.host == 'updatewidget' || uri.host == 'refresh') {
      final result = await HomeWidget.updateWidget(
        androidName: 'com.example.hacwidd.AppWidgetProvider', // Use AppWidgetProvider as registered in AndroidManifest
        iOSName: 'HacwiddWidget',
      );
      debugPrint('Background widget update result: $result');
    }
  }
  
  /// Update widget data safely and trigger widget update
  /// Stores data locally so widget can read it without internet
  static Future<bool> updateWidgetData(Map<String, dynamic> activityData) async {
    // Only run on mobile platforms
    if (!_isMobilePlatform()) {
      debugPrint('Skipping widget update - not on mobile platform');
      return false;
    }
    
    try {
      debugPrint('▶️ Updating widget with activity data (LOCAL STORAGE)');
      
      // Save timestamp to ensure changes are detected
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Extract and save stats from activity data
      final streak = activityData['streak']?.toString() ?? '0';
      final todayTime = activityData['today']?.toString() ?? '0h 0m';
      
      debugPrint('📊 Data to save - Streak: $streak, Today: $todayTime');
      
      // Save ALL data to HomeWidget storage (which uses SharedPreferences)
      // This ensures the widget can read it locally without internet
      await HomeWidget.saveWidgetData('timestamp', timestamp);
      await HomeWidget.saveWidgetData('active', 'true');
      await HomeWidget.saveWidgetData('lastUpdate', DateTime.now().toString());
      await HomeWidget.saveWidgetData('streak', streak);
      await HomeWidget.saveWidgetData('today', todayTime);
      
      debugPrint('✅ Saved basic stats to local storage');
      
      // Process heatmap cell data - save each cell individually
      final cellData = activityData['cells'] as Map<String, int>?;
      if (cellData != null) {
        debugPrint('💾 Saving ${cellData.length} cells to local storage...');
        int savedCount = 0;
        
        for (var entry in cellData.entries) {
          await HomeWidget.saveWidgetData(entry.key, entry.value.toString());
          savedCount++;
          
          // Log every 7th cell (once per week) for verification
          if (savedCount % 7 == 0 || savedCount == cellData.length) {
            debugPrint('  Saved $savedCount/${cellData.length} cells...');
          }
        }
        debugPrint('✅ All ${cellData.length} cells saved to local storage');
      } else {
        // Set default values if no cell data provided
        debugPrint('⚠️ No cell data provided, setting defaults...');
        for (int i = 1; i <= 28; i++) {
          await HomeWidget.saveWidgetData('cell_$i', '0');
        }
        debugPrint('✅ Set 28 default cell values');
      }
      
      // Add a verification flag to confirm data is ready
      await HomeWidget.saveWidgetData('data_ready', 'true');
      await HomeWidget.saveWidgetData('last_save_time', DateTime.now().toIso8601String());
      
      debugPrint('✅ All widget data saved to LOCAL STORAGE');
      debugPrint('📍 Widget can now read data offline from SharedPreferences');
      
      // Force system to update the actual widget UI
      bool success = false;
      int successCount = 0;
      
      // Try all widget providers (including minimal)
      final providers = [
        'MinimalWidgetProvider',  // Simplest - MUST work
        'SimpleWidgetProvider',
        'AppWidgetProvider',
        'HacwiddWidgetProvider',
      ];
      
      debugPrint('🔄 Broadcasting update to ${providers.length} widget providers...');
      
      for (final provider in providers) {
        try {
          final result = await HomeWidget.updateWidget(
            androidName: 'com.example.hacwidd.$provider',
            iOSName: 'HacwiddWidget',
          );
          
          if (result == true) {
            success = true;
            successCount++;
            debugPrint('  ✅ $provider: SUCCESS');
          } else {
            debugPrint('  ❌ $provider: FAILED');
          }
        } catch (e) {
          debugPrint('  ⚠️ $provider: ERROR - $e');
        }
      }
      
      // Final verification
      if (success) {
        debugPrint('✅ Widget update SUCCESSFUL ($successCount/${providers.length} providers responded)');
        debugPrint('📱 Widget should now display updated data from local storage');
      } else {
        debugPrint('❌ Widget update FAILED - no providers responded');
        debugPrint('💡 Widget will still work when added - data is stored locally');
      }
      
      return success;
    } catch (e) {
      debugPrint('❌ Error updating widget data: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      return false;
    }
  }
  
  /// Quick test update with random data
  static Future<bool> updateWidgetWithTestData() async {
    final random = DateTime.now().millisecond % 5;
    final cells = <String, int>{};
    for (int i = 1; i <= 28; i++) {
      cells['cell_$i'] = (i + random) % 5;
    }
    
    return await updateWidgetData({
      'streak': random + 1,
      'today': '${random}h ${random * 10}m',
      'cells': cells,
    });
  }
}