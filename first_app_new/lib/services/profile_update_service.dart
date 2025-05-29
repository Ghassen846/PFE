import 'dart:io';
import 'package:first_app_new/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

class ProfileUpdateService {
  // Get user profile
  static Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final userId = await ApiService.getUserId();

      if (userId == null) {
        developer.log('User ID not found', name: 'ProfileUpdateService');
        throw Exception('User ID not found');
      }

      developer.log(
        'Fetching profile for user ID: $userId',
        name: 'ProfileUpdateService',
      );
      final response = await ApiService.get('user/me');

      if (response.containsKey('error')) {
        developer.log(
          'Error fetching profile: ${response['error']}',
          name: 'ProfileUpdateService',
        );
        throw Exception(response['error']);
      }

      developer.log(
        'Profile fetched successfully: $response',
        name: 'ProfileUpdateService',
      );
      return Map<String, dynamic>.from(response);
    } catch (e) {
      developer.log(
        'Exception fetching profile: $e',
        name: 'ProfileUpdateService',
      );
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
      final userId = await ApiService.getUserId();

      if (userId == null) {
        developer.log('User ID not found', name: 'ProfileUpdateService');
        throw Exception('User ID not found');
      }

      final data = {
        'firstName': firstName,
        'name': name,
        'email': email,
        'phone': phone,
        'username': username,
      };

      developer.log(
        'Updating profile for user ID: $userId with data: $data',
        name: 'ProfileUpdateService',
      );
      final response = await ApiService.put('user/$userId', data);

      if (response.containsKey('error')) {
        developer.log(
          'Error updating profile: ${response['error']}',
          name: 'ProfileUpdateService',
        );
        throw Exception(response['error']);
      }

      developer.log(
        'Profile updated successfully: $response',
        name: 'ProfileUpdateService',
      );
      // Handle both possible response formats
      if (response.containsKey('user')) {
        return Map<String, dynamic>.from(response['user']);
      }

      return Map<String, dynamic>.from(response);
    } catch (e) {
      developer.log(
        'Exception updating profile: $e',
        name: 'ProfileUpdateService',
      );
      throw Exception('Failed to update profile: $e');
    }
  }

  // Upload profile image
  static Future<String> uploadProfileImage(File imageFile) async {
    try {
      final userId = await ApiService.getUserId();

      if (userId == null) {
        developer.log('User ID not found', name: 'ProfileUpdateService');
        throw Exception('User ID not found');
      }

      developer.log(
        'Uploading profile image for user ID: $userId',
        name: 'ProfileUpdateService',
      );

      final response = await ApiService.uploadFile(
        'user/$userId/image',
        imageFile,
        'image',
      );

      if (response.containsKey('error')) {
        developer.log(
          'Error uploading image: ${response['error']}',
          name: 'ProfileUpdateService',
        );
        throw Exception(response['error']);
      }

      // Return image URL from response
      if (response.containsKey('image')) {
        developer.log(
          'Image uploaded successfully: ${response['image']}',
          name: 'ProfileUpdateService',
        );
        return response['image'] ?? '';
      } else if (response.containsKey('imageUrl')) {
        developer.log(
          'Image uploaded successfully: ${response['imageUrl']}',
          name: 'ProfileUpdateService',
        );
        return response['imageUrl'] ?? '';
      } else {
        developer.log(
          'Image URL not found in response',
          name: 'ProfileUpdateService',
        );
        throw Exception('Image URL not found in response');
      }
    } catch (e) {
      developer.log(
        'Exception uploading image: $e',
        name: 'ProfileUpdateService',
      );
      throw Exception('Failed to upload image: $e');
    }
  }

  // Delete profile image
  static Future<bool> deleteProfileImage() async {
    try {
      final userId = await ApiService.getUserId();

      if (userId == null) {
        developer.log('User ID not found', name: 'ProfileUpdateService');
        throw Exception('User ID not found');
      }

      developer.log(
        'Deleting profile image for user ID: $userId',
        name: 'ProfileUpdateService',
      );
      final response = await ApiService.delete('user/delete-image/$userId');

      if (response.containsKey('error')) {
        developer.log(
          'Error deleting image: ${response['error']}',
          name: 'ProfileUpdateService',
        );
        throw Exception(response['error']);
      }

      developer.log(
        'Profile image deleted successfully',
        name: 'ProfileUpdateService',
      );
      return true;
    } catch (e) {
      developer.log(
        'Exception deleting image: $e',
        name: 'ProfileUpdateService',
      );
      throw Exception('Failed to delete image: $e');
    }
  }

  // Show toast message helper
  static void showToast({required String message, bool isError = false}) {
    developer.log(
      'Showing toast: $message, isError: $isError',
      name: 'ProfileUpdateService',
    );
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
      developer.log(
        'Updating local user data: $userData',
        name: 'ProfileUpdateService',
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('firstName', userData['firstName'] ?? '');
      await prefs.setString('name', userData['name'] ?? '');
      await prefs.setString('email', userData['email'] ?? '');
      await prefs.setString('phone', userData['phone'] ?? '');
      await prefs.setString('username', userData['username'] ?? '');

      if (userData['image'] != null) {
        await prefs.setString('image', userData['image']);
      }
    } catch (e) {
      developer.log(
        'Error updating local data: $e',
        name: 'ProfileUpdateService',
      );
    }
  }

  // Change user password
  static Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final userId = await ApiService.getUserId();

      if (userId == null) {
        developer.log('User ID not found', name: 'ProfileUpdateService');
        throw Exception('User ID not found');
      }

      final data = {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      };

      developer.log(
        'Changing password for user ID: $userId',
        name: 'ProfileUpdateService',
      );
      final response = await ApiService.post('user/change-password', data);

      if (response.containsKey('error')) {
        developer.log(
          'Error changing password: ${response['error']}',
          name: 'ProfileUpdateService',
        );
        throw Exception(response['error'] ?? 'Password change failed');
      }

      developer.log(
        'Password changed successfully',
        name: 'ProfileUpdateService',
      );
      return true;
    } catch (e) {
      developer.log(
        'Exception changing password: $e',
        name: 'ProfileUpdateService',
      );
      throw Exception('Failed to change password: $e');
    }
  }
}
