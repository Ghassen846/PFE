import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';
import 'dart:developer' as developer;

class AuthServiceImproved {
  static const _storage = FlutterSecureStorage();
  static Timer? _onlineStatusTimer;
  static bool _isOnline = false;

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await ApiService.getToken();
    developer.log(
      'Checking login status: Token exists - ${token != null}',
      name: 'AuthService',
    );
    return token != null && token.isNotEmpty;
  }

  // Perform logout
  static Future<void> logout() async {
    developer.log('Logging out user', name: 'AuthService');
    await ApiService.secureStorage.deleteAll();
    _isOnline = false;
    stopPeriodicOnlineUpdates();
  }

  // Save user data locally
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    developer.log('Saving user data: $userData', name: 'AuthService');
    await _storage.write(key: 'user_data', value: json.encode(userData));
  }

  // Save user session from login response
  static Future<void> saveUserSession(Map<String, dynamic> response) async {
    if (response.containsKey('token')) {
      developer.log('Saving token: ${response['token']}', name: 'AuthService');
      await _storage.write(key: 'token', value: response['token']);
    }

    if (response.containsKey('user')) {
      await saveUserData(response['user']);
    }
  }

  // Login user and return response
  static Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    developer.log('Attempting login for email: $email', name: 'AuthService');
    return await ApiService.post('api/user/login', {
      'email': email,
      'password': password,
    });
  }

  // Register user with all required fields
  static Future<Map<String, dynamic>> registerUser({
    required String username,
    required String firstName,
    required String name,
    required String email,
    required String password,
    required String phone,
    String role = 'livreur',
    File? profileImage,
    double? latitude,
    double? longitude,
    String? vehiculetype,
    List<File>? vehicleDocuments,
  }) async {
    developer.log(
      'Attempting to register user: $email, role: $role',
      name: 'AuthService',
    );
    return await ApiService.registerUser(
      username: username,
      firstName: firstName,
      name: name,
      email: email,
      password: password,
      phone: phone,
      role: role,
      latitude: latitude,
      longitude: longitude,
      vehiculetype: vehiculetype,
      profileImage: profileImage,
      vehicleDocuments: vehicleDocuments,
    );
  }

  // Track online status locally
  static Future<void> setOnlineStatus(bool isOnline) async {
    _isOnline = isOnline;
    await _storage.write(key: 'is_online', value: isOnline.toString());
    developer.log('Set online status to: $isOnline', name: 'AuthService');
  }

  // Update online status to the server
  static Future<Map<String, dynamic>> updateOnlineStatusToServer(
    bool isOnline,
  ) async {
    final userId = await getUserId();
    if (userId == null) {
      developer.log(
        'User not logged in, cannot update online status',
        name: 'AuthService',
      );
      return {'error': 'User not logged in'};
    }

    developer.log(
      'Updating online status for user $userId to $isOnline',
      name: 'AuthService',
    );
    return await ApiService.put('users/$userId/status', {'isOnline': isOnline});
  }

  // Start periodic online status updates
  static void startPeriodicOnlineUpdates() {
    stopPeriodicOnlineUpdates();
    developer.log(
      'Starting periodic online status updates',
      name: 'AuthService',
    );

    _onlineStatusTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
      if (_isOnline) {
        developer.log(
          'Sending periodic online status update',
          name: 'AuthService',
        );
        await updateOnlineStatusToServer(true);
      }
    });
  }

  // Stop periodic online status updates
  static void stopPeriodicOnlineUpdates() {
    _onlineStatusTimer?.cancel();
    _onlineStatusTimer = null;
    developer.log(
      'Stopped periodic online status updates',
      name: 'AuthService',
    );
  }

  // Get stored user ID
  static Future<String?> getUserId() async {
    final userDataStr = await _storage.read(key: 'user_data');
    if (userDataStr == null) {
      developer.log('No user data found', name: 'AuthService');
      return null;
    }

    try {
      final userData = json.decode(userDataStr);
      final userId = userData['_id'] ?? userData['id'];
      developer.log('Retrieved user ID: $userId', name: 'AuthService');
      return userId;
    } catch (e) {
      developer.log('Error decoding user data: $e', name: 'AuthService');
      return null;
    }
  }
}
