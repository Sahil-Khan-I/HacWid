import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'widget/widget_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize widget functionality
  await WidgetUtils.initializeWidget();
  
  // Register for widget updates
  await WidgetUtils.registerForUpdates();
  
  // Debug log for widget initialization
  debugLog("Widget initialized and registered for updates");
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hackatime Stats',
      theme: ThemeData.dark(),
      home: const HomeScreen(),
    );
  }
}

/// Improved function to update the widget - call this from anywhere to force an update
Future<bool> testUpdateWidget() async {
  debugLog("🔄 FORCING widget update at ${DateTime.now()}");
  
  try {
    // Generate random cell heat levels to make changes more visible
    final rng = Random();
    
    // Try to clear any existing data first - use a timestamp to make it different each time
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    await HomeWidget.saveWidgetData('timestamp', timestamp);
    
    // Set the active flag first with timestamps to ensure change is detected
    await HomeWidget.saveWidgetData('active', 'true');
    await HomeWidget.saveWidgetData('last_update', timestamp);
    
    // Add random streak and today values (varying each time to force update)
    final streak = rng.nextInt(10) + 1;
    final hours = rng.nextInt(8);
    final minutes = rng.nextInt(60);
    await HomeWidget.saveWidgetData('streak', streak.toString());
    await HomeWidget.saveWidgetData('today', '${hours}h ${minutes}m');
    
    // Set cell data with random values (very different values to make changes obvious)
    for (int i = 1; i <= 28; i++) {
      final heatLevel = rng.nextInt(5); // 0-4 random heat levels
      await HomeWidget.saveWidgetData('cell_$i', heatLevel.toString());
    }
    
    debugLog("Widget data saved with timestamp: $timestamp");
    
    // Try updating all possible widget providers
    bool anySuccess = false;
    
    // Method 1: SimpleWidgetProvider (our guaranteed update provider)
    try {
      final result1 = await HomeWidget.updateWidget(
        androidName: 'com.example.hacwidd.SimpleWidgetProvider',
      );
      debugLog("SimpleWidgetProvider update result: $result1");
      if (result1 == true) anySuccess = true;
    } catch (e) {
      debugLog("Error updating SimpleWidgetProvider: $e");
    }
    
    // Method 2: AppWidgetProvider 
    try {
      final result2 = await HomeWidget.updateWidget(
        androidName: 'com.example.hacwidd.AppWidgetProvider',
      );
      debugLog("AppWidgetProvider update result: $result2");
      if (result2 == true) anySuccess = true;
    } catch (e) {
      debugLog("Error updating AppWidgetProvider: $e");
    }
    
    // Method 3: HacwiddWidgetProvider
    try {
      final result3 = await HomeWidget.updateWidget(
        androidName: 'com.example.hacwidd.HacwiddWidgetProvider',
      );
      debugLog("HacwiddWidgetProvider update result: $result3");
      if (result3 == true) anySuccess = true;
    } catch (e) {
      debugLog("Error updating HacwiddWidgetProvider: $e");
    }
    
    // Method 4: Direct method channel to MainActivity
    try {
      final platform = MethodChannel('com.example.hacwidd/widget_update');
      final result4 = await platform.invokeMethod('updateWidget');
      debugLog("Direct update result: $result4");
      if (result4 == true) anySuccess = true;
    } catch (e) {
      debugLog("Error with direct update: $e");
    }
    
    return anySuccess;
  } catch (e) {
    debugLog("❌ Error in widget update: $e");
    return false;
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// Debug log utility - only prints in debug mode and never in production
void debugLog(String message) {
  if (kDebugMode) {
    print(message);
  }
}

class _HomeScreenState extends State<HomeScreen> {
  String storedSlackId = '1'; // Default to '1' as in the reference implementation
  bool isLoading = true;
  bool isFetchingData = false;
  Map<String, dynamic>? statsData;
  Map<String, int> yearlyActivity = {}; // Date -> coding minutes
  Map<int, Map<String, int>> allYearsData = {}; // Year -> (Date -> coding minutes)
  int selectedYear = DateTime.now().year;
  List<int> availableYears = [];
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    // Using '1' as default Slack ID as per the reference implementation
    _loadSlackId();
    // NO sample data initialization - grid will be empty until API data arrives
    availableYears = [selectedYear]; // Start with current year
    // Immediately try to fetch data
    _fetchHackatimeStats();
    
    // Initialize widget functionality - called once on app startup
    HomeWidget.widgetClicked.listen(_handleWidgetClick);
  }
  
  // Handle widget click from home screen
  void _handleWidgetClick(Uri? uri) {
    debugLog("Widget clicked: ${uri.toString()}");
    _fetchHackatimeStats();
  }







  // Format date as YYYY-MM-DD
  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  // Build year selector
  Widget _buildYearSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: availableYears.map((year) {
          final isSelected = year == selectedYear;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _switchYear(year),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected 
                    ? Colors.blue.withValues(alpha: 0.3) 
                    : Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected 
                      ? Colors.blue.withValues(alpha: 0.7) 
                      : Colors.grey.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  year.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.blue : Colors.grey,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Switch to a different year
  void _switchYear(int year) {
    setState(() {
      selectedYear = year;
      
      // Load data for the selected year - ONLY real API data
      if (allYearsData.containsKey(year)) {
        yearlyActivity = Map.from(allYearsData[year]!);
      } else {
        // No real data available - keep grid empty
        yearlyActivity.clear();
      }
    });
  }

  // Load Slack ID from local storage
  Future<void> _loadSlackId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      storedSlackId = prefs.getString('hackatime_slack_id') ?? '1';
      isLoading = false;
    });
    
    // Always fetch data since we have a default Slack ID
    _fetchHackatimeStats();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Hackatime Activity"),
        backgroundColor: Colors.deepPurple,
        actions: [
          // Widget test button with standard method
          IconButton(
            icon: const Icon(Icons.widgets),
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Updating widget (standard method)...')),
              );
              final result = await testUpdateWidget();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Widget update: ${result ? 'Success' : 'Failed'}')),
              );
            },
            tooltip: 'Test Widget Update',
          ),
          // EMERGENCY debug update button (uses custom channel)
          IconButton(
            icon: const Icon(Icons.bug_report, color: Colors.red),
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('EMERGENCY widget update - direct method...')),
              );
              
              try {
                // Try using a direct method channel to MainActivity
                final platform = MethodChannel('com.example.hacwidd/widget_update');
                final result = await platform.invokeMethod('updateWidget');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Direct update: ${result ? 'Success' : 'Failed'}')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            tooltip: 'Emergency Widget Update',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _fetchHackatimeStats(),
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Slack ID Status
            _buildApiKeyStatus(),
            const SizedBox(height: 20),
            
            // Slack ID Management
            _buildSlackIdManagement(),
            const SizedBox(height: 20),
            
            // Instructions
            _buildInstructions(),
            const SizedBox(height: 20),
            
            // Activity Grid
            _buildActivityGrid(),
            const SizedBox(height: 30),
            
            // Data Fetching Section
            _buildDataFetchingSection(),
            const SizedBox(height: 20),
            
            // Display Error
            if (errorMessage != null) _buildErrorDisplay(),
            if (errorMessage != null) const SizedBox(height: 20),
            
            // Display Stats Data
            if (statsData != null) _buildStatsDisplay(),
            
            const SizedBox(height: 20),
            
            // Android Widget Section
            _buildAndroidWidgetSection(),
          ],
        ),
      ),
    );
  }
  
  // Build Android Widget Section
  Widget _buildAndroidWidgetSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "📱 Android Home Screen Widget",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            "Add the Hacwidd activity grid to your home screen to keep track of your coding streaks.",
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _enableAndroidWidget,
              icon: const Icon(Icons.add_to_home_screen),
              label: const Text("Enable Home Screen Widget"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            ),
          ),
        ],
      ),
    );
  }

  // Build Slack ID status
  Widget _buildApiKeyStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "🔑 Hack Club Slack ID:",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            "✓ Connected: $storedSlackId",
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  // Build Slack ID management buttons
  Widget _buildSlackIdManagement() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showSlackIdDialog(),
            icon: const Icon(Icons.badge),
            label: const Text("Update Slack ID"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          onPressed: () => _clearSlackId(),
          icon: const Icon(Icons.delete),
          label: const Text("Reset"),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
        ),
      ],
    );
  }

  // Build instructions
  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "📋 How to get your Slack ID:",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 8),
          Text("1. Open Slack and go to your Hack Club workspace"),
          Text("2. Click on your profile picture"),
          Text("3. Click on 'View profile'"),
          Text("4. Click the three dots (...) and select 'Copy member ID'"),
          Text("5. Paste your Slack ID here"),
        ],
      ),
    );
  }

  // Build activity grid (main feature)
  Widget _buildActivityGrid() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "📊 $selectedYear Coding Activity",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${yearlyActivity.values.where((v) => v > 0).length} active days",
                  style: const TextStyle(fontSize: 11, color: Colors.blue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Year selector
          if (availableYears.length > 1) _buildYearSelector(),
          if (availableYears.length > 1) const SizedBox(height: 16),
          
          // Activity grid
          _buildYearlyActivityGrid(),
          
          const SizedBox(height: 16),
          
          // Legend
          _buildActivityLegend(),
          
          const SizedBox(height: 8),
          
          // Stats summary
          _buildActivityStats(),
        ],
      ),
    );
  }

  // Build yearly activity grid - FIXED VERSION
  Widget _buildYearlyActivityGrid() {
    final startOfYear = DateTime(selectedYear, 1, 1);
    final endOfYear = DateTime(selectedYear, 12, 31);
    final now = DateTime.now();
    
    // For current year, only show up to today. For past years, show full year
    final lastDayToShow = selectedYear == now.year ? now : endOfYear;
    final daysFromStart = lastDayToShow.difference(startOfYear).inDays + 1;
    
    // Calculate weeks needed
    final weeksNeeded = ((daysFromStart + startOfYear.weekday - 1) / 7).ceil();
    
    // Debug: Count active days

    
    return SizedBox(
      height: 130, // 7 days * 17px + spacing
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(weeksNeeded, (weekIndex) {
            return Padding(
              padding: const EdgeInsets.only(right: 2),
              child: Column(
                children: List.generate(7, (dayIndex) {
                  final dayOffset = weekIndex * 7 + dayIndex - (startOfYear.weekday - 1);
                  
                  // FIXED: Use SizedBox instead of empty Container
                  if (dayOffset < 0 || dayOffset >= daysFromStart) {
                    return const SizedBox(
                      width: 14,
                      height: 14,
                    );
                  }
                  
                  final date = startOfYear.add(Duration(days: dayOffset));
                  final dateString = _formatDate(date);
                  // ONLY show activity if it exists in our real data
                  final activity = yearlyActivity.containsKey(dateString) ? yearlyActivity[dateString]! : 0;
                  final color = _getActivityColor(activity);
                  

                  
                  // Debug code removed
                  
                  return GestureDetector(
                    onTap: () => _showDayDetails(date, activity),
                    child: Container(
                      width: 14,
                      height: 14,
                      margin: const EdgeInsets.only(bottom: 3),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.3),
                          width: 0.5,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        ),
      ),
    );
  }

  // Get activity color using Hackatime's exact color scheme
  Color _getActivityColor(int minutes) {

    
    if (minutes <= 0) {
      return const Color(0xFF151b23); // Hackatime's dark background for no activity
    }
    
    // ANY activity > 0 should show some color!
    // Convert minutes to ratio like Hackatime does (8 hours = full day)
    final ratio = minutes / (8 * 60); // 8 hours = 480 minutes
    
    if (ratio >= 0.8) {
      return const Color(0xFF56d364); // Brightest green (8+ hours)
    } else if (ratio >= 0.5) {
      return const Color(0xFF2ea043); // Bright green (4+ hours)
    } else if (ratio >= 0.2) {
      return const Color(0xFF196c2e); // Medium green (1.6+ hours)
    } else if (minutes > 0) {
      return const Color(0xFF033a16); // Dark green (ANY activity > 0)
    } else {
      return const Color(0xFF151b23); // No activity
    }
  }

  // Build activity legend matching Hackatime's design
  Widget _buildActivityLegend() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Less",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(width: 8),
          _buildLegendSquare(const Color(0xFF151b23)), // No activity
          const SizedBox(width: 3),
          _buildLegendSquare(const Color(0xFF033a16)), // Some activity
          const SizedBox(width: 3),
          _buildLegendSquare(const Color(0xFF196c2e)), // Medium activity
          const SizedBox(width: 3),
          _buildLegendSquare(const Color(0xFF2ea043)), // High activity
          const SizedBox(width: 3),
          _buildLegendSquare(const Color(0xFF56d364)), // Max activity
          const SizedBox(width: 8),
          const Text(
            "More",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // Build legend square
  Widget _buildLegendSquare(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(1),
        border: Border.all(
          color: const Color(0xFF2d333b),
          width: 0.5,
        ),
      ),
    );
  }

  // Build activity stats with improved streak calculations
  Widget _buildActivityStats() {
    final activeDays = yearlyActivity.values.where((minutes) => minutes > 0).length;
    final totalHours = yearlyActivity.values.fold(0, (sum, minutes) => sum + minutes) / 60;
    final longestStreak = _calculateLongestStreak();
    final currentStreak = _calculateCurrentStreak();
    
    // Add streak emoji indicators based on streak length
    String currentStreakEmoji = currentStreak >= 7 ? "🔥" : 
                               currentStreak >= 3 ? "✨" : "";
    String longestStreakEmoji = longestStreak >= 14 ? "🏆" : 
                               longestStreak >= 7 ? "🔥" : 
                               longestStreak >= 3 ? "✨" : "";
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem("Active Days", "$activeDays"),
            _buildStatItem("Hours Coded", "${totalHours.toStringAsFixed(1)}h"),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              "Current Streak", 
              "$currentStreak days$currentStreakEmoji"
            ),
            _buildStatItem(
              "Longest Streak", 
              "$longestStreak days$longestStreakEmoji"
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildWeeklyBreakdown(),
      ],
    );
  }
  
  // Build weekly breakdown of coding activity
  Widget _buildWeeklyBreakdown() {
    // Calculate average minutes per day of the week
    final dayTotals = List<int>.filled(7, 0); // Minutes per day [Mon, Tue, Wed, Thu, Fri, Sat, Sun]
    final dayCounts = List<int>.filled(7, 0); // Number of each day in data
    
    yearlyActivity.forEach((dateStr, minutes) {
      if (minutes > 0) {
        final date = _parseDate(dateStr);
        final dayOfWeek = date.weekday - 1; // 0-based [Mon=0, Sun=6]
        dayTotals[dayOfWeek] += minutes;
        dayCounts[dayOfWeek]++;
      }
    });
    
    // Calculate averages
    final dayAverages = List<double>.filled(7, 0);
    for (int i = 0; i < 7; i++) {
      dayAverages[i] = dayCounts[i] > 0 ? dayTotals[i] / dayCounts[i] : 0;
    }
    
    // Find the max average for scaling
    final maxAverage = dayAverages.reduce((a, b) => a > b ? a : b);
    
    // Day names
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "📊 Weekly Pattern:",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(7, (index) {
            final barHeight = maxAverage > 0 
                ? (dayAverages[index] / maxAverage) * 100 
                : 0.0;
            
            return Column(
              children: [
                Container(
                  width: 24,
                  height: 100,
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: 20,
                    height: barHeight.clamp(0, 100),
                    decoration: BoxDecoration(
                      color: _getBarColor(barHeight),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dayNames[index],
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
  
  // Get color for activity bar based on height
  Color _getBarColor(double value) {
    if (value < 10) return Colors.grey.shade800;
    if (value < 30) return Colors.green.shade900;
    if (value < 60) return Colors.green.shade700;
    if (value < 80) return Colors.green;
    return Colors.greenAccent;
  }

  // Build stat item with improved styling
  Widget _buildStatItem(String label, String value) {
    // Use different colors for different stat types to enhance visual appeal
    Color valueColor = Colors.green;
    
    // Use special styling for streak-related items
    if (label.contains("Streak")) {
      valueColor = label.contains("Current") ? Colors.orange : Colors.deepPurple;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // Calculate longest streak with improved algorithm
  int _calculateLongestStreak() {
    // Extract active dates
    final activeEntries = yearlyActivity.entries
        .where((entry) => entry.value > 0)
        .toList();
    
    if (activeEntries.isEmpty) return 0;
    
    // Convert all active dates to DateTime objects and sort chronologically
    final activeDates = activeEntries
        .map((entry) => _parseDate(entry.key))
        .toList()
        ..sort((a, b) => a.compareTo(b));
    
    int longestStreak = 1; // Minimum streak is 1 if we have activity
    int currentStreak = 1;
    
    // For each date, check if the next date is consecutive
    for (int i = 0; i < activeDates.length - 1; i++) {
      final currentDate = activeDates[i];
      final nextDate = activeDates[i + 1];
      
      // Check if dates are consecutive (exactly 1 day apart)
      if (nextDate.difference(currentDate).inDays == 1) {
        currentStreak++;
        longestStreak = max(longestStreak, currentStreak);
      } 
      // If not consecutive, reset streak
      else if (nextDate.difference(currentDate).inDays > 1) {
        currentStreak = 1;
      }
    }
    
    return longestStreak;
  }
  
  // Calculate current streak - how many consecutive days of activity until today
  int _calculateCurrentStreak() {
    // Get today and convert to string format used in our data
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Extract active dates
    final activeEntries = yearlyActivity.entries
        .where((entry) => entry.value > 0)
        .toList();
    
    if (activeEntries.isEmpty) return 0;
    
    // Create a set of active date strings for faster lookup
    final activeDateSet = Set<String>.from(
      activeEntries.map((e) => e.key)
    );
    
    // Find the most recent date with activity
    DateTime? mostRecentDate;
    DateTime? dateToCheck;
    
    for (final entry in activeEntries) {
      final date = _parseDate(entry.key);
      if (mostRecentDate == null || date.isAfter(mostRecentDate)) {
        mostRecentDate = date;
      }
    }
    
    if (mostRecentDate == null) return 0;
    
    // If the most recent activity is more than 1 day ago, current streak is 0
    final daysSinceLastActivity = today.difference(mostRecentDate).inDays;
    if (daysSinceLastActivity > 1) {
      return 0;
    }
    
    // Count consecutive days backwards from the most recent activity
    int streak = 1; // Start with 1 for the most recent day
    dateToCheck = mostRecentDate.subtract(const Duration(days: 1));
    
    // Keep going back one day at a time until we find a gap
    while (true) {
      final dateString = _formatDate(dateToCheck!);
      
      if (activeDateSet.contains(dateString)) {
        streak++;
        dateToCheck = dateToCheck.subtract(const Duration(days: 1));
      } else {
        break; // Streak is broken
      }
    }
    
    return streak;
  }
  
  // We're using the existing _formatDate method defined at the top
  
  // Enable Android home screen widget
  Future<void> _enableAndroidWidget() async {
    // Store the context before async operations
    final currentContext = context;
    
    try {
      // Register for periodic updates
      await WidgetUtils.registerForUpdates();
      // Legacy code commented out:
      // await legacy.HacwidWidget.registerForUpdates();
      
      // Check if the context is still valid after the async operation
      if (!currentContext.mounted) return;
      
      // Show instructions for adding widget
      showDialog(
        context: currentContext,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Add Home Screen Widget"),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Widget enabled successfully! To add it to your home screen:"),
                SizedBox(height: 16),
                Text("1. Long press on your home screen"),
                Text("2. Select 'Widgets'"),
                Text("3. Find 'Hacwidd'"),
                Text("4. Drag and drop it to your home screen"),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
    } catch (e) {
      _showSnackBar("Error enabling widget: $e");
    }
  }
  
  // Helper method to parse date string into DateTime
  DateTime _parseDate(String dateString) {
    // Format: YYYY-MM-DD
    final parts = dateString.split('-');
    return DateTime(
      int.parse(parts[0]), 
      int.parse(parts[1]), 
      int.parse(parts[2])
    );
  }

  // Show day details
  void _showDayDetails(DateTime date, int minutes) {
    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    final dayOfWeek = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][(date.weekday - 1) % 7];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Text("📅 "),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_formatDateReadable(date)),
                  Text(
                    isToday ? "$dayOfWeek (Today)" : dayOfWeek,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: _getActivityColor(minutes),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                ),
                Text(
                  minutes > 0 
                    ? "🕐 ${_formatDuration(minutes * 60)}" 
                    : "No coding activity",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _getActivityDescription(minutes),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  // Format date as readable string
  String _formatDateReadable(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return "${months[date.month - 1]} ${date.day}, ${date.year}";
  }

  // Get activity description - simplified
  String _getActivityDescription(int minutes) {
    if (minutes == 0) {
      return "No coding activity recorded";
    } else {
      final hours = minutes / 60;
      if (hours >= 1) {
        return "Coded for ${hours.toStringAsFixed(1)} hours";
      } else {
        return "Coded for $minutes minutes";
      }
    }
  }



  // Build data fetching section
  Widget _buildDataFetchingSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "🔄 Sync with Hackatime:",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          const Text(
            "Data syncs automatically when Slack ID is updated, but you can manually refresh anytime.",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: !isFetchingData ? _fetchHackatimeStats : null,
              icon: isFetchingData 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.sync),
              label: Text(isFetchingData ? "Syncing..." : "Sync Data"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              "🔄 Tap 'Sync Data' to update the activity grid",
              style: TextStyle(color: Colors.blue, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }



  // Build error display
  Widget _buildErrorDisplay() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "❌ Error:",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(errorMessage!, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 12),
          const Text(
            "Troubleshooting tips:",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          const Text("• Verify your Slack ID is correct", style: TextStyle(fontSize: 12)),
          const Text("• Ensure you have coding activity in your Hackatime account", style: TextStyle(fontSize: 12)),
          const Text("• Check your internet connection", style: TextStyle(fontSize: 12)),
          const Text("• Try syncing again in a few moments", style: TextStyle(fontSize: 12)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _fetchHackatimeStats,
              icon: const Icon(Icons.refresh),
              label: const Text("Try Again"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build stats display
  Widget _buildStatsDisplay() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "📊 API Response:",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            statsData?.toString() ?? "No data available",
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  // Format duration from seconds
  String _formatDuration(dynamic seconds) {
    if (seconds == null) return "0 seconds";
    final int totalSeconds = seconds is int ? seconds : int.tryParse(seconds.toString()) ?? 0;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    
    if (hours > 0) {
      return "${hours}h ${minutes}m";
    } else if (minutes > 0) {
      return "${minutes}m";
    } else {
      return "${totalSeconds}s";
    }
  }


  

  
  // Normalize date to YYYY-MM-DD format


  // Parse Hackatime API data like the real Hackatime does
  void _parseHackatimeData(Map<String, dynamic> apiData, Map<String, int> parsedActivity, int year) {
    // Parse EXACTLY like the working Rust implementation
    
    // The API returns a "spans" array directly
    if (!apiData.containsKey('spans') || apiData['spans'] is! List) {
      debugLog('❌ No spans array found in API response');
      return;
    }
    
    final spans = apiData['spans'] as List;
    debugLog('🔍 Found ${spans.length} spans in API response');
    
    // Calculate date range: one year ago to today (matching Rust implementation)
    final now = DateTime.now();
    final oneYearAgo = now.subtract(Duration(days: 365));
    final oneYearAgoTimestamp = oneYearAgo.millisecondsSinceEpoch / 1000.0;
    final todayEndTimestamp = DateTime(now.year, now.month, now.day, 23, 59, 59).millisecondsSinceEpoch / 1000.0;
    
    // Process each span - same approach as Rust implementation
    Map<String, int> dayBuckets = {};
    int totalSpansProcessed = 0;
    
    for (var spanData in spans) {
      if (spanData is! Map<String, dynamic>) continue;
      
      final startTime = (spanData['start_time'] ?? 0).toDouble();
      final endTime = (spanData['end_time'] ?? 0).toDouble();
      final duration = (spanData['duration'] ?? 0).toDouble();
      
      // Filter spans within our date range (exact match with Rust code)
      if (endTime < oneYearAgoTimestamp || startTime > todayEndTimestamp) {
        continue;
      }
      
      totalSpansProcessed++;
      
      // Convert timestamps to dates
      final startDate = DateTime.fromMillisecondsSinceEpoch((startTime * 1000).round());
      final endDate = DateTime.fromMillisecondsSinceEpoch((endTime * 1000).round());
      
      final startDateKey = _formatDate(startDate);
      final endDateKey = _formatDate(endDate);
      
      if (startDateKey == endDateKey) {
        // Span within single day - add full duration (matching Rust implementation)
        dayBuckets[startDateKey] = ((dayBuckets[startDateKey] ?? 0) + duration.round()).toInt();
      } else {
        // Handle spans that cross midnight - distribute across days (matching Rust logic)
        final daysDiff = endDate.difference(startDate).inDays + 1;
        
        // This part exactly matches Rust implementation's proportional allocation
        final durationPerDay = duration / daysDiff;
        
        for (int i = 0; i < daysDiff; i++) {
          final currentDate = startDate.add(Duration(days: i));
          final dateKey = _formatDate(currentDate);
          dayBuckets[dateKey] = ((dayBuckets[dateKey] ?? 0) + durationPerDay.round()).toInt();
        }
      }
    }
    
    debugLog('✅ Processed $totalSpansProcessed spans, found ${dayBuckets.length} active days');
    
    // Convert seconds to minutes for display (similar to how Rust generates intensity levels)
    dayBuckets.forEach((dateKey, seconds) {
      if (seconds > 0) {
        final minutes = max(1, (seconds / 60).round()); // At least 1 minute to show color
        parsedActivity[dateKey] = minutes;
      }
    });
  }
  


  // Parse API data and update yearlyActivity map for a specific year
  void _parseAndUpdateActivityData(Map<String, dynamic>? apiData, int year) {
    if (apiData == null) {
      debugLog('❌ API data is null, cannot parse');
      return;
    }
    
    try {
      Map<String, int> parsedActivity = {};
      
      // Parse Hackatime data following the Rust implementation approach
      _parseHackatimeData(apiData, parsedActivity, year);
      
      // If we successfully parsed data
      if (parsedActivity.isNotEmpty) {
        // Store the activity data for this year
        allYearsData[year] = Map.from(parsedActivity);
        
        // Update current display if this is the selected year
        if (year == selectedYear) {
          setState(() {
            yearlyActivity.clear();
            yearlyActivity.addAll(allYearsData[year]!);
          });
        }
        
        // Add year to available years if not already present
        if (!availableYears.contains(year)) {
          availableYears.add(year);
          availableYears.sort((a, b) => b.compareTo(a)); // Sort descending
        }
        
        debugLog('✓ Successfully parsed and stored data for $year');
      } else {
        debugLog('⚠️ No activity data found in API response for $year');
      }
      
    } catch (e) {
      debugLog('❌ Error parsing API data for $year: $e');
    }
  }



  // Prepare widget data from activity data
  Map<String, dynamic> _prepareWidgetData() {
    // Calculate streak
    int currentStreak = 0;
    final now = DateTime.now();
    DateTime checkDate = DateTime(now.year, now.month, now.day);
    
    for (int i = 0; i < 365; i++) {
      final dateStr = "${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}";
      final minutes = yearlyActivity[dateStr] ?? 0;
      
      if (minutes > 0) {
        currentStreak++;
      } else if (i > 0) {
        // Stop counting if we hit a day with no activity (but skip today if it's early)
        break;
      }
      
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    
    // Get today's time
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final todayMinutes = yearlyActivity[todayStr] ?? 0;
    final todayHours = todayMinutes ~/ 60;
    final todayMins = todayMinutes % 60;
    final todayTime = todayHours > 0 ? '${todayHours}h ${todayMins}m' : '${todayMins}m';
    
    // Get last 28 days for the heatmap (4 weeks)
    Map<String, int> cells = {};
    for (int i = 27; i >= 0; i--) {
      final cellDate = now.subtract(Duration(days: i));
      final dateStr = "${cellDate.year}-${cellDate.month.toString().padLeft(2, '0')}-${cellDate.day.toString().padLeft(2, '0')}";
      final minutes = yearlyActivity[dateStr] ?? 0;
      
      // Convert minutes to heat level (0-4)
      int heatLevel = 0;
      if (minutes > 0) {
        if (minutes < 30) heatLevel = 1;
        else if (minutes < 60) heatLevel = 2;
        else if (minutes < 120) heatLevel = 3;
        else heatLevel = 4;
      }
      
      cells['cell_${28 - i}'] = heatLevel;
    }
    
    return {
      'streak': currentStreak,
      'today': todayTime,
      'cells': cells,
    };
  }

  // Fetch comprehensive stats from Hackatime API for all available years
  Future<void> _fetchHackatimeStats() async {
    // Avoid multiple simultaneous fetches
    if (isFetchingData) {
      debugLog('Already fetching data, ignoring request');
      return;
    }
    
    setState(() {
      isFetchingData = true;
      errorMessage = null;
      // Clear ALL existing data - we want ONLY real API data
      allYearsData.clear(); 
      yearlyActivity.clear();
      // Do NOT initialize empty data - grid should be completely empty until we get real data
    });

    try {
      // Get current year
      final currentYear = DateTime.now().year;
      
      // Use the exact same API endpoint as the Rust implementation
      final endpoint = 'https://hackatime.hackclub.com/api/v1/users/$storedSlackId/heartbeats/spans';
      
      // Check if we have a valid Slack ID before making the request
      if (storedSlackId.trim().isEmpty) {
        setState(() {
          errorMessage = 'Please set a valid Slack ID';
        });
        return;
      }

      debugLog('Fetching data for Slack ID: $storedSlackId');
      
      try {
        // Add a timeout to the HTTP request
        final response = await http.get(
          Uri.parse(endpoint),
          headers: {'Content-Type': 'application/json'},
        ).timeout(
          const Duration(seconds: 15),
        );

        final statusCode = response.statusCode;
        debugLog('API response status code: $statusCode');
        
        if (statusCode == 200) {
          // Parse response
          final apiResponse = json.decode(response.body);
          
          // Parse and store data for this year
          _parseAndUpdateActivityData(apiResponse, currentYear);
          
          // Create a simplified data object for the widget
          debugLog("Preparing simplified data for widget");
          
          // Prepare widget data using the helper function
          final widgetData = _prepareWidgetData();
          
          // Log the widget data
          debugLog("Widget data: streak=${widgetData['streak']}, today=${widgetData['today']}, cells=${(widgetData['cells'] as Map).length}");
          
          // Update the widget with simplified data
          debugLog("Updating widget with simplified data");
          bool success = await WidgetUtils.updateWidgetData(widgetData);
          
          if (success) {
            debugLog("Widget data updated successfully");
          } else {
            debugLog("Failed to update widget data");
          }
          
          // Store the complete response for stats display
          setState(() {
            statsData = apiResponse;
            errorMessage = null;
          });
          
          // Calculate stats
          final totalActiveDays = allYearsData.values
              .expand((yearData) => yearData.values)
              .where((minutes) => minutes > 0)
              .length;
          
          if (totalActiveDays > 0) {
            _showSnackBar('🎉 Data synced successfully!');
          } else {
            _showSnackBar('⚠️ No activity found. Try a different Slack ID.');
          }
        } else {
          String message;
          switch (statusCode) {
            case 401:
              message = 'Invalid Slack ID. Please check your Hack Club Slack ID.';
              break;
            case 403:
              message = 'Access denied. Please verify your Slack ID permissions.';
              break;
            case 404:
              message = 'Resource not found. This Slack ID may not exist.';
              break;
            default:
              message = 'API error: $statusCode';
          }
          
          setState(() {
            errorMessage = message;
          });
        }
      } catch (e) {
        String errorMsg = 'Network error: ${e.toString()}';
        if (e.toString().contains('timeout')) {
          errorMsg = 'Request timed out. Check your internet connection.';
        }
        
        setState(() {
          errorMessage = errorMsg;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        isFetchingData = false;
      });
    }
  }

  // Show Slack ID dialog
  void _showSlackIdDialog() {
    final TextEditingController controller = TextEditingController();
    controller.text = storedSlackId;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('🔑 Hack Club Slack ID'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Enter your Hack Club Slack ID:'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'U012ABC3DEF',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '💡 Slack member ID starts with U followed by alphanumeric characters',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _saveSlackId(controller.text);
                Navigator.of(context).pop();
              },
              child: const Text('Save & Connect'),
            ),
          ],
        );
      },
    );
  }

  // Save Slack ID
  Future<void> _saveSlackId(String slackId) async {
    if (slackId.trim().isEmpty) {
      _showSnackBar('Slack ID cannot be empty');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('hackatime_slack_id', slackId.trim());
    
    setState(() {
      storedSlackId = slackId.trim();
      statsData = null;
      errorMessage = null;
    });
    
    _showSnackBar('Slack ID updated, syncing...');
    
    // Automatically sync data after updating the Slack ID
    _fetchHackatimeStats();
    
    // Update the Android widget with test data (real data will be updated after fetch completes)
    WidgetUtils.updateWidgetWithTestData();
  }

  // Clear API key
  Future<void> _clearSlackId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('hackatime_slack_id');
    
    setState(() {
      storedSlackId = '1'; // Reset to default ID
      statsData = null;
      errorMessage = null;
      allYearsData.clear();
      yearlyActivity.clear(); // Clear all data - no sample data
      availableYears = [selectedYear];
    });
    
    _showSnackBar('Reset to default ID, syncing...');
    _fetchHackatimeStats(); // Fetch data with default ID
  }
   
  // Show snack bar
  void _showSnackBar(String message) {   
    // Keep messages brief and clean for better UI
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ), 
    );
  }
}
