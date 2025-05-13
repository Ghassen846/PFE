import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ApiService.dart';
import 'AuthService.dart';

class ProfileUpdateService {
  // Get user profile
  static Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final userId = await AuthService.getUserId();

      if (userId == null) {
        throw Exception('User ID not found');
      }

      final response = await ApiService.get('user/profile');

      if (response.containsKey('error')) {
        throw Exception(response['error']);
      }

      // Convert to Map<String, dynamic>
      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      throw Exception('Failed to fetch profile: $e');
    }
  }

  // Update user profile data
  static Future<Map<String, dynamic>> updateProfile({
    required String firstName,
    required String name,
    required String email,
    required String phone,
    required String username,
  }) async {
    try {
      final userId = await AuthService.getUserId();

      if (userId == null) {
        throw Exception('User ID not found');
      }
      final data = {
        'firstName': firstName,
        'name': name, // Changed from 'LastName' to 'name' to match backend
        'email': email,
        'phone': phone,
        'username': username,
      };
      final response = await ApiService.put('user/$userId', data);

      if (response.containsKey('error')) {
        throw Exception(response['error']);
      } // Handle both possible response formats
      if (response.containsKey('user')) {
        return Map<String, dynamic>.from(response['user']);
      }

      // Return directly if the response itself is the user data
      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint('Error updating profile: $e');
      throw Exception('Failed to update profile: $e');
    }
  }

  // Upload profile image
  static Future<String> uploadProfileImage(File imageFile) async {
    try {
      final userId = await AuthService.getUserId();

      if (userId == null) {
        throw Exception('User ID not found');
      }
      final response = await ApiService.uploadFile(
        'user/upload-image',
        imageFile,
        'image',
      );

      if (response.containsKey('error')) {
        throw Exception(response['error']);
      }

      // Return image URL from response
      if (response.containsKey('image')) {
        return response['image'] ?? '';
      } else if (response.containsKey('imageUrl')) {
        return response['imageUrl'] ?? '';
      } else {
        throw Exception('Image URL not found in response');
      }
    } catch (e) {
      debugPrint('Error uploading image: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  // Delete profile image
  static Future<bool> deleteProfileImage() async {
    try {
      final userId = await AuthService.getUserId();

      if (userId == null) {
        throw Exception('User ID not found');
      }
      final response = await ApiService.delete('user/delete-image/$userId');

      if (response.containsKey('error')) {
        throw Exception(response['error']);
      }

      return true;
    } catch (e) {
      debugPrint('Error deleting image: $e');
      throw Exception('Failed to delete image: $e');
    }
  }

  // Show toast message helper
  static void showToast({required String message, bool isError = false}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: isError ? Colors.red : Colors.green,
      textColor: Colors.white,
    );
  }

  // Store updated user data in shared preferences
  static Future<void> updateLocalUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('firstName', userData['firstName'] ?? '');
      await prefs.setString(
        'name',
        userData['name'] ?? '',
      ); // Changed from 'LastName' to 'name' to match backend
      await prefs.setString('email', userData['email'] ?? '');
      await prefs.setString('phone', userData['phone'] ?? '');
      await prefs.setString('username', userData['username'] ?? '');

      if (userData['image'] != null) {
        await prefs.setString('image', userData['image']);
      }
    } catch (e) {
      debugPrint('Error updating local data: $e');
    }
  }

  // Change user password
  static Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final userId = await AuthService.getUserId();

      if (userId == null) {
        throw Exception('User ID not found');
      }

      final data = {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      };

      final response = await ApiService.post('user/change-password', data);

      if (response.containsKey('error')) {
        throw Exception(response['error'] ?? 'Password change failed');
      }

      return true;
    } catch (e) {
      debugPrint('Error changing password: $e');
      throw Exception('Failed to change password: $e');
    }
  }
}
