import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Learning Flutter',
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

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  // Load API key from local storage
  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      storedApiKey = prefs.getString('api_key');
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
      appBar: AppBar(title: const Text("Learning Step 1")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("This is Text Widget"),
            const Icon(Icons.star, size: 40, color: Colors.yellow),
            const SizedBox(height: 20),
            
            // Display API key status - FIXED LINE
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: storedApiKey != null 
                  ? Colors.green.withValues(alpha: 0.2) 
                  : Colors.red.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                storedApiKey != null 
                  ? "API Key: ${storedApiKey!.substring(0, 10)}..." 
                  : "No API Key stored",
                style: const TextStyle(fontSize: 16),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Buttons
            ElevatedButton(
              onPressed: () => _showApiKeyDialog(),
              child: Text(storedApiKey != null ? "Update API Key" : "Set API Key"),
            ),
            
            const SizedBox(height: 10),
            
            if (storedApiKey != null)
              ElevatedButton(
                onPressed: () => _clearApiKey(),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text("Clear API Key"),
              ),
          ],
        ),
      ),
    );
  }

  // Show dialog to input API key
  void _showApiKeyDialog() {
    final TextEditingController controller = TextEditingController();
    if (storedApiKey != null) {
      controller.text = storedApiKey!;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter API Key'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Your API Key',
              border: OutlineInputBorder(),
            ),
            obscureText: true, // Hide the API key input
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
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // Save API key to local storage
  Future<void> _saveApiKey(String apiKey) async {
    if (apiKey.trim().isEmpty) {
      _showSnackBar('API Key cannot be empty');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_key', apiKey.trim());
    
    setState(() {
      storedApiKey = apiKey.trim();
    });
    
    _showSnackBar('API Key saved successfully!');
  }

  // Clear API key from local storage
  Future<void> _clearApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('api_key');
    
    setState(() {
      storedApiKey = null;
    });
    
    _showSnackBar('API Key cleared');
  }

  // Show snack bar message
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
