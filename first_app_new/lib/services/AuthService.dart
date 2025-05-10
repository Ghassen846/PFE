import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'ApiService.dart';

class AuthService {
  static const secureStorage = FlutterSecureStorage();

  // Register user with image upload support
  static Future<Map<String, dynamic>> registerUser({
    required String username,
    required String firstName,
    required String name,
    required String email,
    required String password,
    required String phone,
    String role = 'livreur', // Changed default from 'client' to 'livreur'
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
        'role': role,
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
        return await ApiService.uploadFile(
          'user/register',
          profileImage,
          'image', // Use 'image' field name for compatibility with backend
          fields: fields,
        );
      } else {
        // No image, use regular post
        return await ApiService.post('user/register', fields);
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
      debugPrint('Attempting login for email: $email');

      final response = await ApiService.post('user/login', {
        'email': email,
        'password': password,
      });

      if (response.containsKey('error')) {
        debugPrint('Login error: ${response['error']}');
        return response;
      }

      debugPrint('Login response: $response');

      // If login successful, save token
      if (response.containsKey('token')) {
        debugPrint('Token found in response, saving to secure storage');
        final token = response['token'];
        await secureStorage.write(key: 'token', value: token);

        // Also save as a fallback in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);

        debugPrint('Token saved successfully');
      } else {
        debugPrint('No token found in response: ${response.keys}');
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
      await prefs.setString(
        'role',
        userData['role'] ?? 'livreur',
      ); // Changed default from 'client' to 'livreur'

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

  // Get current user token
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
