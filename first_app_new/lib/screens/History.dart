import 'package:first_app_new/services/api_service.dart';
import 'package:flutter/material.dart';

// Model class for delivery history items
class Delivery {
  final String orderId;
  final String status;
  final DateTime date;
  final String livreurName;
  final String customerName;
  final String customerPhone;
  final String deliveryAddress;
  final double? totalAmount;

  Delivery({
    required this.orderId,
    required this.status,
    required this.date,
    required this.livreurName,
    this.customerName = '',
    this.customerPhone = '',
    this.deliveryAddress = '',
    this.totalAmount,
  });
  factory Delivery.fromJson(Map<String, dynamic> json) {
    try {
      // Extract order data from nested structure
      Map<String, dynamic> orderData = {};
      if (json['order'] is Map) {
        orderData = json['order'] as Map<String, dynamic>;
      } else if (json['order'] is String) {
        debugPrint('Order data is a string, possibly an ID reference');
      }

      Map<String, dynamic> userData = {};
      if (orderData['user'] is Map) {
        userData = orderData['user'] as Map<String, dynamic>;
      } else if (json['user'] is Map) {
        userData = json['user'] as Map<String, dynamic>;
      }

      DateTime? parsedDate;
      try {
        if (json['createdAt'] != null) {
          parsedDate = DateTime.parse(json['createdAt'].toString());
        } else if (orderData['createdAt'] != null) {
          parsedDate = DateTime.parse(orderData['createdAt'].toString());
        }
      } catch (e) {
        debugPrint('Error parsing date: $e');
      }

      final driverData = json['driver'] ?? orderData['livreur'];
      Map<String, dynamic> driverMap = {};
      if (driverData is Map) {
        driverMap = driverData as Map<String, dynamic>;
      }

      return Delivery(
        orderId: json['_id']?.toString() ?? orderData['_id']?.toString() ?? '',
        status:
            json['status']?.toString() ??
            orderData['status']?.toString() ??
            'Unknown',
        date: parsedDate ?? DateTime.now(),
        livreurName: _getDriverName(driverMap),
        customerName: _getCustomerName(userData),
        customerPhone: userData['phone']?.toString() ?? '',
        deliveryAddress: orderData['deliveryAddress']?.toString() ?? '',
        totalAmount: _parseAmount(orderData['totalPrice']),
      );
    } catch (e) {
      debugPrint('Error parsing delivery JSON: $e');
      return Delivery(
        orderId: 'error',
        status: 'error',
        date: DateTime.now(),
        livreurName: 'Unknown',
      );
    }
  }

  static String _getDriverName(Map<String, dynamic>? driver) {
    if (driver == null) return 'Unknown';
    final firstName = driver['firstName'] ?? '';
    final name = driver['name'] ?? '';
    return '$firstName $name'.trim();
  }

  static String _getCustomerName(Map<String, dynamic> user) {
    final firstName = user['firstName'] ?? '';
    final name = user['name'] ?? '';
    return '$firstName $name'.trim();
  }

  static double? _parseAmount(dynamic amount) {
    if (amount == null) return null;
    if (amount is num) return amount.toDouble();
    if (amount is String) return double.tryParse(amount);
    return null;
  }
}

// Service to fetch delivery history data
class DeliveryService {
  /// Fetches delivery history from the API
  static Future<List<Delivery>> fetchDeliveryHistory() async {
    try {
      // First try to get the user ID
      final userId = await ApiService.getUserId();
      if (userId == null) {
        debugPrint('Error: Cannot fetch history without user ID');
        return [];
      }

      // Fetch deliveries using the user ID
      final response = await ApiService.get(
        'deliveries/by-status',
        queryParams: {'userId': userId},
      );

      if (response.containsKey('error')) {
        debugPrint('Error fetching delivery history: ${response['error']}');
        return [];
      }
      List<dynamic> deliveriesData = [];
      if (response.containsKey('deliveries')) {
        final deliveries = response['deliveries'];
        if (deliveries is List) {
          deliveriesData = deliveries;
        }
      } else if (response.containsKey('data')) {
        final data = response['data'];
        if (data is List) {
          deliveriesData = data;
        }
      } else {
        debugPrint('Unexpected API response format');
        return [];
      }
    
      if (deliveriesData.isEmpty) {
        debugPrint('No delivery history found');
        return [];
      }

      // Map the API response to Delivery objects
      final deliveries =
          deliveriesData
              .map(
                (delivery) =>
                    Delivery.fromJson(delivery as Map<String, dynamic>),
              )
              .toList();

      // Sort by date, most recent first
      deliveries.sort((a, b) => b.date.compareTo(a.date));

      return deliveries;
    } catch (e) {
      debugPrint('Error fetching delivery history: $e');
      return [];
    }
  }
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green;
      case 'delivering':
      case 'picked_up':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Icons.check_circle;
      case 'delivering':
      case 'picked_up':
        return Icons.local_shipping;
      case 'cancelled':
        return Icons.cancel;
      case 'pending':
        return Icons.schedule;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery History')),
      body: FutureBuilder<List<Delivery>>(
        future: DeliveryService.fetchDeliveryHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final history = snapshot.data!;
          if (history.isEmpty) {
            return const Center(child: Text('No deliveries found.'));
          }

          return RefreshIndicator(
            onRefresh: () => DeliveryService.fetchDeliveryHistory(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final delivery = history[index];
                return Card(
                  elevation: 2,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _statusColor(
                        delivery.status,
                      ).withOpacity(0.1),
                      child: Icon(
                        _statusIcon(delivery.status),
                        color: _statusColor(delivery.status),
                      ),
                    ),
                    title: Text('Order #${delivery.orderId}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (delivery.customerName.isNotEmpty)
                          Text(
                            delivery.customerName,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        Text(
                          '${delivery.livreurName} · '
                          '${delivery.date.day}/${delivery.date.month}/${delivery.date.year} '
                          '${delivery.date.hour.toString().padLeft(2, '0')}:'
                          '${delivery.date.minute.toString().padLeft(2, '0')}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          delivery.status,
                          style: TextStyle(
                            color: _statusColor(delivery.status),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (delivery.totalAmount != null)
                          Text(
                            '\$${delivery.totalAmount!.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                    onTap: () {
                      // Navigation to detail page can be added here
                      // Navigator.push(context, MaterialPageRoute(builder: (context) => DeliveryDetailScreen(delivery: delivery)));
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
