import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import 'server_config.dart';
import 'image_service.dart';

class ApiService {
  static final FlutterSecureStorage secureStorage = FlutterSecureStorage();
  static Timer? _onlineStatusTimer;
  static bool _isOnline = false;
  // Helper method to properly process image URLs
  static String _processImageUrl(String imageUrl) {
    if (imageUrl.isEmpty) return '';

    // Remove any IP address or domain prefixes for /uploads paths
    if (imageUrl.contains('/uploads/')) {
      final uploadsPart = imageUrl.substring(imageUrl.indexOf('/uploads/'));
      return uploadsPart; // Return just the /uploads/... path
    }

    // For images that are just filenames, add the /uploads/ prefix
    if (!imageUrl.startsWith('/') &&
        !imageUrl.startsWith('http://') &&
        !imageUrl.startsWith('https://') &&
        !imageUrl.startsWith('uploads/')) {
      return '/uploads/$imageUrl';
    }

    // For paths starting with uploads/ without the leading slash
    if (imageUrl.startsWith('uploads/')) {
      return '/$imageUrl';
    }

    // If it's a relative path without /uploads, let the ImageService handle it
    if (!imageUrl.startsWith('/uploads/') &&
        !imageUrl.startsWith('http://') &&
        !imageUrl.startsWith('https://')) {
      return ImageService.getFullImageUrl(imageUrl);
    }

    // Already a clean path or URL
    return imageUrl;
  }

  // Helper method to process all image URLs in a response map
  static void _processImageUrls(Map<String, dynamic> data) {
    // Process user image if present
    if (data.containsKey('user') && data['user'] is Map) {
      final user = data['user'] as Map<String, dynamic>;
      if (user.containsKey('image') && user['image'] is String) {
        user['image'] = _processImageUrl(user['image']);
      }
    }

    // Process direct image URL if present
    if (data.containsKey('image') && data['image'] is String) {
      data['image'] = _processImageUrl(data['image']);
    }

    // Process imageUrl if present
    if (data.containsKey('imageUrl') && data['imageUrl'] is String) {
      data['imageUrl'] = _processImageUrl(data['imageUrl']);
    }

    // Process items array with nested images (for food items, etc.)
    if (data.containsKey('items') && data['items'] is List) {
      final items = data['items'] as List;
      for (var i = 0; i < items.length; i++) {
        if (items[i] is Map) {
          final item = items[i] as Map<String, dynamic>;

          // Process item imageUrl
          if (item.containsKey('imageUrl') && item['imageUrl'] is String) {
            item['imageUrl'] = _processImageUrl(item['imageUrl']);
          }

          // Process nested food object
          if (item.containsKey('food') && item['food'] is Map) {
            final food = item['food'] as Map<String, dynamic>;
            if (food.containsKey('imageUrl') && food['imageUrl'] is String) {
              food['imageUrl'] = _processImageUrl(food['imageUrl']);
            }
          }
        }
      }
    }

    // Process driver image
    if (data.containsKey('driver') && data['driver'] is Map) {
      final driver = data['driver'] as Map<String, dynamic>;
      if (driver.containsKey('image') && driver['image'] is String) {
        driver['image'] = _processImageUrl(driver['image']);
      }
    }

    // Process client image
    if (data.containsKey('client') && data['client'] is Map) {
      final client = data['client'] as Map<String, dynamic>;
      if (client.containsKey('image') && client['image'] is String) {
        client['image'] = _processImageUrl(client['image']);
      }
    }

    // Process order and its nested images
    if (data.containsKey('order') && data['order'] is Map) {
      final order = data['order'] as Map<String, dynamic>;
      _processImageUrls(order); // Recursively process the order object
    }
  }

  // === API Service Methods ===

  // Get the stored auth token
  static Future<String?> getToken() async {
    return await secureStorage.read(key: 'token');
  }

