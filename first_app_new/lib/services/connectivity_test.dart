// This file contains utilities for testing backend connectivity
import 'dart:async';
import 'dart:developer';
import 'package:http/http.dart' as http;

class ConnectivityTest {
  // Tests all possible server URLs and returns the first working one
  static Future<String?> findWorkingServer() async {
    log('Testing all possible server URLs');

    final serverUrls = [
      // Primary URL from ApiService
      'http://192.168.100.208:5000/api', // PC's IP address
      'http://10.0.2.2:5000/api', // Android emulator URL
      'http://localhost:5000/api', // Local development
      'http://127.0.0.1:5000/api', // Another localhost option
    ];

    // Add dynamic IP addresses from ipconfig if possible
    // This would need platform channel code to run ipconfig

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

  // Tests a specific URL and returns success/failure
  static Future<bool> testSpecificUrl(String url) async {
    log('Testing specific URL: $url');
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));

      final success = response.statusCode >= 200 && response.statusCode < 300;
      log(
        'URL test ${success ? 'succeeded' : 'failed'}: $url (status: ${response.statusCode})',
      );
      return success;
    } catch (e) {
      log('Error testing URL $url: $e');
      return false;
    }
  }

  // Gets a list of all available server URLs to try
  static List<String> getPossibleServerUrls() {
    return [
      'http://192.168.100.208:5000/api', // PC's IP address
      'http://10.0.2.2:5000/api',
      'http://localhost:5000/api',
      'http://127.0.0.1:5000/api',
    ];
  }

  // A simple test to log any connection issues
  static Future<void> testAndLogConnection() async {
    log('Starting connectivity test');
    final workingUrl = await findWorkingServer();

    if (workingUrl != null) {
      log('✅ Found working connection to: $workingUrl');
    } else {
      log('❌ Failed to connect to any server');
      log('ℹ️ Make sure the server is running and accessible');
      log('ℹ️ For Android emulator, use 10.0.2.2 to access host machine');
      log(
        'ℹ️ For physical device, make sure device and server are on same network',
      );
    }
  }
}
