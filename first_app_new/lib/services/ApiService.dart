import 'dart:convert';
import 'dart:io';
import 'dart:async'; // For TimeoutException
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http_parser/http_parser.dart';
import 'server_config.dart';

class ApiService {
  // Base URL is now handled by ServerConfig
  static String getBaseUrl() {
    // Return the dynamic server URL from ServerConfig
    return ServerConfig.activeServerUrl;
  }

  static const secureStorage = FlutterSecureStorage();
  // Get the authorization token
  static Future<String?> getToken() async {
    try {
      final token = await secureStorage.read(key: 'token');
      debugPrint(
        "ApiService getToken from secure storage: ${token != null ? 'Token found' : 'No token'}",
      );
      return token;
    } catch (e) {
      debugPrint("Error reading token from secure storage: $e");
      // Fallback to SharedPreferences if secure storage fails
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      debugPrint(
        "ApiService getToken from SharedPreferences: ${token != null ? 'Token found' : 'No token'}",
      );
      return token;
    }
  }

  // Check if the device has internet connectivity
  static Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } catch (e) {
      debugPrint('Error checking internet connection: $e');
      return false;
    }
  }

  // Ping server to check connectivity without authentication
  static Future<bool> pingServer() async {
    try {
      final response = await http
          .get(Uri.parse('${getBaseUrl()}/health'))
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error pinging server: $e');
      return false;
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
      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              ...?headers,
            },
          )
          .timeout(
            const Duration(
              seconds: 20,
            ), // Set a 20 second timeout for better reliability
            onTimeout: () {
              debugPrint('GET request timeout for endpoint: $endpoint');
              throw TimeoutException(
                'Server connection timeout. Please check your internet connection and try again.',
              );
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
      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              ...?headers,
            },
            body: jsonEncode(data),
          )
          .timeout(
            const Duration(
              seconds: 20,
            ), // Set a 20 second timeout for better reliability
            onTimeout: () {
              debugPrint('POST request timeout for endpoint: $endpoint');
              throw TimeoutException(
                'Connection timeout. Please check your internet connection.',
              );
            },
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
      final url = '${getBaseUrl()}/$endpoint';
      debugPrint('PUT request to: $url');
      debugPrint('PUT data: ${jsonEncode(data)}');

      final response = await http.put(
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
      debugPrint('PUT request error: $e');
      return {'error': e.toString()};
    }
  }

  // Generic PATCH request
  static Future<Map<String, dynamic>> patch(
    String endpoint,
    dynamic data, {
    Map<String, String>? headers,
  }) async {
    try {
      final token = await getToken();
      final url = '${getBaseUrl()}/$endpoint';
      debugPrint('PATCH request to: $url');
      debugPrint('PATCH data: ${jsonEncode(data)}');

      final response = await http.patch(
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
      debugPrint('PATCH request error: $e');
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
      final url = '${getBaseUrl()}/$endpoint';
      debugPrint('DELETE request to: $url');

      final response = await http.delete(
        Uri.parse(url),
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
    List<File>? additionalFiles,
  }) async {
    try {
      final token = await getToken();
      final url = '${getBaseUrl()}/$endpoint';
      debugPrint('uploadFile to: $url');

      final request = http.MultipartRequest('POST', Uri.parse(url));

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

      // Add additional files if provided (for vehicle documents)
      if (additionalFiles != null && additionalFiles.isNotEmpty) {
        for (int i = 0; i < additionalFiles.length; i++) {
          File docFile = additionalFiles[i];
          fileExtension = docFile.path.split('.').last.toLowerCase();
          contentType = fileExtension == 'jpg' ? 'jpeg' : fileExtension;

          request.files.add(
            await http.MultipartFile.fromPath(
              'vehiculedocuments',
              docFile.path,
              contentType: MediaType('image', contentType),
            ),
          );
        }
      }

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

  // Upload multiple files with one main image file and additional documents
  static Future<Map<String, dynamic>> uploadMultipleFiles(
    String endpoint,
    File mainFile,
    String mainFieldName,
    List<File>? additionalFiles, {
    Map<String, String>? fields,
    Map<String, String>? headers,
  }) async {
    try {
      final token = await getToken();
      final url = '${getBaseUrl()}/$endpoint';
      debugPrint('uploadMultipleFiles to: $url');

      final request = http.MultipartRequest('POST', Uri.parse(url));

      // Add authorization header
      request.headers.addAll({'Authorization': 'Bearer $token', ...?headers});

      // Add main file
      var fileExtension = mainFile.path.split('.').last.toLowerCase();
      var contentType = fileExtension == 'jpg' ? 'jpeg' : fileExtension;

      request.files.add(
        await http.MultipartFile.fromPath(
          mainFieldName,
          mainFile.path,
          contentType: MediaType('image', contentType),
        ),
      );

      // Add additional files if provided
      if (additionalFiles != null && additionalFiles.isNotEmpty) {
        for (int i = 0; i < additionalFiles.length; i++) {
          File file = additionalFiles[i];
          fileExtension = file.path.split('.').last.toLowerCase();
          contentType = fileExtension == 'jpg' ? 'jpeg' : fileExtension;

          request.files.add(
            await http.MultipartFile.fromPath(
              'vehiculedocuments',
              file.path,
              contentType: MediaType('image', contentType),
            ),
          );
        }
      }

      // Add additional fields if provided
      if (fields != null) {
        request.fields.addAll(fields);
      }

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _processResponse(response);
    } catch (e) {
      debugPrint('Multiple file upload error: $e');
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

// Removed custom MediaType class as it conflicts with http_parser's MediaType.
