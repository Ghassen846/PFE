import 'package:flutter/material.dart';
import 'ApiService.dart';

class DeliveryService {
  // Get all deliveries
  static Future<List<Map<String, dynamic>>> getDeliveries() async {
    try {
      final response = await ApiService.get('deliveries');

      if (response.containsKey('error')) {
        throw Exception(response['error']);
      }

      if (response is List) {
        return List<Map<String, dynamic>>.from([response]);
      } else if (response.containsKey('deliveries')) {
        return List<Map<String, dynamic>>.from(response['deliveries']);
      }

      return [];
    } catch (e) {
      debugPrint('Error fetching deliveries: $e');
      return [];
    }
  }

  // Get delivery by ID
  static Future<Map<String, dynamic>> getDeliveryById(String deliveryId) async {
    try {
      final response = await ApiService.get('deliveries/$deliveryId');

      if (response.containsKey('error')) {
        throw Exception(response['error']);
      }

      return response;
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
        return List<Map<String, dynamic>>.from([response]);
      } else if (response.containsKey('deliveries')) {
        return List<Map<String, dynamic>>.from(response['deliveries']);
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

      return response;
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
        return [Map<String, dynamic>.from(response)];
      }

      return [];
    } catch (e) {
      debugPrint('Error fetching livreur locations: $e');
      return [];
    }
  }
}
