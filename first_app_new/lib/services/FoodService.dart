import 'dart:io';
import 'package:flutter/material.dart';
import 'ApiService.dart';

class FoodService {
  // Get all food items
  static Future<List<Map<String, dynamic>>> getFoodItems() async {
    try {
      final response = await ApiService.get('foods');

      // Handle error case
      if (response.containsKey('error')) {
        debugPrint('API error: ${response['error']}');
        return [];
      }

      // Handle response as Map with data field
      if (response.containsKey('data')) {
        var data = response['data'];
        if (data is List<dynamic>) {
          return _convertToMapList(data);
        } else {
          debugPrint(
            'Error: response["data"] is not a List, got: ${data.runtimeType}',
          );
          return [];
        }
      } else {
        debugPrint(
          'Error: response does not contain "data" key, got: $response',
        );
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching food items: $e');
      return [];
    }
  }

  // Helper method to safely convert List to List<Map<String, dynamic>>
  static List<Map<String, dynamic>> _convertToMapList(List<dynamic> items) {
    List<Map<String, dynamic>> result = [];

    for (var item in items) {
      if (item is Map) {
        // Convert to Map<String, dynamic> carefully
        Map<String, dynamic> convertedMap = {};
        item.forEach((key, value) {
          if (key is String) {
            convertedMap[key] = value;
          }
        });
        result.add(convertedMap);
      }
    }

    return result;
  }

  // Get food item by ID
  static Future<Map<String, dynamic>> getFoodItemById(String foodId) async {
    try {
      final response = await ApiService.get('foods/$foodId');

      if (response.containsKey('error')) {
        throw Exception(response['error']);
      }

      return response;
    } catch (e) {
      debugPrint('Error fetching food item: $e');
      return {'error': 'Failed to fetch food item: $e'};
    }
  }

  // Create food item with image upload
  static Future<Map<String, dynamic>> createFoodItem(
    Map<String, dynamic> foodData,
    File? imageFile,
  ) async {
    try {
      if (imageFile != null) {
        // Remove image property from data as we'll send it as a file
        final Map<String, String> fields = {};
        foodData.forEach((key, value) {
          if (value != null && key != 'image') {
            fields[key] = value.toString();
          }
        });

        return await ApiService.uploadFile(
          'foods',
          imageFile,
          'image',
          fields: fields,
        );
      } else {
        return await ApiService.post('foods', foodData);
      }
    } catch (e) {
      debugPrint('Error creating food item: $e');
      return {'error': 'Failed to create food item: $e'};
    }
  }

  // Update food item
  static Future<Map<String, dynamic>> updateFoodItem(
    String foodId,
    Map<String, dynamic> foodData, {
    File? imageFile,
  }) async {
    try {
      if (imageFile != null) {
        // Remove image property from data as we'll send it as a file
        final Map<String, String> fields = {};
        foodData.forEach((key, value) {
          if (value != null && key != 'image') {
            fields[key] = value.toString();
          }
        });

        return await ApiService.uploadFile(
          'foods/$foodId',
          imageFile,
          'image',
          fields: fields,
        );
      } else {
        return await ApiService.put('foods/$foodId', foodData);
      }
    } catch (e) {
      debugPrint('Error updating food item: $e');
      return {'error': 'Failed to update food item: $e'};
    }
  }

  // Rate food item
  static Future<Map<String, dynamic>> rateFood(
    String foodId,
    int rating,
    String clientId,
  ) async {
    try {
      final response = await ApiService.post('foods/$foodId/rate', {
        'clientId': clientId,
        'rating': rating,
      });

      if (response.containsKey('error')) {
        throw Exception(response['error']);
      }

      return response;
    } catch (e) {
      debugPrint('Error rating food: $e');
      return {'error': 'Failed to rate food: $e'};
    }
  }
}
