// This file contains configuration for server URLs and IP addresses
import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class ServerConfig {
  // Primary server URL to use
  static const String SERVER_IP = '192.168.100.41';
  static const String PRIMARY_SERVER_URL = 'http://$SERVER_IP:5000/api';

  // Backup URLs for different environments
  static const String EMULATOR_URL = 'http://10.0.2.2:5000/api';
  static const String LOCALHOST_URL = 'http://localhost:5000/api';
  static const String LOOPBACK_URL = 'http://127.0.0.1:5000/api';
  // Image server base URL - note: we use the active server URL base without the /api suffix
  static String get IMAGE_SERVER_BASE {
    // Extract the base URL without the /api suffix from the active server URL
    final String url = activeServerUrl;
    return url.endsWith('/api') ? url.substring(0, url.length - 4) : url;
  }

  // Current active URL
  static String _activeServerUrl = PRIMARY_SERVER_URL;

  // Get active server URL
  static String get activeServerUrl => _activeServerUrl;

  // Initialize the server config
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('active_server_url');

    if (savedUrl != null && await _testUrl('$savedUrl/health')) {
      _activeServerUrl = savedUrl;
      log('Using saved server URL: $_activeServerUrl');
      return;
    }

    final urls = [
      PRIMARY_SERVER_URL,
      EMULATOR_URL,
      LOCALHOST_URL,
      LOOPBACK_URL,
    ];

    for (final url in urls) {
      log('Testing server URL: $url');
      if (await _testUrl('$url/health')) {
        _activeServerUrl = url;
        await prefs.setString('active_server_url', url);
        log('Found working server URL: $_activeServerUrl');
        return;
      }
    }

    log('No working server URL found, using default: $_activeServerUrl');
  }

  // Test if a URL is accessible
  static Future<bool> _testUrl(String url) async {
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));
      final isSuccess = response.statusCode >= 200 && response.statusCode < 300;
      log('Test URL $url: ${isSuccess ? 'Success' : 'Failed'}');
      return isSuccess;
    } catch (e) {
      log('Error testing URL $url: $e');
      return false;
    }
  }

  // Fix image URLs to use the correct server
  // This method is now deprecated, use ApiConfig.getFullImageUrl() instead
  static String fixImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return '';
    }

    // We delegate to the new implementation
    return ApiConfig.getFullImageUrl(imageUrl);
  }
}
