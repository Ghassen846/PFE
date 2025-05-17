// Helper extension for DeliveryDetailsScreen

import 'package:flutter/material.dart';
import '../services/connectivity_test.dart';

extension DeliveryScreenExtensions on State {
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
    final workingUrl = await ConnectivityTest.findWorkingServer();

    // Pop the loading dialog
    Navigator.of(context).pop();

    // Show the results
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
                  ...ConnectivityTest.getPossibleServerUrls().map(
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
