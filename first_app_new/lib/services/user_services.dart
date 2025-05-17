import 'dart:io';
import 'package:first_app_new/services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

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
        "address": address,
        "phone": phone,
        "image": image,
        "username": username,
        "email": email,
      };

      developer.log(
        'Updating user information for userId: $userId with data: $data',
        name: 'UserService',
      );
      final response = await ApiService.patch('api/user/$userId', data);

      if (response.containsKey("user")) {
        // Update local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fullName', fullName);
        await prefs.setString(
          'name',
          fullName,
        ); // Updated to 'name' for consistency
        await prefs.setString('email', email);
        await prefs.setString('phone', phone);
        await prefs.setString('username', username);
        await prefs.setString('image', image);

        developer.log(
          'User information updated successfully',
          name: 'UserService',
        );
        return 200;
      } else if (response.containsKey("error")) {
        developer.log(
          'Error updating user: ${response["error"]}',
          name: 'UserService',
        );
        return 400;
      }

      developer.log('Unexpected response: $response', name: 'UserService');
      return 400;
    } catch (e) {
      developer.log('Exception updating user: $e', name: 'UserService');
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

      if (image == null) {
        developer.log('No image selected', name: 'UserService');
        return "no image selected";
      }

      final File imageFile = File(image.path);
      developer.log(
        'Uploading profile image for userId: $userId, file: ${imageFile.path}',
        name: 'UserService',
      );
      final response = await ApiService.uploadFile(
        'api/user/$userId/image',
        imageFile,
        'image',
      );

      if (response.containsKey('error')) {
        developer.log(
          'Upload failed: ${response['error']}',
          name: 'UserService',
        );
        return 'Upload failed: ${response['error']}';
      }

      if (response.containsKey('user') &&
          response['user'] != null &&
          response['user']['image'] != null) {
        String imageUrl = response['user']['image'];
        // Save to shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('image', imageUrl);
        developer.log('Profile image updated: $imageUrl', name: 'UserService');
        return imageUrl;
      } else if (response.containsKey('image')) {
        String imageUrl = response['image'];
        // Save to shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('image', imageUrl);
        developer.log('Profile image updated: $imageUrl', name: 'UserService');
        return imageUrl;
      } else if (response.containsKey('imageUrl')) {
        String imageUrl = response['imageUrl'];
        // Save to shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('image', imageUrl);
        developer.log('Profile image updated: $imageUrl', name: 'UserService');
        return imageUrl;
      }

      developer.log(
        'Image URL not found in response: $response',
        name: 'UserService',
      );
      return 'Image URL not found in response';
    } catch (e) {
      developer.log('Error updating profile image: $e', name: 'UserService');
      return 'Error: $e';
    }
  }

  // Get dashboard data for delivery users
  static Future<Map<String, dynamic>> getDashboardData({
    required String username,
  }) async {
    try {
      developer.log(
        'Fetching dashboard data for username: $username',
        name: 'UserService',
      );
      final response = await ApiService.get(
        'api/statistics/delivery/$username',
      );

      if (response.containsKey('error')) {
        developer.log(
          'Error getting dashboard: ${response['error']}',
          name: 'UserService',
        );
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
        developer.log('Dashboard data fetched: $response', name: 'UserService');
        return response;
      } else {
        developer.log(
          'No deliveryMan in response, returning defaults',
          name: 'UserService',
        );
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
      developer.log('Error getting dashboard data: $e', name: 'UserService');
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
      developer.log(
        'Fetching user profile for userId: $userId',
        name: 'UserService',
      );
      final response = await ApiService.get('api/user/$userId');

      if (response.containsKey('error')) {
        developer.log(
          'Error fetching user profile: ${response['error']}',
          name: 'UserService',
        );
        throw Exception(response['error']);
      }

      developer.log('User profile fetched: $response', name: 'UserService');
      return response;
    } catch (e) {
      developer.log('Exception fetching user profile: $e', name: 'UserService');
      return {'error': 'Failed to fetch user profile: $e'};
    }
  }

  // Get current user profile
  static Future<Map<String, dynamic>> getCurrentUserProfile() async {
    try {
      developer.log('Fetching current user profile', name: 'UserService');
      final response = await ApiService.get('api/user/me');

      if (response.containsKey('error')) {
        developer.log(
          'Error fetching current user profile: ${response['error']}',
          name: 'UserService',
        );
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

        developer.log(
          'Current user profile fetched: ${response['user']}',
          name: 'UserService',
        );
        return response['user'];
      }

      developer.log(
        'Current user profile fetched (no user key): $response',
        name: 'UserService',
      );
      return response;
    } catch (e) {
      developer.log(
        'Exception fetching current user profile: $e',
        name: 'UserService',
      );
      return {'error': 'Failed to fetch current user profile: $e'};
    }
  }
}
