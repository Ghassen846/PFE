import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ApiService.dart';

class UserService {
  // Update user information
  static Future<int> updateUserInformation({
    required String userId,
    required String fullName,
    required String email,
    required String address,
    required String username,
    required String image,
    required String phone,
  }) async {
    try {
      final data = {
        "fullName": fullName,
        "adress": address,
        "phone": phone,
        "image": image,
        "username": username,
        "email": email,
      };

      final response = await ApiService.patch('user/$userId', data);

      if (response.containsKey("user")) {
        // Update local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fullName', fullName);
        await prefs.setString('name', fullName);
        await prefs.setString('email', email);
        await prefs.setString('phone', phone);
        await prefs.setString('username', username);
        await prefs.setString('image', image);

        return 200;
      } else if (response.containsKey("error")) {
        debugPrint('Error updating user: ${response["error"]}');
        return 400;
      }

      return 400;
    } catch (e) {
      debugPrint('Exception updating user: $e');
      return 500;
    }
  }

  // Update user profile image
  static Future<String> updateProfileImage({required String userId}) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) return "no image selected";

      final File imageFile = File(image.path);
      final response = await ApiService.uploadFile(
        'user/upload-image/$userId',
        imageFile,
        'image',
      );

      if (response.containsKey('error')) {
        return 'Upload failed: ${response['error']}';
      }

      if (response.containsKey('user') &&
          response['user'] != null &&
          response['user']['image'] != null) {
        String imageUrl = response['user']['image'];

        // Save to shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('image', imageUrl);

        return imageUrl;
      } else if (response.containsKey('image')) {
        String imageUrl = response['image'];

        // Save to shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('image', imageUrl);

        return imageUrl;
      }

      return 'Image URL not found in response';
    } catch (e) {
      debugPrint('Error updating profile image: $e');
      return 'Error: $e';
    }
  }

  // Get dashboard data for delivery users
  static Future<Map<String, dynamic>> getDashboardData({
    required String username,
  }) async {
    try {
      final response = await ApiService.get('statistics/delivery/$username');

      if (response.containsKey('error')) {
        debugPrint('Error getting dashboard: ${response['error']}');
        return {
          'completedDeliveries': 0,
          'deliveryMan': username,
          'pendingDeliveries': 0,
          'ratings': 0,
          'totalCanceled': 0,
          'totalCollected': "0",
          'totalDeliveries': 0,
        };
      }

      if (response.containsKey('deliveryMan')) {
        return response;
      } else {
        return {
          'completedDeliveries': 0,
          'deliveryMan': username,
          'pendingDeliveries': 0,
          'ratings': 0,
          'totalCanceled': 0,
          'totalCollected': "0",
          'totalDeliveries': 0,
        };
      }
    } catch (e) {
      debugPrint('Error getting dashboard data: $e');
      return {
        'completedDeliveries': 0,
        'deliveryMan': username,
        'pendingDeliveries': 0,
        'ratings': 0,
        'totalCanceled': 0,
        'totalCollected': "0",
        'totalDeliveries': 0,
      };
    }
  }

  // Get user profile
  static Future<Map<String, dynamic>> getUserProfile(String userId) async {
    try {
      final response = await ApiService.get('user/$userId');

      if (response.containsKey('error')) {
        throw Exception(response['error']);
      }

      return response;
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      return {'error': 'Failed to fetch user profile: $e'};
    }
  }

  // Get current user profile
  static Future<Map<String, dynamic>> getCurrentUserProfile() async {
    try {
      final response = await ApiService.get('user/me');

      if (response.containsKey('error')) {
        throw Exception(response['error']);
      }

      if (response.containsKey('user')) {
        // Cache user data
        final prefs = await SharedPreferences.getInstance();
        final userData = response['user'];

        if (userData != null) {
          await prefs.setString(
            'username',
            userData['username']?.toString() ?? '',
          );
          await prefs.setString('email', userData['email']?.toString() ?? '');
          await prefs.setString('phone', userData['phone']?.toString() ?? '');
          await prefs.setString('role', userData['role']?.toString() ?? '');
          await prefs.setString(
            'firstName',
            userData['firstName']?.toString() ?? '',
          );
          await prefs.setString('name', userData['name']?.toString() ?? '');

          if (userData['image'] != null) {
            await prefs.setString('image', userData['image'].toString());
          }
        }

        return response['user'];
      }

      return response;
    } catch (e) {
      debugPrint('Error fetching current user profile: $e');
      return {'error': 'Failed to fetch current user profile: $e'};
    }
  }
}
