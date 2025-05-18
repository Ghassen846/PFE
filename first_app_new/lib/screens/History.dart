import 'package:flutter/material.dart';

// Model class for delivery history items
class Delivery {
  final String orderId;
  final String status;
  final DateTime date;
  final String livreurName;

  Delivery({
    required this.orderId,
    required this.status,
    required this.date,
    required this.livreurName,
  });

  factory Delivery.fromJson(Map<String, dynamic> json) {
    return Delivery(
      orderId: json['orderId'],
      status: json['status'],
      date: DateTime.parse(json['date']),
      livreurName: json['livreurName'],
    );
  }
}

// Service to fetch delivery history data
class DeliveryService {
  /// Simulates a network call that returns the list of past deliveries
  static Future<List<Delivery>> fetchDeliveryHistory() async {
    await Future.delayed(const Duration(seconds: 1)); // simulated latency

    // Mock data
    final data = [
      {
        'orderId': '1234',
        'status': 'Delivered',
        'date': '2025-05-10T14:30:00',
        'livreurName': 'Alice Dupont',
      },
      {
        'orderId': '5678',
        'status': 'In Transit',
        'date': '2025-05-12T09:15:00',
        'livreurName': 'Bob Martin',
      },
      {
        'orderId': '9101',
        'status': 'Cancelled',
        'date': '2025-05-11T17:00:00',
        'livreurName': 'Charlie Leroy',
      },
      {
        'orderId': '1121',
        'status': 'Delivered',
        'date': '2025-05-09T11:45:00',
        'livreurName': 'David Garcia',
      },
      {
        'orderId': '3141',
        'status': 'In Transit',
        'date': '2025-05-15T08:30:00',
        'livreurName': 'Emma Wilson',
      },
      {
        'orderId': '5161',
        'status': 'Cancelled',
        'date': '2025-05-08T16:20:00',
        'livreurName': 'Frank Johnson',
      },
    ];

    return data.map((json) => Delivery.fromJson(json)).toList();
  }
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  Color _statusColor(String status) {
    switch (status) {
      case 'Delivered':
        return Colors.green;
      case 'In Transit':
        return Colors.orange;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Delivered':
        return Icons.check_circle;
      case 'In Transit':
        return Icons.local_shipping;
      case 'Cancelled':
        return Icons.cancel;
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
                    subtitle: Text(
                      '${delivery.livreurName} · '
                      '${delivery.date.day}/${delivery.date.month}/${delivery.date.year} '
                      '${delivery.date.hour.toString().padLeft(2, '0')}:'
                      '${delivery.date.minute.toString().padLeft(2, '0')}',
                    ),
                    trailing: Text(
                      delivery.status,
                      style: TextStyle(
                        color: _statusColor(delivery.status),
                        fontWeight: FontWeight.bold,
                      ),
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
