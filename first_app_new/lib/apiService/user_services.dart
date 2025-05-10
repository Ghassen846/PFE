// filepath: c:\Users\PC\developement\flutter-apps\first_app_new\lib\apiService\user_services.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api.dart';

class UserService {
  static const secureStorage = FlutterSecureStorage();

  // Register a new user
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
  }) async {
    try {
      // Create fields map
      final fields = {
        'username': username,
        'firstName': firstName,
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'role': role = 'livreur',
      };

      // Add location if available
      if (latitude != null && longitude != null) {
        fields['location[latitude]'] = latitude.toString();
        fields['location[longitude]'] = longitude.toString();
      }

      if (role == 'livreur') {
        fields['vehiculetype'] = 'scooter'; // Default vehicle type
        fields['status'] = 'available'; // Default status
      }

      // If we have an image, use the uploadFile method
      if (profileImage != null) {
        return await ApiClient.uploadFile(
          'user/register',
          profileImage,
          'image', // Use 'image' field name for compatibility with backend
          fields: fields,
        );
      } else {
        // No image, use regular post
        return await ApiClient.post('user/register', fields);
      }
    } catch (e) {
      debugPrint('Registration error: $e');
      return {'error': 'Registration failed: $e'};
    }
  }

  // Login user
  static Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final response = await ApiClient.post('user/login', {
        'email': email,
        'password': password,
      });

      if (response.containsKey('error')) {
        return response;
      }

      // If login successful, save token
      if (response.containsKey('token')) {
        await secureStorage.write(key: 'token', value: response['token']);
      }

      return response;
    } catch (e) {
      debugPrint('Login error: $e');
      return {'error': 'Login failed: $e'};
    }
  }

  // Save user session data
  static Future<void> saveUserSession(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save token securely
      if (userData['token'] != null) {
        await secureStorage.write(key: 'token', value: userData['token']);
      }

      // Save user data in shared preferences
      await prefs.setString('userId', userData['_id'] ?? '');
      await prefs.setString('username', userData['username'] ?? '');
      await prefs.setString('firstName', userData['firstName'] ?? '');
      await prefs.setString('name', userData['name'] ?? '');
      await prefs.setString('email', userData['email'] ?? '');
      await prefs.setString('phone', userData['phone'] ?? '');
      await prefs.setString('role', userData['role'] ?? 'client');

      if (userData['image'] != null) {
        await prefs.setString('image', userData['image']);
      }

      // Save session status
      await prefs.setBool('isLoggedIn', true);
    } catch (e) {
      debugPrint('Error saving session: $e');
    }
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

      if (isLoggedIn) {
        // Verify token validity
        final token = await secureStorage.read(key: 'token');
        return token != null;
      }

      return false;
    } catch (e) {
      debugPrint('Error checking login status: $e');
      return false;
    }
  }

  // Get current user profile
  static Future<Map<String, dynamic>> getCurrentUserProfile() async {
    try {
      final userId = await getUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final response = await ApiClient.get('user/profile/$userId');

      if (response.containsKey('error')) {
        throw Exception('Failed to fetch profile: ${response['error']}');
      }

      return response;
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      return {'error': 'Failed to get user profile: $e'};
    }
  }

  // Update user profile
  static Future<Map<String, dynamic>> updateUserProfile({
    required Map<String, dynamic> userData,
    File? profileImage,
  }) async {
    try {
      final userId = await getUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      if (profileImage != null) {
        // Convert userData to string fields for multipart request
        final Map<String, String> fields = {};
        userData.forEach((key, value) {
          if (value != null && key != 'image') {
            fields[key] = value.toString();
          }
        });

        return await ApiClient.uploadFile(
          'user/profile/$userId',
          profileImage,
          'image',
          fields: fields,
        );
      } else {
        return await ApiClient.put('user/profile/$userId', userData);
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return {'error': 'Failed to update profile: $e'};
    }
  }

  // Change user password
  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final userId = await getUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      return await ApiClient.put('user/password/$userId', {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });
    } catch (e) {
      debugPrint('Error changing password: $e');
      return {'error': 'Failed to change password: $e'};
    }
  }

  // Get current user token
  static Future<String?> getToken() async {
    return await secureStorage.read(key: 'token');
  }

  // Get current user ID
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  // Get current user role
  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }

  // Get user data from shared preferences
  static Future<Map<String, dynamic>> getUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'userId': prefs.getString('userId') ?? '',
      'username': prefs.getString('username') ?? '',
      'firstName': prefs.getString('firstName') ?? '',
      'name': prefs.getString('name') ?? '',
      'email': prefs.getString('email') ?? '',
      'phone': prefs.getString('phone') ?? '',
      'role': prefs.getString('role') ?? '',
      'image': prefs.getString('image') ?? '',
      'isLoggedIn': prefs.getBool('isLoggedIn') ?? false,
    };
  }

  // Logout user
  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Delete token from secure storage
      await secureStorage.delete(key: 'token');

      // Clear all SharedPreferences
      await prefs.clear();
    } catch (e) {
      debugPrint('Error during logout: $e');
    }
  }
}
