import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  String? storedApiKey;
  bool isLoading = true;
  bool isFetchingData = false;
  Map<String, dynamic>? statsData;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  // Load API key from local storage
  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      storedApiKey = prefs.getString('hackatime_api_key');
      isLoading = false;
    });
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
        title: const Text("Hackatime Stats"),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // API Key Status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: storedApiKey != null 
                  ? Colors.green.withValues(alpha: 0.2) 
                  : Colors.red.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "🔑 Hackatime API Key:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    storedApiKey != null 
                      ? "✓ Connected: ${storedApiKey!.substring(0, 8)}..." 
                      : "✗ Not connected to Hackatime",
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // API Key Management
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showApiKeyDialog(),
                    icon: const Icon(Icons.key),
                    label: Text(storedApiKey != null ? "Update API Key" : "Connect Hackatime"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                  ),
                ),
                const SizedBox(width: 10),
                if (storedApiKey != null)
                  ElevatedButton.icon(
                    onPressed: () => _clearApiKey(),
                    icon: const Icon(Icons.delete),
                    label: const Text("Clear"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Get API Key Instructions
            if (storedApiKey == null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "📋 How to get your API Key:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text("1. Visit https://hackatime.hackclub.com/"),
                    const Text("2. Sign up or log in with your GitHub"),
                    const Text("3. Look for the API key in your config"),
                    const Text("4. Copy the api_key value"),
                    const Text("5. Paste it here (format: 2b0037df-1311-4050...)"),
                  ],
                ),
              ),
            
            const SizedBox(height: 30),
            
            // Data Fetching Section
            Container(
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
                    "📊 Fetch Your Coding Stats:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: storedApiKey != null && !isFetchingData
                          ? _fetchHackatimeStats
                          : null,
                      icon: isFetchingData 
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.bar_chart),
                      label: Text(isFetchingData ? "Fetching..." : "Get My Stats"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  
                  if (storedApiKey == null)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        "⚠️ Please connect your Hackatime API key first",
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Display Error
            if (errorMessage != null)
              Container(
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
                  ],
                ),
              ),
            
            // Display Stats Data
            if (statsData != null) _buildStatsDisplay(),
          ],
        ),
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
            "📊 Your Hackatime Stats:",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          _buildStatsContent(),
        ],
      ),
    );
  }

  // Build stats content
  Widget _buildStatsContent() {
    if (statsData == null) return const Text("No data available");

    // Handle different possible response formats
    if (statsData!.containsKey('data')) {
      final data = statsData!['data'];
      return _buildDataSection(data);
    } else if (statsData!.containsKey('languages')) {
      return _buildDataSection(statsData!);
    } else {
      // Display raw data if structure is unknown
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: statsData!.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${entry.key}:",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  "${entry.value}",
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        }).toList(),
      );
    }
  }

  // Build data section
  Widget _buildDataSection(dynamic data) {
    List<Widget> widgets = [];
    
    if (data is Map<String, dynamic>) {
      // Handle total time
      if (data.containsKey('total_seconds')) {
        widgets.add(_buildDataRow("Total Time", _formatDuration(data['total_seconds'])));
      }
      
      if (data.containsKey('text')) {
        widgets.add(_buildDataRow("Human Readable", data['text']));
      }
      
      // Handle languages
      if (data.containsKey('languages') && data['languages'] is List) {
        widgets.add(const SizedBox(height: 8));
        widgets.add(const Text("🔤 Languages:", style: TextStyle(fontWeight: FontWeight.bold)));
        final languages = data['languages'] as List;
        for (var lang in languages.take(5)) {
          widgets.add(Padding(
            padding: const EdgeInsets.only(left: 16, top: 4),
            child: Text("${lang['name'] ?? lang}: ${lang['text'] ?? lang['percent'] ?? ''}"),
          ));
        }
      }
      
      // Handle editors
      if (data.containsKey('editors') && data['editors'] is List) {
        widgets.add(const SizedBox(height: 8));
        widgets.add(const Text("💻 Editors:", style: TextStyle(fontWeight: FontWeight.bold)));
        final editors = data['editors'] as List;
        for (var editor in editors.take(3)) {
          widgets.add(Padding(
            padding: const EdgeInsets.only(left: 16, top: 4),
            child: Text("${editor['name'] ?? editor}: ${editor['text'] ?? editor['percent'] ?? ''}"),
          ));
        }
      }
      
      // Handle projects
      if (data.containsKey('projects') && data['projects'] is List) {
        widgets.add(const SizedBox(height: 8));
        widgets.add(const Text("📁 Projects:", style: TextStyle(fontWeight: FontWeight.bold)));
        final projects = data['projects'] as List;
        for (var project in projects.take(3)) {
          widgets.add(Padding(
            padding: const EdgeInsets.only(left: 16, top: 4),
            child: Text("${project['name'] ?? project}: ${project['text'] ?? project['percent'] ?? ''}"),
          ));
        }
      }
    }
    
    if (widgets.isEmpty) {
      widgets.add(Text("Raw data: ${data.toString()}"));
    }
    
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
  }

  // Build data row
  Widget _buildDataRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              "$label:",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text("$value", style: const TextStyle(fontSize: 14)),
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
    final secs = totalSeconds % 60;
    
    if (hours > 0) {
      return "${hours}h ${minutes}m ${secs}s";
    } else if (minutes > 0) {
      return "${minutes}m ${secs}s";
    } else {
      return "${secs}s";
    }
  }

  // Fetch stats from Hackatime API
  Future<void> _fetchHackatimeStats() async {
    if (storedApiKey == null) {
      _showSnackBar('Please set your Hackatime API key first');
      return;
    }

    setState(() {
      isFetchingData = true;
      errorMessage = null;
      statsData = null;
    });

    try {
      // Try multiple endpoints to find the working one
      final endpoints = [
        'https://hackatime.hackclub.com/api/hackatime/v1/users/current/stats/last_7_days',
        'https://hackatime.hackclub.com/api/hackatime/v1/users/current/summaries?start=today&end=today',
        'https://hackatime.hackclub.com/api/hackatime/v1/users/current/stats',
        'https://hackatime.hackclub.com/api/hackatime/v1/stats',
      ];

      for (String endpoint in endpoints) {
        try {
          final response = await http.get(
            Uri.parse(endpoint),
            headers: {
              'Authorization': 'Bearer $storedApiKey',
              'Content-Type': 'application/json',
            },
          );

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            setState(() {
              statsData = data;
              errorMessage = null;
            });
            _showSnackBar('Stats fetched successfully! 🎉');
            return;
          } else if (response.statusCode == 401) {
            setState(() {
              errorMessage = 'Invalid API key. Please check your API key and try again.';
            });
            return;
          }
        } catch (e) {
          // Try next endpoint
          continue;
        }
      }

      // If all endpoints fail
      setState(() {
        errorMessage = 'Could not fetch data from Hackatime. Please check:\n1. Your API key is correct\n2. You have some coding activity logged\n3. Your internet connection';
      });

    } catch (e) {
      setState(() {
        errorMessage = 'Network error: ${e.toString()}';
      });
    } finally {
      setState(() {
        isFetchingData = false;
      });
    }
  }

  // Show API key input dialog
  void _showApiKeyDialog() {
    final TextEditingController controller = TextEditingController();
    if (storedApiKey != null) {
      controller.text = storedApiKey!;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('🔑 Hackatime API Key'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter your Hackatime API key:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: '2b0037df-1311-4050-820d-2518f2ecb72e',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.vpn_key),
                ),
                obscureText: false,
              ),
              const SizedBox(height: 8),
              const Text(
                '💡 Format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
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

  // Save API key
  Future<void> _saveApiKey(String apiKey) async {
    if (apiKey.trim().isEmpty) {
      _showSnackBar('API Key cannot be empty');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('hackatime_api_key', apiKey.trim());
    
    setState(() {
      storedApiKey = apiKey.trim();
      statsData = null;
      errorMessage = null;
    });
    
    _showSnackBar('Hackatime API Key saved! 🎉');
  }

  // Clear API key
  Future<void> _clearApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('hackatime_api_key');
    
    setState(() {
      storedApiKey = null;
      statsData = null;
      errorMessage = null;
    });
    
    _showSnackBar('API Key cleared');
  }

  // Show snack bar
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
