import 'package:first_app_new/services/api_service.dart';
import 'package:flutter/material.dart';
import '../models/order_model/order_model.dart';
import 'dart:async';

class OrderDebugUtils {
  // Add a debouncer to prevent rapid status updates
  static final Map<String, Timer> _statusUpdateTimers = {};
  static const _debounceMs = 500; // Debounce time in milliseconds

  // Helper to get token from SharedPreferences or secure storage
  static Future<String?> _getToken() async {
    final token = await ApiService.getToken();
    if (token == null) {
      debugPrint('Error: No token found in storage');
    }
    return token;
  }

  // Helper method for debugging data types
  static void _debugOrderDataTypes(Map<String, dynamic> orderJson) {
    try {
      debugPrint('==== Order Data Types ====');

      // Convert numeric order/reference fields to strings if needed
      var orderValue = orderJson['order'];
      if (orderValue != null && orderValue is! String) {
        orderJson['order'] = orderValue.toString();
      }

      var orderRefValue = orderJson['orderRef'];
      if (orderRefValue != null && orderRefValue is! String) {
        orderJson['orderRef'] = orderRefValue.toString();
      }

      var referenceValue = orderJson['reference'];
      if (referenceValue != null && referenceValue is! String) {
        orderJson['reference'] = referenceValue.toString();
      }

      // Print the data types
      for (var key in [
        '_id',
        'order',
        'reference',
        'orderRef',
        'validationCode',
      ]) {
        if (orderJson.containsKey(key)) {
          debugPrint(
            '$key: ${orderJson[key]} (${orderJson[key]?.runtimeType})',
          );
        }
      }

      debugPrint('========================');
    } catch (e) {
      debugPrint('Error debugging order data types: $e');
    }
  }

  // Helper method to extract orders from response
  static List<Map<String, dynamic>> _extractOrdersFromResponse(
    dynamic response,
  ) {
    if (response is List) {
      return response
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    } else if (response is Map<String, dynamic>) {
      if (response.containsKey('orders') && response['orders'] is List) {
        return (response['orders'] as List)
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList();
      } else if (response.containsKey('data') && response['data'] is List) {
        return (response['data'] as List)
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList();
      } else {
        // Single order response
        return [Map<String, dynamic>.from(response)];
      }
    }
    return [];
  }

  // Helper method to debug why some orders might be missing
  static Future<void> debugMissingOrders(String userId) async {
    try {
      final authToken = await _getToken();
      if (authToken == null) {
        debugPrint('Error: Cannot fetch orders without a valid token');
        return;
      }

      final response = await ApiService.get('orders/livreur?userId=$userId');

      debugPrint('==== DEBUG MISSING ORDERS ====');
      debugPrint('User ID: $userId');
      debugPrint(
        'Response status: ${response.containsKey('error') ? 'Error' : 'Success'}',
      );

      if (response.containsKey('error')) {
        debugPrint('API Error: ${response['error']}');
        return;
      }

      // Extract and process orders
      final ordersData = _extractOrdersFromResponse(response);
      debugPrint('Total orders in raw response: ${ordersData.length}');

      // Log basic details of each order
      for (int i = 0; i < ordersData.length; i++) {
        var order = ordersData[i];

        // Convert numeric fields to strings before debugging
        if (order['order'] != null && order['order'] is! String) {
          order['order'] = order['order'].toString();
        }
        if (order['orderRef'] != null && order['orderRef'] is! String) {
          order['orderRef'] = order['orderRef'].toString();
        }
        if (order['reference'] != null && order['reference'] is! String) {
          order['reference'] = order['reference'].toString();
        }

        final orderId = order['_id']?.toString() ?? 'unknown';
        final status = order['status']?.toString() ?? 'unknown';
        final reference =
            order['reference']?.toString() ??
            order['orderRef']?.toString() ??
            'N/A';

        debugPrint(
          'Order #$i - ID: $orderId - Status: $status - Reference: $reference',
        );

        _debugOrderDataTypes(order);

        // Check if this order would parse successfully
        try {
          final parsedOrder = Order.fromJson(order);
          debugPrint('✅ Order parsed successfully: ${parsedOrder.orderId}');
        } catch (e) {
          debugPrint('❌ Order parsing would fail: $e');
        }
      }

      debugPrint('============================');
    } catch (e) {
      debugPrint('Error in debugMissingOrders: $e');
    }
  }

  // Add this function to handle debounced status updates
  static Future<void> updateOrderStatusWithDebounce(
    String orderId,
    String status, {
    String? validationCode,
  }) async {
    // Cancel any pending updates for this order
    _statusUpdateTimers[orderId]?.cancel();

    // Create new debounced update
    _statusUpdateTimers[orderId] = Timer(
      Duration(milliseconds: _debounceMs),
      () async {
        try {
          final Map<String, String> body = {
            'status': status,
            'deliveryPerson': '',
          };
          if (validationCode != null) {
            body['validationCode'] = validationCode;
          }

          debugPrint('Sending status update for order $orderId: $status');
          await ApiService.patch('orders/$orderId/status', body);
          debugPrint('Status update successful for order $orderId');
        } catch (e) {
          debugPrint('Error updating order status: $e');
        }
      },
    );
  }
}
