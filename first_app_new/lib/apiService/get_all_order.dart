// filepath: c:\Users\PC\developement\flutter-apps\first_app_new\lib\apiService\get_all_order.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api.dart';

class OrderService {
  // Get all orders
  static Future<List<Map<String, dynamic>>> getAllOrders({
    String? status,
    bool? isDelivered,
    String? restaurantId,
    String? deliveryPersonId,
    String? clientId,
  }) async {
    try {
      // Build query string based on provided filters
      final List<String> queryParams = [];

      if (status != null) {
        queryParams.add('status=$status');
      }

      if (isDelivered != null) {
        queryParams.add('isDelivered=${isDelivered.toString()}');
      }

      if (restaurantId != null) {
        queryParams.add('restaurantId=$restaurantId');
      }

      if (deliveryPersonId != null) {
        queryParams.add('deliveryPersonId=$deliveryPersonId');
      }

      if (clientId != null) {
        queryParams.add('clientId=$clientId');
      }

      final queryString =
          queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';

      final response = await ApiClient.get('orders$queryString');

      if (response.containsKey('error')) {
        debugPrint('API Error: ${response['error']}');
        return [];
      }

      // Check for data in response and convert to List<Map>
      if (response.containsKey('data')) {
        final data = response['data'];
        if (data is List) {
          return data.map((item) => Map<String, dynamic>.from(item)).toList();
        }
      }

      // If no orders found or unexpected response format
      debugPrint('Unexpected response format: $response');
      return [];
    } catch (e) {
      debugPrint('Error fetching orders: $e');
      return [];
    }
  }

  // Get an order by ID
  static Future<Map<String, dynamic>> getOrderById(String orderId) async {
    try {
      final response = await ApiClient.get('orders/$orderId');

      if (response.containsKey('error')) {
        throw Exception('Failed to get order: ${response['error']}');
      }

      return response;
    } catch (e) {
      debugPrint('Error fetching order: $e');
      return {'error': 'Failed to fetch order: $e'};
    }
  }

  // Get orders for the current delivery person
  static Future<List<Map<String, dynamic>>> getDeliveryPersonOrders({
    String? status,
  }) async {
    try {
      // Get the delivery person ID (would normally come from auth state or storage)
      final deliveryPersonId = await _getCurrentDeliveryPersonId();
      if (deliveryPersonId == null) {
        throw Exception('User is not logged in or not a delivery person');
      }

      String endpoint = 'orders/delivery/$deliveryPersonId';
      if (status != null) {
        endpoint += '?status=$status';
      }

      final response = await ApiClient.get(endpoint);

      if (response.containsKey('error')) {
        throw Exception('Failed to get delivery orders: ${response['error']}');
      }

      if (response.containsKey('data') && response['data'] is List) {
        return (response['data'] as List)
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }

      return [];
    } catch (e) {
      debugPrint('Error fetching delivery orders: $e');
      return [];
    }
  }

  // Get orders for a client
  static Future<List<Map<String, dynamic>>> getClientOrders({
    String? status,
  }) async {
    try {
      // Get the client ID (would normally come from auth state or storage)
      final clientId = await _getCurrentUserId();
      if (clientId == null) {
        throw Exception('User is not logged in');
      }

      String endpoint = 'orders/client/$clientId';
      if (status != null) {
        endpoint += '?status=$status';
      }

      final response = await ApiClient.get(endpoint);

      if (response.containsKey('error')) {
        throw Exception('Failed to get client orders: ${response['error']}');
      }

      if (response.containsKey('data') && response['data'] is List) {
        return (response['data'] as List)
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }

      return [];
    } catch (e) {
      debugPrint('Error fetching client orders: $e');
      return [];
    }
  }

  // Helper method to get currently logged in user ID
  static Future<String?> _getCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('userId');
    } catch (e) {
      debugPrint('Error getting current user ID: $e');
      return null;
    }
  }

  // Helper method to get currently logged in delivery person ID
  static Future<String?> _getCurrentDeliveryPersonId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString('role');

      if (role == 'delivery' || role == 'livreur') {
        return prefs.getString('userId');
      }

      return null;
    } catch (e) {
      debugPrint('Error getting delivery person ID: $e');
      return null;
    }
  }
}

// End of OrderService class
