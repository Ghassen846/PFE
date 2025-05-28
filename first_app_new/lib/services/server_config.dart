// This file contains configuration for server URLs and IP addresses
import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ServerConfig {
  // Primary server URL to use
  static const String SERVER_IP = '192.168.100.198';
  static const String PRIMARY_SERVER_URL = 'http://$SERVER_IP:3000/api';

  // Backup URLs for different environments
  static const String EMULATOR_URL = 'http://10.0.2.2:3000/api';
  static const String LOCALHOST_URL = 'http://localhost:3000/api';
  static const String LOOPBACK_URL = 'http://127.0.0.1:3000/api';

  // Image server base URL
  static const String IMAGE_SERVER_BASE = 'http://$SERVER_IP:3000';

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
  static String fixImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return '';
    }

    String fixedUrl = imageUrl;

    if (imageUrl.startsWith('undefined/uploads/')) {
      fixedUrl = imageUrl.replaceFirst('undefined', IMAGE_SERVER_BASE);
      log('Fixed malformed image URL: $fixedUrl');
    } else if (imageUrl.contains('localhost')) {
      fixedUrl = imageUrl.replaceAll('localhost', SERVER_IP);
      log('Fixed localhost image URL: $fixedUrl');
    } else if (imageUrl.startsWith('/uploads/')) {
      fixedUrl = '$IMAGE_SERVER_BASE$imageUrl';
      log('Added server to image URL: $fixedUrl');
    }

    return fixedUrl;
  }
}
