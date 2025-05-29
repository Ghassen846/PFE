// Helper extension for DeliveryDetailsScreen

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:developer';
import 'package:http/http.dart' as http;

extension DeliveryScreenExtensions on State {
  // Tests all possible server URLs and returns the first working one
  static Future<String?> _findWorkingServer() async {
    log('Testing all possible server URLs');
    final serverUrls = [
      // Primary URL from ApiService
      'http://192.168.100.198:3000/api', // PC's IP address
      'http://10.0.2.2:3000/api', // Android emulator URL
      'http://localhost:3000/api', // Local development
      'http://127.0.0.1:3000/api', // Another localhost option
    ];

    // Test each URL
    for (final url in serverUrls) {
      log('Testing server URL: $url');
      try {
        final response = await http
            .get(Uri.parse('$url/health'))
            .timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          log('Found working server URL: $url');
          return url;
        } else {
          log('Server responded with: ${response.statusCode}');
        }
      } catch (e) {
        log('Error connecting to $url: $e');
      }
    }

    log('No working server URL found');
    return null;
  }

  // Returns list of possible server URLs to test
  static List<String> _getPossibleServerUrls() {
    return [
      'http://192.168.100.198:3000/api', // PC's IP address
      'http://10.0.2.2:3000/api',
      'http://localhost:3000/api',
      'http://127.0.0.1:3000/api',
    ];
  }

  // Show a dialog with connectivity test results
  Future<void> showConnectivityTestDialog(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: const [
                Icon(Icons.network_check, color: Colors.blue),
                SizedBox(width: 8),
                Text('Testing Connection...'),
              ],
            ),
            content: SizedBox(
              height: 100,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Checking server connectivity...'),
                  ],
                ),
              ),
            ),
          ),
    );

    // Run the test
    final workingUrl = await _findWorkingServer();

    // Pop the loading dialog
    if (context.mounted) {
      Navigator.of(context).pop();
    }

    // Show the results
    if (context.mounted) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text(
                workingUrl != null
                    ? 'Connection Successful'
                    : 'Connection Failed',
                style: TextStyle(
                  color: workingUrl != null ? Colors.green : Colors.red,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (workingUrl != null) ...[
                    Text('Successfully connected to:'),
                    SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        workingUrl,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                  ] else ...[
                    Text('Could not connect to the server. Please check:'),
                    SizedBox(height: 8),
                    Text('• Is the server running?'),
                    Text('• Is your device on the same network?'),
                    Text('• Is the correct IP address configured?'),
                    SizedBox(height: 16),
                    Text('Tested the following URLs:'),
                    ..._getPossibleServerUrls().map(
                      (url) => Padding(
                        padding: const EdgeInsets.only(left: 8, top: 4),
                        child: Text(
                          '- $url',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    }
  }
}
