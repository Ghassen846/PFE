import 'package:flutter/material.dart';
import 'ApiService.dart';
import 'AuthService.dart';

class OrderService {
  // Get all orders
  static Future<List<Map<String, dynamic>>> getOrders() async {
    try {
      final response = await ApiService.get('orders');

      if (response.containsKey('error')) {
        throw Exception(response['error']);
      }

      if (response is List) {
        return List<Map<String, dynamic>>.from([response]);
      } else if (response.containsKey('orders')) {
        return List<Map<String, dynamic>>.from(response['orders']);
      }

      return [];
    } catch (e) {
      debugPrint('Error fetching orders: $e');
      return [];
    }
  }

  // Get orders for the current user
  static Future<List<Map<String, dynamic>>> getMyOrders() async {
    try {
      final userId = await AuthService.getUserId();

      if (userId == null) {
        throw Exception('User ID not found');
      }

      final response = await ApiService.get('orders/user/$userId');

      if (response.containsKey('error')) {
        throw Exception(response['error']);
      }

      if (response is List) {
        return List<Map<String, dynamic>>.from([response]);
      } else if (response.containsKey('orders')) {
        return List<Map<String, dynamic>>.from(response['orders']);
      }

      return [];
    } catch (e) {
      debugPrint('Error fetching user orders: $e');
      return [];
    }
  }

  // Get orders assigned to the current livreur
  static Future<List<Map<String, dynamic>>> getDeliveryOrders() async {
    try {
      final response = await ApiService.get('orders/livreur');

      if (response.containsKey('error')) {
        throw Exception(response['error']);
      }

      if (response is List) {
        return List<Map<String, dynamic>>.from([response]);
      } else if (response.containsKey('orders')) {
        return List<Map<String, dynamic>>.from(response['orders']);
      } else
        return [response];
    } catch (e) {
      debugPrint('Error fetching delivery orders: $e');
      return [];
    }
  }

  // Create a new order
  static Future<Map<String, dynamic>> createOrder(
    Map<String, dynamic> orderData,
  ) async {
    try {
      final response = await ApiService.post('orders/add', orderData);

      if (response.containsKey('error')) {
        throw Exception(response['error']);
      }

      return response;
    } catch (e) {
      debugPrint('Error creating order: $e');
      return {'error': 'Failed to create order: $e'};
    }
  }

  // Update order status
  static Future<Map<String, dynamic>> updateOrderStatus(
    String orderId,
    String status,
  ) async {
    try {
      final response = await ApiService.patch('orders/$orderId/status', {
        'status': status,
      });

      if (response.containsKey('error')) {
        throw Exception(response['error']);
      }

      return response;
    } catch (e) {
      debugPrint('Error updating order status: $e');
      return {'error': 'Failed to update order status: $e'};
    }
  }

  // Assign livreur to order
  static Future<Map<String, dynamic>> assignLivreur(
    String orderId,
    String livreurId,
  ) async {
    try {
      final response = await ApiService.patch(
        'orders/$orderId/assign-livreur',
        {'livreur': livreurId},
      );

      if (response.containsKey('error')) {
        throw Exception(response['error']);
      }

      return response;
    } catch (e) {
      debugPrint('Error assigning livreur: $e');
      return {'error': 'Failed to assign livreur: $e'};
    }
  }
}
