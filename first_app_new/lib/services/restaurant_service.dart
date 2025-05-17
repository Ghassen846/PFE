import 'dart:io';
import 'package:first_app_new/services/api_service.dart';
import 'package:flutter/material.dart';

class RestaurantService {
  // Get all restaurants
  static Future<List<Map<String, dynamic>>> getRestaurants() async {
    try {
      final response = await ApiService.get('restaurants');

      if (response.containsKey('error')) {
        throw Exception(response['error']);
      }

      if (response.containsKey('data') && response['data'] is List) {
        return List<Map<String, dynamic>>.from(response['data']);
      }

      return [];
    } catch (e) {
      debugPrint('Error fetching restaurants: $e');
      return [];
    }
  }

  // Get restaurant by ID
  static Future<Map<String, dynamic>> getRestaurantById(
    String restaurantId,
  ) async {
    try {
      final response = await ApiService.get('restaurants/$restaurantId');

      if (response.containsKey('error')) {
        throw Exception(response['error']);
      }

      return response;
    } catch (e) {
      debugPrint('Error fetching restaurant: $e');
      return {'error': 'Failed to fetch restaurant: $e'};
    }
  }

  // Create restaurant with image upload
  static Future<Map<String, dynamic>> createRestaurant(
    Map<String, dynamic> restaurantData,
    File? imageFile,
  ) async {
    try {
      if (imageFile != null) {
        // Remove image property from data as we'll send it as a file
        final Map<String, String> fields = {};
        restaurantData.forEach((key, value) {
          if (value != null && key != 'image') {
            fields[key] = value.toString();
          }
        });

        return await ApiService.uploadFile(
          'restaurants',
          imageFile,
          'image',
          fields: fields,
        );
      } else {
        return await ApiService.post('restaurants', restaurantData);
      }
    } catch (e) {
      debugPrint('Error creating restaurant: $e');
      return {'error': 'Failed to create restaurant: $e'};
    }
  }

  // Rate restaurant
  static Future<Map<String, dynamic>> rateRestaurant(
    String restaurantId,
    int rating,
    String clientId,
  ) async {
    try {
      final response = await ApiService.post('restaurants/$restaurantId/rate', {
        'clientId': clientId,
        'rating': rating,
      });

      if (response.containsKey('error')) {
        throw Exception(response['error']);
      }

      return response;
    } catch (e) {
      debugPrint('Error rating restaurant: $e');
      return {'error': 'Failed to rate restaurant: $e'};
    }
  }
}
