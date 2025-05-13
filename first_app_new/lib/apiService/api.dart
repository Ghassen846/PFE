// filepath: c:\Users\PC\developement\flutter-apps\first_app_new\lib\apiService\api.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http_parser/http_parser.dart';

class ApiClient {
  // Base URL - change this to your server address
  static const String baseUrl = 'http://192.168.100.245:5000/api';
  // Alternative URLs for different environments
  static const String emulatorUrl = 'http://10.0.2.2:5000/api';
  static const String localUrl = 'http://localhost:5000/api';

  static String getBaseUrl() {
    // You can extend this to use a value from SharedPreferences for dynamic configuration
    return baseUrl;
  }

  static const secureStorage = FlutterSecureStorage();

  // Get the authorization token
  static Future<String?> getToken() async {
    try {
      // First try secure storage
      String? token = await secureStorage.read(key: 'token');
      debugPrint(
        'Token from secure storage: ${token != null ? "Found" : "Not found"}',
      );

      if (token != null) return token;

      // Fall back to shared preferences if needed
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString('token');
      debugPrint(
        'Token from SharedPreferences: ${token != null ? "Found" : "Not found"}',
      );

      return token;
    } catch (e) {
      debugPrint('Error getting token: $e');
      return null;
    }
  }

  // Generic GET request
  static Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    try {
      final token = await getToken();
      final url = '${getBaseUrl()}/$endpoint';
      debugPrint('GET request to: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          ...?headers,
        },
      );

      return _processResponse(response);
    } catch (e) {
      debugPrint('GET request error: $e');
      return {'error': e.toString()};
    }
  }

  // Generic POST request
  static Future<Map<String, dynamic>> post(
    String endpoint,
    dynamic data, {
    Map<String, String>? headers,
  }) async {
    try {
      final token = await getToken();
      final url = '${getBaseUrl()}/$endpoint';
      debugPrint('POST request to: $url');
      debugPrint('POST data: ${jsonEncode(data)}');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          ...?headers,
        },
        body: jsonEncode(data),
      );

      return _processResponse(response);
    } catch (e) {
      debugPrint('POST request error: $e');
      return {'error': e.toString()};
    }
  }

  // Generic PUT request
  static Future<Map<String, dynamic>> put(
    String endpoint,
    dynamic data, {
    Map<String, String>? headers,
  }) async {
    try {
      final token = await getToken();
      final response = await http.put(
        Uri.parse('$baseUrl/$endpoint'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          ...?headers,
        },
        body: jsonEncode(data),
      );

      return _processResponse(response);
    } catch (e) {
      debugPrint('PUT request error: $e');
      return {'error': e.toString()};
    }
  }

  // Generic DELETE request
  static Future<Map<String, dynamic>> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    try {
      final token = await getToken();
      final response = await http.delete(
        Uri.parse('$baseUrl/$endpoint'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          ...?headers,
        },
      );

      return _processResponse(response);
    } catch (e) {
      debugPrint('DELETE request error: $e');
      return {'error': e.toString()};
    }
  }

  // Multipart file upload
  static Future<Map<String, dynamic>> uploadFile(
    String endpoint,
    File file,
    String fieldName, {
    Map<String, String>? fields,
    Map<String, String>? headers,
  }) async {
    try {
      final token = await getToken();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/$endpoint'),
      );

      // Add authorization header
      request.headers.addAll({'Authorization': 'Bearer $token', ...?headers});

      // Add file
      var fileExtension = file.path.split('.').last.toLowerCase();
      var contentType = fileExtension == 'jpg' ? 'jpeg' : fileExtension;

      request.files.add(
        await http.MultipartFile.fromPath(
          fieldName,
          file.path,
          contentType: MediaType('image', contentType),
        ),
      );

      // Add additional fields if provided
      if (fields != null) {
        request.fields.addAll(fields);
      }

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _processResponse(response);
    } catch (e) {
      debugPrint('File upload error: $e');
      return {'error': e.toString()};
    }
  }

  // Process API response
  static Map<String, dynamic> _processResponse(http.Response response) {
    try {
      debugPrint('API Response Status: ${response.statusCode}');
      debugPrint('API Response Body: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Success case
        debugPrint('API Request Successful');
        if (data is Map<String, dynamic> && data.containsKey('token')) {
          debugPrint('Token received in response');
        }
        return data;
      } else {
        // Error case
        final errorMsg = data['message'] ?? 'Error ${response.statusCode}';
        debugPrint('API Error: $errorMsg');
        return {
          'error': errorMsg,
          'statusCode': response.statusCode,
          'rawResponse': response.body,
        };
      }
    } catch (e) {
      debugPrint('Failed to process response: $e');
      debugPrint('Raw response body: ${response.body}');
      return {
        'error': 'Failed to process response: $e',
        'statusCode': response.statusCode,
        'rawResponse': response.body,
      };
    }
  }
}