  // GET request with optional query parameters
  static Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    final url = _buildUrl(endpoint).replace(queryParameters: queryParams);
    final headers = await _getHeaders();
    developer.log('GET request to: ${url.toString()}', name: 'ApiService');
    developer.log('Headers: $headers', name: 'ApiService');

    try {
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 10));
      return _processResponse(response);
    } catch (e) {
      developer.log('GET request error: $e', name: 'ApiService');
      return {'error': e.toString(), 'statusCode': 500};
    }
  }

  // POST request with data
  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final url = _buildUrl(endpoint);
    final headers = await _getHeaders();
    developer.log('POST request to: ${url.toString()}', name: 'ApiService');
    developer.log(
      'Base URL: ${ServerConfig.activeServerUrl}',
      name: 'ApiService',
    );
    developer.log('Endpoint: $endpoint', name: 'ApiService');
    developer.log('Headers: $headers', name: 'ApiService');
    developer.log('Data: $data', name: 'ApiService');

    try {
      final response = await http
          .post(url, headers: headers, body: json.encode(data))
          .timeout(const Duration(seconds: 10));
      return _processResponse(response);
    } catch (e) {
      developer.log('POST request error: $e', name: 'ApiService');
      return {'error': e.toString(), 'statusCode': 500};
    }
  }

  // PUT request with data
  static Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final url = _buildUrl(endpoint);
    final headers = await _getHeaders();
    developer.log('PUT request to: ${url.toString()}', name: 'ApiService');
    developer.log('Headers: $headers', name: 'ApiService');
    developer.log('Data: $data', name: 'ApiService');

    try {
      final response = await http
          .put(url, headers: headers, body: json.encode(data))
          .timeout(const Duration(seconds: 10));
      return _processResponse(response);
    } catch (e) {
      developer.log('PUT request error: $e', name: 'ApiService');
      return {'error': e.toString(), 'statusCode': 500};
    }
  }

  // DELETE request
  static Future<Map<String, dynamic>> delete(String endpoint) async {
    final url = _buildUrl(endpoint);
    final headers = await _getHeaders();
    developer.log('DELETE request to: ${url.toString()}', name: 'ApiService');
    developer.log('Headers: $headers', name: 'ApiService');

    try {
      final response = await http
          .delete(url, headers: headers)
          .timeout(const Duration(seconds: 10));
      return _processResponse(response);
    } catch (e) {
      developer.log('DELETE request error: $e', name: 'ApiService');
      return {'error': e.toString(), 'statusCode': 500};
    }
  }

  // PATCH request with data
  static Future<Map<String, dynamic>> patch(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final url = _buildUrl(endpoint);
    final headers = await _getHeaders();
    developer.log('PATCH request to: ${url.toString()}', name: 'ApiService');
    developer.log('Headers: $headers', name: 'ApiService');
    developer.log('Data: $data', name: 'ApiService');

    try {
      final response = await http
          .patch(url, headers: headers, body: json.encode(data))
          .timeout(const Duration(seconds: 10));
      return _processResponse(response);
    } catch (e) {
      developer.log('PATCH request error: $e', name: 'ApiService');
      return {'error': e.toString(), 'statusCode': 500};
    }
  }

  // File upload with multipart request
  static Future<Map<String, dynamic>> uploadFile(
    String endpoint,
    File file,
    String fileField, {
    Map<String, String>? fields,
    Map<String, String>? headers,
  }) async {
    final url = _buildUrl(endpoint);
    final defaultHeaders = await _getHeaders();
    final requestHeaders = {...defaultHeaders, ...?headers};

    developer.log('Upload request to: ${url.toString()}', name: 'ApiService');
    developer.log('Headers: $requestHeaders', name: 'ApiService');
    developer.log('Fields: $fields', name: 'ApiService');
    developer.log('File: ${file.path}', name: 'ApiService');

    final request = http.MultipartRequest('POST', url);
    request.headers.addAll(requestHeaders);

    if (fields != null) {
      request.fields.addAll(fields);
    }

    final fileStream = http.ByteStream(file.openRead());
    final length = await file.length();

    final multipartFile = http.MultipartFile(
      fileField,
      fileStream,
      length,
      filename: file.path.split('/').last,
    );

    request.files.add(multipartFile);

    try {
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 10),
      );
      final response = await http.Response.fromStream(streamedResponse);
      return _processResponse(response);
    } catch (e) {
      developer.log('Upload request error: $e', name: 'ApiService');
      return {'error': e.toString(), 'statusCode': 500};
    }
  }

  // Helper to build URL with proper normalization
  static Uri _buildUrl(String endpoint) {
    String baseUrl = ServerConfig.activeServerUrl;

    // Trim trailing slashes from the base URL
    baseUrl = baseUrl.replaceAll(RegExp(r'/*$'), '');

    // Ensure endpoint doesn't start with a slash
    String cleanEndpoint =
        endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;

    // Handle the case where the baseUrl already includes /api and the endpoint also starts with api/
    if (baseUrl.endsWith('/api') && cleanEndpoint.startsWith('api/')) {
      developer.log(
        'Fixing double API path: Removing api/ prefix from endpoint',
        name: 'ApiService',
      );
      cleanEndpoint = cleanEndpoint.substring(
        4,
      ); // Remove 'api/' prefix from endpoint
    }

    final finalUrl = '$baseUrl/$cleanEndpoint';
    developer.log('Final URL constructed: $finalUrl', name: 'ApiService');
    return Uri.parse(finalUrl);
  }

  // Helper to get standard headers including auth token
  static Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Helper to process HTTP responses
  static Map<String, dynamic> _processResponse(http.Response response) {
    developer.log(
      'Processing response: ${response.statusCode}',
      name: 'ApiService',
    );
    developer.log('Response body: ${response.body}', name: 'ApiService');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {'success': true};
      }

      try {
        final responseData = json.decode(response.body);
        // Handle List responses
        if (responseData is List) {
          final processedList =
              responseData.map((item) {
                if (item is Map) {
                  final mapItem = Map<String, dynamic>.from(item);

                  // Process images in each item of the list
                  _processImageUrls(mapItem);
                  return mapItem;
                }
                return item;
              }).toList();
          return {'data': processedList, 'statusCode': response.statusCode};
        }
        // Process images in the response for Map type
        if (responseData is Map) {
          final result = Map<String, dynamic>.from(responseData);
          // Use our helper method to process all image URLs in the response
          _processImageUrls(result);
          return result;
        }

        return responseData;
      } catch (e) {
        developer.log('Error decoding JSON: $e', name: 'ApiService');
        return {'data': response.body, 'statusCode': response.statusCode};
      }
    } else {
      try {
        final errorData = json.decode(response.body);
        developer.log('Error response: $errorData', name: 'ApiService');
        String errorMessage;

        // Handle different error formats from the server
        if (errorData is Map) {
          // Try to extract error message from common patterns
          if (errorData.containsKey('message')) {
            errorMessage = errorData['message'].toString();
          } else if (errorData.containsKey('error')) {
            errorMessage = errorData['error'].toString();
          } else {
            // Convert the entire error object to string if no standard error field
            errorMessage = errorData.toString();
          }
        } else {
          // If it's not a map (could be a string or list), convert to string
          errorMessage = errorData.toString();
        }

        return {'error': errorMessage, 'statusCode': response.statusCode};
      } catch (e) {
        developer.log('Error decoding error response: $e', name: 'ApiService');
        return {
          'error': response.body.isNotEmpty ? response.body : 'Unknown error',
          'statusCode': response.statusCode,
        };
      }
    }
  }

  // === Authentication Methods ===
  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    // Check for token
    final token = await getToken();
    if (token == null || token.isEmpty) {
      developer.log('Login check failed: No token found', name: 'ApiService');
      return false;
    }

    // Check for userId in SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final prefsUserId = prefs.getString('userId');

    // Check for userId in secure storage
    final userDataStr = await secureStorage.read(key: 'user_data');
    String? secureStorageUserId;

    if (userDataStr != null) {
      try {
        final userData = json.decode(userDataStr);
        secureStorageUserId = userData['_id'] ?? userData['id'];
      } catch (e) {
        developer.log('Error decoding user data: $e', name: 'ApiService');
      }
    }

    final bool hasValidUserId =
        (prefsUserId != null && prefsUserId.isNotEmpty) ||
        (secureStorageUserId != null && secureStorageUserId.isNotEmpty);
    developer.log(
      'Login status: Token exists: true, Valid userId: $hasValidUserId',
      name: 'ApiService',
    );

    return hasValidUserId;
  }

  // Perform logout
  static Future<void> logout() async {
    developer.log('Logging out user', name: 'ApiService');

    // Update online status to server before logging out
    try {
      final userId = await getUserId();
      if (userId != null && userId.isNotEmpty) {
        await updateOnlineStatusToServer(false);
      }
    } catch (e) {
      developer.log(
        'Error updating online status during logout: $e',
        name: 'ApiService',
      );
    }

    // Clear all secure storage
    await secureStorage.deleteAll();

    // Clear SharedPreferences user-related data
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('username');
    await prefs.remove('email');
    await prefs.remove('firstName');
    await prefs.remove('name');
    await prefs.remove('phone');
    await prefs.remove('role');
    await prefs.remove('image');
    await prefs.setBool('isLoggedIn', false);
    await prefs.setBool('isOnline', false);

    // Reset service state
    _isOnline = false;
    stopPeriodicOnlineUpdates();

    developer.log('Logout completed successfully', name: 'ApiService');
  }

  // Save user data locally
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    developer.log('Saving user data: $userData', name: 'ApiService');
    await secureStorage.write(key: 'user_data', value: json.encode(userData));
  }

  // Save user session from login response
  static Future<void> saveUserSession(Map<String, dynamic> response) async {
    developer.log('Saving session data: $response', name: 'ApiService');

    if (response.containsKey('token')) {
      developer.log('Saving token: ${response['token']}', name: 'ApiService');
      await secureStorage.write(
        key: 'token',
        value: response['token'] as String,
      );
    }

    // Get the user data from response
    Map<String, dynamic> userData = {};
    if (response.containsKey('user') && response['user'] is Map) {
      userData = Map<String, dynamic>.from(response['user'] as Map);
    } else {
      // Use the top-level response if no 'user' key
      userData = Map<String, dynamic>.from(response);
      // Remove token from userData to avoid duplication
      userData.remove('token');
    }

    // Make sure we have a userId
    String? userId = userData['_id'] ?? userData['id'];
    if (userId == null) {
      developer.log('No user ID found in response', name: 'ApiService');
      return;
    }

    // Save user data to secure storage
    await saveUserData(userData);

    // Also save essential data to SharedPreferences for faster access
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId);
    await prefs.setBool('isLoggedIn', true);

    // Save other important user details
    if (userData['email'] != null) {
      await prefs.setString('email', userData['email']);
    }
    if (userData['username'] != null) {
      await prefs.setString('username', userData['username']);
    }
    if (userData['firstName'] != null) {
      await prefs.setString('firstName', userData['firstName']);
    }
    if (userData['name'] != null) {
      await prefs.setString('name', userData['name']);
    }
    if (userData['phone'] != null) {
      await prefs.setString('phone', userData['phone']);
    }
    if (userData['role'] != null) {
      await prefs.setString('role', userData['role']);
    }
    if (userData['image'] != null) {
      // Process the image URL before storing it
      final processedImageUrl = _processImageUrl(userData['image'] as String);
      await prefs.setString('image', processedImageUrl);
    }

    developer.log('User session saved successfully', name: 'ApiService');
  }

  // Login user and return response
  static Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    developer.log('Attempting login for email: $email', name: 'ApiService');
    return await post('user/login', {'email': email, 'password': password});
  }

  // Register user with all required fields
  static Future<Map<String, dynamic>> registerUser({
    required String username,
    required String firstName,
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
    double? latitude,
    double? longitude,
    String? vehiculetype,
    File? profileImage,
    List<File>? vehicleDocuments,
  }) async {
    try {
      developer.log(
        'Attempting to register user: $email, role: $role',
        name: 'ApiService',
      );

      final data = {
        'username': username,
        'firstName': firstName,
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'role': role,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (vehiculetype != null) 'vehiculetype': vehiculetype,
      };
      developer.log('Registering user with data: $data', name: 'ApiService');
      // Using the correct endpoint for user registration
      // When combined with the baseUrl http://SERVER_IP:5000/api, this creates:
      // http://SERVER_IP:5000/api/user/register
      final response = await post('user/register', data);
      if (response.containsKey('error')) {
        developer.log(
          'Registration error: ${response['error']}',
          name: 'ApiService',
        );
        throw Exception(response['error']);
      }

      developer.log('Registration response: $response', name: 'ApiService');
      // Extract user ID from the response, handling different possible formats
      String? userId;
      if (response.containsKey('_id')) {
        userId = response['_id'].toString();
      } else if (response.containsKey('user') && response['user'] is Map) {
        final user = response['user'] as Map<String, dynamic>;
        userId = user['_id']?.toString() ?? user['id']?.toString();
      } else if (response.containsKey('id')) {
        userId = response['id'].toString();
      }

      if (userId == null) {
        developer.log(
          'No user ID in registration response: $response',
          name: 'ApiService',
        );
      } // Upload profile image if provided
      String? imageUrl;
      if (profileImage != null && userId != null) {
        developer.log(
          'Uploading profile image: ${profileImage.path}',
          name: 'ApiService',
        );
        try {
          final imageResponse = await uploadFile(
            'user/register/image?userId=$userId',
            profileImage,
            'image',
          );

          if (imageResponse.containsKey('error')) {
            developer.log(
              'Error uploading profile image: ${imageResponse["error"]}',
              name: 'ApiService',
            ); // Don't throw - continue with registration even if image upload fails
          } else if (imageResponse.containsKey('image')) {
            imageUrl = imageResponse['image'] as String;
          } else if (imageResponse.containsKey('imageUrl')) {
            imageUrl = imageResponse['imageUrl'] as String;
          }

          if (imageUrl != null) {
            // Ensure we're not duplicating URL prefixes
            final processedImageUrl = _processImageUrl(imageUrl);
            response['user'] ??= {};
            response['user']['image'] = processedImageUrl;
            developer.log(
              'Profile image uploaded: $processedImageUrl',
              name: 'ApiService',
            );
          } else {
            developer.log(
              'No image URL in response: $imageResponse',
              name: 'ApiService',
            );
          }
        } catch (e) {
          developer.log(
            'Exception during profile image upload: $e',
            name: 'ApiService',
          );
          // Continue with registration even if image upload fails
        }
      }

      // Upload vehicle documents if provided
      List<String> documentUrls = [];
      if (vehicleDocuments != null &&
          vehicleDocuments.isNotEmpty &&
          userId != null) {
        developer.log(
          'Uploading ${vehicleDocuments.length} vehicle documents',
          name: 'ApiService',
        );
        for (var doc in vehicleDocuments) {
          final docResponse = await uploadFile(
            'user/register/documents?userId=$userId',
            doc,
            'document',
          );
          if (docResponse.containsKey('document')) {
            String docUrl = docResponse['document'] as String;
            documentUrls.add(
              _processImageUrl(docUrl),
            ); // Use the same URL processor
          } else if (docResponse.containsKey('documentUrl')) {
            String docUrl = docResponse['documentUrl'] as String;
            documentUrls.add(
              _processImageUrl(docUrl),
            ); // Use the same URL processor
          }
        }
        if (documentUrls.isNotEmpty) {
          response['user'] ??= {};
          response['user']['vehicleDocuments'] = documentUrls;
          developer.log(
            'Vehicle documents uploaded: $documentUrls',
            name: 'ApiService',
          );
        } else {
          developer.log('No document URLs in response', name: 'ApiService');
        }
      }

      // Save user session
      await saveUserSession(response);

      developer.log('Registration successful: $response', name: 'ApiService');
      return response;
    } catch (e) {
      developer.log('Registration exception: $e', name: 'ApiService');
      return {'error': e.toString(), 'statusCode': 500};
    }
  }

  // Track online status locally
  static Future<void> setOnlineStatus(bool isOnline) async {
    _isOnline = isOnline;
    await secureStorage.write(key: 'is_online', value: isOnline.toString());
    developer.log('Set online status to: $isOnline', name: 'ApiService');
  }

  // Update online status to the server
  static Future<Map<String, dynamic>> updateOnlineStatusToServer(
    bool isOnline,
  ) async {
    final userId = await getUserId();
    if (userId == null) {
      developer.log(
        'User not logged in, cannot update online status',
        name: 'ApiService',
      );
      return {'error': 'User not logged in'};
    }

    developer.log(
      'Updating online status for user $userId to $isOnline',
      name: 'ApiService',
    );
    // Use correct endpoint format without 'api/' prefix since it's already in baseUrl
    return await put('user/status', {'userId': userId, 'isOnline': isOnline});
  }

  // Start periodic online status updates
  static void startPeriodicOnlineUpdates() {
    stopPeriodicOnlineUpdates();
    developer.log(
      'Starting periodic online status updates',
      name: 'ApiService',
    );

    _onlineStatusTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
      if (_isOnline) {
        developer.log(
          'Sending periodic online status update',
          name: 'ApiService',
        );
        await updateOnlineStatusToServer(true);
      }
    });
  }

  // Stop periodic online status updates
  static void stopPeriodicOnlineUpdates() {
    _onlineStatusTimer?.cancel();
    _onlineStatusTimer = null;
    developer.log('Stopped periodic online status updates', name: 'ApiService');
  }

  // Get stored user ID
  static Future<String?> getUserId() async {
    // First try to get from SharedPreferences (faster)
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');

    if (userId != null && userId.isNotEmpty) {
      developer.log(
        'Retrieved user ID from SharedPreferences: $userId',
        name: 'ApiService',
      );
      return userId;
    }

    // If not in SharedPreferences, try secure storage
    final userDataStr = await secureStorage.read(key: 'user_data');
    if (userDataStr == null) {
      developer.log('No user data found in secure storage', name: 'ApiService');
      return null;
    }

    try {
      final userData = json.decode(userDataStr);
      userId = userData['_id'] ?? userData['id'];

      if (userId != null) {
        // Save to SharedPreferences for future faster access
        await prefs.setString('userId', userId);
        developer.log(
          'Retrieved user ID from secure storage: $userId',
          name: 'ApiService',
        );
        return userId;
      } else {
        developer.log('User ID not found in user data', name: 'ApiService');
        return null;
      }
    } catch (e) {
      developer.log('Error decoding user data: $e', name: 'ApiService');
      return null;
    }
  }

  // For debugging purposes
  static void logEndpointUrl(String endpoint) {
    final url = _buildUrl(endpoint);
    developer.log(
      'Base URL: ${ServerConfig.activeServerUrl}',
      name: 'ApiService',
    );
    developer.log('Endpoint: $endpoint', name: 'ApiService');
    developer.log('Final URL: $url', name: 'ApiService');
  }

  // Test method to access the private _buildUrl method for debugging
  static Uri testBuildUrl(String endpoint) {
    return _buildUrl(endpoint);
  }
}
