import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class ConnectionHelper {
  // Try to find a working server URL
  static Future<String?> findWorkingServer(List<String> urls) async {
    for (String url in urls) {
      try {
        log('Testing connection to: $url');
        final response = await http
            .get(
              Uri.parse('$url/health'),
              headers: {'Connection': 'keep-alive'},
            )
            .timeout(const Duration(seconds: 3));

        if (response.statusCode == 200) {
          log('Found working server: $url');
          return url;
        }
      } catch (e) {
        log('Failed to connect to $url: $e');
      }
    }
    return null;
  }

  // Display connection error dialog
  static Future<void> showConnectionErrorDialog(
    BuildContext context,
    String errorMessage,
    VoidCallback retryAction,
  ) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        bool isTesting = false;
        String? testResult;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Connection Error'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    Text(errorMessage),
                    const SizedBox(height: 16),
                    if (isTesting)
                      const CircularProgressIndicator()
                    else if (testResult != null)
                      Text(testResult!)
                    else
                      const Text(
                        'The app may be unable to connect to the delivery server. '
                        'Please check your internet connection and server status.',
                      ),
                  ],
                ),
              ),
              actions: <Widget>[
                if (!isTesting && testResult == null)
                  TextButton(
                    child: const Text('Test Connection'),
                    onPressed: () async {
                      setState(() {
                        isTesting = true;
                      });
                      final workingUrl = await findWorkingServer([
                        'http://192.168.100.41:5000/api',
                        'http://10.0.2.2:5000/api',
                        'http://127.0.0.1:5000/api',
                      ]);
                      setState(() {
                        isTesting = false;
                        if (workingUrl != null) {
                          testResult = 'Found working server at $workingUrl';
                        } else {
                          testResult = 'Could not find any working server';
                        }
                      });
                    },
                  ),
                TextButton(
                  child: const Text('Retry'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    retryAction();
                  },
                ),
                if (testResult != null)
                  TextButton(
                    child: const Text('Close'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
