import 'package:first_app_new/services/api_service.dart';
import 'package:flutter/material.dart';
import '../models/order_model/order_model.dart';

// Import centralized services

class OrderService {
  // Helper to get token from SharedPreferences or secure storage
  Future<String?> _getToken() async {
    final token = await ApiService.getToken();
    if (token == null) {
      debugPrint('Error: No token found in storage');
    }
    return token;
  }

  // Get all orders specific to a delivery person
  Future<List<Order>> getOrders() async {
    try {
      final authToken = await _getToken();
      if (authToken == null) {
        debugPrint('Error: Cannot fetch orders without a valid token');
        return [];
      }

      // Get the user ID using ApiService's getUserId method
      final userId = await ApiService.getUserId();
      if (userId == null) {
        debugPrint('Error: Cannot fetch orders without a valid user ID');
        return [];
      }

      debugPrint('Fetching orders for delivery person (userId: $userId)');

      // Use userId in the query parameters
      var response = await ApiService.get(
        'orders/delivery/current',
        queryParams: {'userId': userId},
      );

      debugPrint(
        'Orders API response: ${response.toString().substring(0, response.toString().length > 300 ? 300 : response.toString().length)}...',
      );

      // If there's an error or no orders, try the mock endpoint
      if (response.containsKey('error') ||
          (!response.containsKey('orders') && !response.containsKey('data'))) {
        debugPrint('Primary endpoint failed, trying mock endpoint...');

        // Try the mock endpoint we created for testing
        response = await ApiService.get('delivery/mock-delivery-orders');

        debugPrint(
          'Mock API response: ${response.toString().substring(0, response.toString().length > 300 ? 300 : response.toString().length)}...',
        );
      }

      if (response.containsKey('error')) {
        debugPrint('API Error: ${response['error']}');
        if (response['statusCode'] == 401) {
          debugPrint('Unauthorized: Token may be invalid or expired');
          // Optionally trigger re-login (handled by UI)
        }
        return [];
      }

      List<dynamic> ordersData = [];
      if (response.containsKey('orders')) {
        final orders = response['orders'];
        if (orders is List) {
          ordersData = orders;
        } else {
          debugPrint(
            'Error: response["orders"] is not a List, got: ${orders.runtimeType}',
          );
        }
      } else if (response.containsKey('data')) {
        final data = response['data'];
        if (data is List) {
          ordersData = data;
        } else {
          debugPrint(
            'Error: response["data"] is not a List, got: ${data.runtimeType}',
          );
        }
      } else {
        if (!response.containsKey('error')) {
          ordersData = [response];
        } else {
          debugPrint('Error: Unexpected response structure: $response');
        }
      }

      return ordersData
          .map((orderJson) => Order.fromJson(orderJson as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching orders: $e');
      return [];
    }
  }

  // Update order status
  Future<Order?> updateOrderStatus(
    String orderId,
    String status,
    String deliveryPerson,
    String validationCode,
  ) async {
    try {
      final authToken = await _getToken();
      if (authToken == null) {
        debugPrint('Error: Cannot update order status without a valid token');
        return null;
      }

      final Map<String, dynamic> data = {
        'status': status,
        'deliveryPerson': deliveryPerson,
        'validationCode': validationCode,
      };
      final response = await ApiService.put('orders/$orderId/status', data);

      if (response.containsKey('error')) {
        debugPrint('API Error: ${response['error']}');
        if (response['statusCode'] == 401) {
          debugPrint('Unauthorized: Token may be invalid or expired');
          // Optionally trigger re-login (handled by UI)
        }
        return null;
      }

      // Return the updated order
      if (response.containsKey('order')) {
        return Order.fromJson(response['order']);
      } else if (response.containsKey('data')) {
        return Order.fromJson(response['data']);
      }

      return Order.fromJson(response);
    } catch (e) {
      debugPrint('Error updating order status: $e');
      return null;
    }
  }

  // Get order history for delivery person
  Future<List<Order>> getOrderHistory() async {
    try {
      final authToken = await _getToken();
      if (authToken == null) {
        debugPrint('Error: Cannot fetch order history without a valid token');
        return [];
      }

      final response = await ApiService.get('orders/history');

      if (response.containsKey('error')) {
        debugPrint('API Error: ${response['error']}');
        if (response['statusCode'] == 401) {
          debugPrint('Unauthorized: Token may be invalid or expired');
          // Optionally trigger re-login (handled by UI)
        }
        return [];
      }

      List<dynamic> ordersData = [];
      if (response.containsKey('orders')) {
        final orders = response['orders'];
        if (orders is List) {
          ordersData = orders;
        } else {
          debugPrint(
            'Error: response["orders"] is not a List, got: ${orders.runtimeType}',
          );
        }
      } else if (response.containsKey('data')) {
        final data = response['data'];
        if (data is List) {
          ordersData = data;
        } else {
          debugPrint(
            'Error: response["data"] is not a List, got: ${data.runtimeType}',
          );
        }
      } else {
        debugPrint('Error: Unexpected response structure: $response');
      }

      return ordersData
          .map((orderJson) => Order.fromJson(orderJson as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching order history: $e');
      return [];
    }
  }
}
