import 'package:flutter/foundation.dart';
import '../models/order_model/order_model.dart';

class OrderDebugHelper {
  /// Print detailed information about an order to diagnose parsing issues
  static void debugPrintOrder(dynamic orderJson) {
    try {
      if (orderJson == null) {
        debugPrint('⚠️ Ordre is null');
        return;
      }
      if (orderJson is! Map) {
        debugPrint('⚠️ Ordre is not a Map: ${orderJson.runtimeType}');
        return;
      }

      final map = orderJson; // No need for cast

      debugPrint('=== 🔍 ORDRE DEBUG INFO ===');
      debugPrint('ID: ${map['_id']}');

      // Check for problematic integer fields
      final fieldsToCheck = [
        'order',
        'reference',
        'orderRef',
        'validationCode',
      ];

      for (final field in fieldsToCheck) {
        if (map.containsKey(field)) {
          final value = map[field];
          final type = value?.runtimeType;
          debugPrint('$field: $value ($type)');

          if (type == int) {
            debugPrint(
              '⚠️ WARNING: $field is an integer but should be a string',
            );
          }
        }
      }

      // Try to parse the order
      try {
        final order = Order.fromJson(Map<String, dynamic>.from(map));
        debugPrint('✅ Order parsed successfully: ${order.orderId}');
      } catch (e) {
        debugPrint('❌ Failed to parse order: $e');
      }

      debugPrint('=========================');
    } catch (e) {
      debugPrint('Error in debugPrintOrder: $e');
    }
  }

  /// For debugging multiple orders
  static void debugPrintOrders(List<dynamic> orders) {
    debugPrint('Debug printing ${orders.length} orders:');
    for (int i = 0; i < orders.length; i++) {
      debugPrint('Order #$i:');
      debugPrintOrder(orders[i]);
    }
  }
}
