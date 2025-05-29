import 'package:first_app_new/services/api_service.dart';
import 'package:flutter/material.dart';
import '../models/order_model/order_model.dart';
import '../utils/order_debug_helper.dart';

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
          .map((orderJson) {
            try {
              // Debug the data types of problematic fields
              if (orderJson is Map<String, dynamic>) {
                _debugOrderDataTypes(orderJson);
                // Use the dedicated debug helper for more detailed diagnostics
                OrderDebugHelper.debugPrintOrder(orderJson);
              }

              return Order.fromJson(orderJson as Map<String, dynamic>);
            } catch (e) {
              // Print more detailed error info
              String errorMsg = 'Error parsing order: $e';
              if (e.toString().contains(
                "type 'int' is not a subtype of type 'String'",
              )) {
                errorMsg +=
                    '\nLikely integer to string conversion error with a field.';
              }

              debugPrint(
                '$errorMsg for order: ${orderJson is Map ? orderJson['_id'] ?? 'unknown' : 'non-map object'}',
              );
              // Return null for orders that failed to parse
              return null;
            }
          })
          .where((order) => order != null) // Filter out null orders
          .cast<Order>() // Cast the non-null orders to Order
          .where(
            (order) => _shouldShowOrderToDeliveryPerson(order),
          ) // Filter active orders only
          .toList();
    } catch (e) {
      debugPrint('Error fetching orders: $e');
      return [];
    }
  }

  // Helper method to debug the URL construction
  void _debugUrl(String endpoint) {
    try {
      final fullUrl = ApiService.testBuildUrl(endpoint).toString();
      debugPrint('Full API URL will be: $fullUrl');
    } catch (e) {
      debugPrint('Error debugging URL: $e');
    }
  }

  // Update order status
  Future<Order?> updateOrderStatus(
    String orderId,
    String status,
    String deliveryPerson,
    String validationCode,
  ) async {
    debugPrint('Updating order status: orderId=$orderId, status=$status');
    try {
      final authToken = await _getToken();
      if (authToken == null) {
        debugPrint('Error: Cannot update order status without a valid token');
        return null;
      }

      final Map<String, dynamic> data = {
        'status': status,
        'deliveryPerson': deliveryPerson,
      };

      // Only include validation code if it's not empty
      if (validationCode.isNotEmpty) {
        data['validationCode'] = validationCode;
        debugPrint('Including validation code in request: $validationCode');
      } else {
        debugPrint('No validation code provided for this status update');
      }

      debugPrint('Sending API request to update order status: $data');

      // Use orderId from the order object, not the order reference number
      final endpoint = 'orders/$orderId/status';

      // Debug the full URL that will be used
      _debugUrl(endpoint);

      debugPrint('Using PATCH request to endpoint: $endpoint');
      final response = await ApiService.patch(endpoint, data);

      debugPrint('API response for order status update: ${response.keys}');

      if (response.containsKey('error')) {
        debugPrint('API Error: ${response['error']}');
        if (response['statusCode'] == 401) {
          debugPrint('Unauthorized: Token may be invalid or expired');
        }
        return null;
      }

      // Handle different response formats
      Order? parsedOrder;

      if (response.containsKey('order')) {
        try {
          debugPrint('Parsing order from response["order"]');
          final orderData = response['order'];
          if (orderData is Map<String, dynamic>) {
            _debugOrderDataTypes(orderData);
            parsedOrder = Order.fromJson(orderData);
          } else {
            debugPrint(
              'Error: response["order"] is not a Map: ${orderData.runtimeType}',
            );
          }
        } catch (e) {
          debugPrint('Error parsing updated order: $e');
        }
      }

      if (parsedOrder == null && response.containsKey('data')) {
        try {
          debugPrint('Parsing order from response["data"]');
          final dataObj = response['data'];
          if (dataObj is Map<String, dynamic>) {
            _debugOrderDataTypes(dataObj);
            parsedOrder = Order.fromJson(dataObj);
          } else {
            debugPrint(
              'Error: response["data"] is not a Map: ${dataObj.runtimeType}',
            );
          }
        } catch (e) {
          debugPrint('Error parsing order from data: $e');
        }
      }

      // Try parsing the direct response as a last resort
      if (parsedOrder == null) {
        try {
          debugPrint('Attempting to parse direct response');
          _debugOrderDataTypes(response);
          parsedOrder = Order.fromJson(response);
        } catch (e) {
          debugPrint('Error parsing direct response: $e');
        }
      }

      if (parsedOrder != null) {
        debugPrint(
          'Successfully parsed updated order with status: ${parsedOrder.status}',
        );
        return parsedOrder;
      } else {
        debugPrint('Failed to parse order from any response format');
        return null;
      }
    } catch (e) {
      debugPrint('Exception while updating order status: $e');
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
          .map((orderJson) {
            try {
              // Debug the data types of problematic fields
              if (orderJson is Map<String, dynamic>) {
                _debugOrderDataTypes(orderJson);
                // Use the dedicated debug helper for more detailed diagnostics
                OrderDebugHelper.debugPrintOrder(orderJson);
              }

              return Order.fromJson(orderJson as Map<String, dynamic>);
            } catch (e) {
              debugPrint(
                'Error parsing order history: $e for order: ${orderJson is Map ? orderJson['_id'] ?? 'unknown' : 'non-map object'}',
              );
              // Return null for orders that failed to parse
              return null;
            }
          })
          .where((order) => order != null) // Filter out null orders
          .cast<Order>() // Cast the non-null orders to Order
          .toList();
    } catch (e) {
      debugPrint('Error fetching order history: $e');
      return [];
    }
  }

  // Helper method to debug why some orders might be missing
  Future<void> debugMissingOrders(String userId) async {
    try {
      final authToken = await _getToken();
      if (authToken == null) {
        debugPrint('Error: Cannot fetch orders without a valid token');
        return;
      }

      // Directly query the backend to see ALL orders assigned to this livreur
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

      // Prepare a list to store the orders
      List<dynamic> ordersData = [];

      // Handle different response formats
      if (response.containsKey('orders')) {
        final orders = response['orders'];
        if (orders is List) {
          ordersData = orders;
        } else {
          debugPrint(
            'Error: response["orders"] is not a List: ${orders.runtimeType}',
          );
        }
      } else if (response.containsKey('data')) {
        final data = response['data'];
        if (data is List) {
          ordersData = data;
        } else {
          debugPrint(
            'Error: response["data"] is not a List: ${data.runtimeType}',
          );
        }
      } else {
        // If the response doesn't contain orders or data, but isn't an error,
        // it might be a single order or another structure
        debugPrint('Response doesn\'t contain orders or data arrays');
        debugPrint('Response keys: ${response.keys.join(", ")}');

        // Single order case
        if (response.containsKey('_id')) {
          ordersData = [response];
        }
      }

      debugPrint('Total orders in raw response: ${ordersData.length}');

      // Use our OrderDebugHelper to print details about each order
      if (ordersData.isNotEmpty) {
        OrderDebugHelper.debugPrintOrders(ordersData);
      }

      // Log basic details of each order
      for (int i = 0; i < ordersData.length; i++) {
        final order = ordersData[i];
        if (order is Map<String, dynamic>) {
          debugPrint(
            'Order #$i - ID: ${order['_id']} - Status: ${order['status']} - Reference: ${order['reference'] ?? order['orderRef'] ?? 'N/A'}',
          );
        } else {
          debugPrint('Order #$i - Not a Map: ${order.runtimeType}');
        }
      }

      debugPrint('============================');
    } catch (e) {
      debugPrint('Error in debugMissingOrders: $e');
    }
  }

  // Add this helper method for debugging data types
  void _debugOrderDataTypes(Map<String, dynamic> orderJson) {
    try {
      // Print key data fields and their types
      debugPrint('==== Order Data Types ====');
      if (orderJson.containsKey('_id')) {
        debugPrint(
          '_id: ${orderJson['_id']} (${orderJson['_id'].runtimeType})',
        );
      }
      if (orderJson.containsKey('order')) {
        debugPrint(
          'order: ${orderJson['order']} (${orderJson['order'].runtimeType})',
        );
      }
      if (orderJson.containsKey('reference')) {
        debugPrint(
          'reference: ${orderJson['reference']} (${orderJson['reference'].runtimeType})',
        );
      }
      if (orderJson.containsKey('orderRef')) {
        debugPrint(
          'orderRef: ${orderJson['orderRef']} (${orderJson['orderRef'].runtimeType})',
        );
      }
      if (orderJson.containsKey('validationCode')) {
        debugPrint(
          'validationCode: ${orderJson['validationCode']} (${orderJson['validationCode'].runtimeType})',
        );
      }
      debugPrint('==== End of Order Data Types ====');
    } catch (e) {
      debugPrint('Error debugging order data types: $e');
    }
  }

  // Helper method to determine if an order should be shown to delivery person
  bool _shouldShowOrderToDeliveryPerson(Order order) {
    final status = order.status.toLowerCase();

    // Hide cancelled, completed, and delivered orders from delivery person's active list
    final hiddenStatuses = ['cancelled', 'completed', 'delivered'];

    if (hiddenStatuses.contains(status)) {
      debugPrint(
        'Filtering out order ${order.order} with status: ${order.status}',
      );
      return false;
    }

    return true;
  }
}
