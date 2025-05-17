import 'package:first_app_new/services/api_service.dart';
import 'package:first_app_new/services/image_service.dart';
import 'package:flutter/material.dart';

class DeliveryService {
  // Get all deliveries
  static Future<List<Map<String, dynamic>>> getDeliveries() async {
    try {
      final response = await ApiService.get('deliveries');

      if (response.containsKey('error')) {
        throw Exception(response['error']);
      }

      if (response is List) {
        return _processDeliveryResults(
          List<Map<String, dynamic>>.from([response]),
        );
      } else if (response.containsKey('deliveries')) {
        return _processDeliveryResults(
          List<Map<String, dynamic>>.from(response['deliveries']),
        );
      }

      return [];
    } catch (e) {
      debugPrint('Error fetching deliveries: $e');
      return [];
    }
  }

  // Helper method to process delivery data and fix image URLs
  static List<Map<String, dynamic>> _processDeliveryResults(
    List<Map<String, dynamic>> deliveries,
  ) {
    return deliveries.map((delivery) {
      // Process any image URLs in the delivery data
      if (delivery.containsKey('driver') && delivery['driver'] != null) {
        var driver = delivery['driver'] as Map<String, dynamic>;
        if (driver.containsKey('image') && driver['image'] != null) {
          // Fix driver image URL if it's already a full URL to prevent double URLs
          driver['image'] = _fixImageUrlIfNeeded(driver['image'] as String);
        }
      }

      if (delivery.containsKey('client') && delivery['client'] != null) {
        var client = delivery['client'] as Map<String, dynamic>;
        if (client.containsKey('image') && client['image'] != null) {
          // Fix client image URL if needed
          client['image'] = _fixImageUrlIfNeeded(client['image'] as String);
        }
      }

      // Process order and food images if they exist
      if (delivery.containsKey('order') && delivery['order'] != null) {
        var order = delivery['order'] as Map<String, dynamic>;
        if (order.containsKey('items') && order['items'] is List) {
          final items = order['items'] as List;
          for (var i = 0; i < items.length; i++) {
            if (items[i] is Map &&
                items[i].containsKey('food') &&
                items[i]['food'] is Map) {
              var food = items[i]['food'] as Map<String, dynamic>;
              if (food.containsKey('imageUrl') && food['imageUrl'] != null) {
                food['imageUrl'] = _fixImageUrlIfNeeded(
                  food['imageUrl'] as String,
                );
              }
            }
          }
        }
      }
      return delivery;
    }).toList();
  }

  // Helper method to fix image URLs that may already have the full URL
  static String _fixImageUrlIfNeeded(String imageUrl) {
    // If the URL contains "/uploads/http:", it's a double-prefixed URL
    if (imageUrl.contains('/uploads/http:')) {
      final parts = imageUrl.split('/uploads/');
      if (parts.length >= 2) {
        // Return only the second part that contains the actual URL
        return parts.last.startsWith('http:')
            ? parts.last
            : 'http:${parts.last}';
      }
    }

    // Check if the URL has a duplicated prefix
    if (imageUrl.contains('http://') &&
        imageUrl.indexOf('http://') != imageUrl.lastIndexOf('http://')) {
      // Extract the actual path from the double URL
      final startOfSecondHttp = imageUrl.indexOf(
        'http://',
        imageUrl.indexOf('http://') + 7,
      );
      return imageUrl.substring(startOfSecondHttp);
    }

    // If it's already a full URL, return as is; otherwise, process it
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl; // Already a full URL, return as is
    }

    return ImageService.getFullImageUrl(imageUrl);
  }

  // Get delivery by ID
  static Future<Map<String, dynamic>> getDeliveryById(String deliveryId) async {
    try {
      final response = await ApiService.get('deliveries/$deliveryId');

      if (response.containsKey('error')) {
        throw Exception(response['error']);
      }

      // Process the delivery to fix any image URLs
      return _processDeliveryResults([response])[0];
    } catch (e) {
      debugPrint('Error fetching delivery: $e');
      return {'error': 'Failed to fetch delivery: $e'};
    }
  }

  // Get deliveries for a specific livreur
  static Future<List<Map<String, dynamic>>> getDeliveriesByLivreur(
    String livreurId,
  ) async {
    try {
      final response = await ApiService.get('deliveries/livreur/$livreurId');

      if (response.containsKey('error')) {
        throw Exception(response['error']);
      }

      if (response is List) {
        return _processDeliveryResults(
          List<Map<String, dynamic>>.from([response]),
        );
      } else if (response.containsKey('deliveries')) {
        return _processDeliveryResults(
          List<Map<String, dynamic>>.from(response['deliveries']),
        );
      }

      return [];
    } catch (e) {
      debugPrint('Error fetching livreur deliveries: $e');
      return [];
    }
  }

  // Update delivery status
  static Future<Map<String, dynamic>> updateDeliveryStatus(
    String deliveryId,
    String status,
  ) async {
    try {
      final response = await ApiService.patch('deliveries/$deliveryId/status', {
        'status': status,
      });

      if (response.containsKey('error')) {
        throw Exception(response['error']);
      }

      // Process the response to fix any image URLs
      return _processDeliveryResults([response])[0];
    } catch (e) {
      debugPrint('Error updating delivery status: $e');
      return {'error': 'Failed to update delivery status: $e'};
    }
  }

  // Update livreur location
  static Future<Map<String, dynamic>> updateLivreurLocation(
    String livreurId,
    double latitude,
    double longitude, {
    String? address,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'latitude': latitude,
        'longitude': longitude,
      };

      if (address != null) {
        data['address'] = address;
      }

      final response = await ApiService.patch(
        'deliveries/location/$livreurId',
        data,
      );

      if (response.containsKey('error')) {
        throw Exception(response['error']);
      }

      return response;
    } catch (e) {
      debugPrint('Error updating livreur location: $e');
      return {'error': 'Failed to update location: $e'};
    }
  }

  // Get livreur locations
  static Future<List<Map<String, dynamic>>> getLivreurLocations() async {
    try {
      final response = await ApiService.get('deliveries/locations');

      if (response.containsKey('error')) {
        throw Exception(response['error']);
      }

      if (response is List) {
        return _processDeliveryResults([Map<String, dynamic>.from(response)]);
      }

      return [];
    } catch (e) {
      debugPrint('Error fetching livreur locations: $e');
      return [];
    }
  }
}
