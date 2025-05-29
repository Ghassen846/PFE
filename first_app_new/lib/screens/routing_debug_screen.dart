import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/api_key_reminder_dialog.dart';

class RoutingDebugScreen extends StatefulWidget {
  const RoutingDebugScreen({super.key});

  @override
  State<RoutingDebugScreen> createState() => _RoutingDebugScreenState();
}

class _RoutingDebugScreenState extends State<RoutingDebugScreen> {
  String _apiKey = 'Loading...';
  String _userLat = 'Loading...';
  String _userLng = 'Loading...';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final apiKey = dotenv.env['GRAPH_HOPPER_API_KEY'] ?? 'Not configured';
      final userLat = prefs.getDouble('latitude')?.toString() ?? 'Not set';
      final userLng = prefs.getDouble('longitude')?.toString() ?? 'Not set';

      setState(() {
        _apiKey = apiKey;
        _userLat = userLat;
        _userLng = userLng;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _apiKey = 'Error: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Routing Debug'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoCard(
                      'GraphHopper API',
                      [
                        'Status: ${_apiKey == 'Not configured' || _apiKey == 'your_graphhopper_api_key_here' ? '❌ Not configured' : '✅ Configured'}',
                        'API Key: ${_apiKey == 'Not configured' || _apiKey == 'your_graphhopper_api_key_here' ? 'Not set' : 'Valid key found'}',
                      ],
                      _apiKey == 'Not configured' ||
                              _apiKey == 'your_graphhopper_api_key_here'
                          ? Colors.red.shade100
                          : Colors.green.shade100,
                      onTap:
                          () => showDialog(
                            context: context,
                            builder: (context) => const ApiKeyReminderDialog(),
                          ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      'User Location',
                      ['Latitude: $_userLat', 'Longitude: $_userLng'],
                      _userLat == 'Not set'
                          ? Colors.amber.shade100
                          : Colors.blue.shade100,
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard('Routing Troubleshooting', [
                      '• Check that GraphHopper API key is valid',
                      '• Ensure user location is available',
                      '• Verify restaurant and customer coordinates',
                      '• Check internet connectivity',
                    ], Colors.grey.shade100),
                    const SizedBox(height: 32),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'The app will now use fallback routing if no API key is provided',
                              ),
                            ),
                          );
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.check_circle),
                        label: const Text('I understand'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildInfoCard(
    String title,
    List<String> items,
    Color color, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: color,
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(item),
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(height: 8),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(Icons.touch_app, size: 16),
                    SizedBox(width: 4),
                    Text('Tap for more info', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
