import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

void main() {
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
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
    _loadApiKey();
    // NO sample data initialization - grid will be empty until API data arrives
    availableYears = [selectedYear]; // Start with current year
    // Immediately try to fetch data
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
  Future<void> _loadApiKey() async {
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
          ],
        ),
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
            "✓ Connected: ${storedSlackId}",
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
                  

                  
                  // Debug: Show a few activity samples
                  if (activity > 0 && (dayOffset % 50 == 0 || activity > 30)) {
                    
                  }
                  
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

  // Build activity stats - ONLY for real API data
  Widget _buildActivityStats() {
    final activeDays = yearlyActivity.values.where((minutes) => minutes > 0).length;
    final totalHours = yearlyActivity.values.fold(0, (sum, minutes) => sum + minutes) / 60;
    final longestStreak = _calculateLongestStreak();
    final totalDays = activeDays; // Only count days with real activity
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem("Total Days", "$totalDays"),
            _buildStatItem("Active Days", "$activeDays"),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem("Total Hours", "${totalHours.toStringAsFixed(1)}h"),
            _buildStatItem("Longest Streak", "$longestStreak days"),
          ],
        ),
      ],
    );
  }

  // Build stat item
  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.green,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  // Calculate longest streak
  int _calculateLongestStreak() {
    final sortedDates = yearlyActivity.keys.toList()..sort();
    int currentStreak = 0;
    int longestStreak = 0;
    
    for (String dateString in sortedDates) {
      if (yearlyActivity[dateString]! > 0) {
        currentStreak++;
        longestStreak = max(longestStreak, currentStreak);
      } else {
        currentStreak = 0;
      }
    }
    
    return longestStreak;
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
          const SizedBox(height: 16),
          
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
            statsData.toString(),
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
      print('❌ No spans array found in API response');
      return;
    }
    
    final spans = apiData['spans'] as List;
    print('🔍 Found ${spans.length} spans in API response');
    
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
    
    print('✅ Processed $totalSpansProcessed spans, found ${dayBuckets.length} active days');
    
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
      print('❌ API data is null, cannot parse');
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
        
        print('✓ Successfully parsed and stored data for $year');
      } else {
        print('⚠️ No activity data found in API response for $year');
      }
      
    } catch (e) {
      print('❌ Error parsing API data for $year: $e');
    }
  }



  // Fetch comprehensive stats from Hackatime API for all available years
  Future<void> _fetchHackatimeStats() async {
    setState(() {
      isFetchingData = true;
      errorMessage = null;
      // Clear ALL existing data - we want ONLY real API data
      allYearsData.clear(); 
      yearlyActivity.clear();
      // Do NOT initialize empty data - grid should be completely empty until we get real data
    });

    try {
      // Get current year as this is what we need
      final currentYear = DateTime.now().year;
      Map<String, dynamic>? apiResponse;
      
      // Use the exact same API endpoint as the Rust implementation
      final endpoint = 'https://hackatime.hackclub.com/api/v1/users/${storedSlackId}/heartbeats/spans';

      try {
        final response = await http.get(
          Uri.parse(endpoint),
          headers: {
            'Content-Type': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          apiResponse = json.decode(response.body);
          
          // Parse and store data for this year
          _parseAndUpdateActivityData(apiResponse, currentYear);
        } else if (response.statusCode == 401) {
          setState(() {
            errorMessage = 'Invalid Slack ID. Please check your Hack Club Slack ID.';
          });
          return;
        } else if (response.statusCode == 403) {
          setState(() {
            errorMessage = 'Access denied. Please verify your Slack ID permissions.';
          });
          return;
        } else if (response.statusCode == 404) {
          setState(() {
            errorMessage = 'Resource not found. This Slack ID may not exist.';
          });
          return;
        } else {
          setState(() {
            errorMessage = 'API error: ${response.statusCode}';
          });
          return;
        }
      } catch (e) {
        setState(() {
          errorMessage = 'Network error: ${e.toString()}';
        });
        return;
      }

      // If we got here, we have data
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
        _showSnackBar('🎉 Synced Hackatime data! Found $totalActiveDays active days.');
      } else {
        _showSnackBar('⚠️ No activity data found in the response. Try a different Slack ID.');
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
                _saveApiKey(controller.text);
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
  Future<void> _saveApiKey(String slackId) async {
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
    
    _showSnackBar('Hackatime API Key saved! 🎉');
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
    
    _showSnackBar('Reset to default Slack ID - Sync to get new data');
    _fetchHackatimeStats(); // Fetch data with default ID
  }
   
  // Show snack bar
  void _showSnackBar(String message) {   
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)), 
    );
  }
}
