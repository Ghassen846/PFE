import 'package:flutter/material.dart';

// Notification model
class NotificationItem {
  final String orderId;
  final String status;
  final String address;
  final DateTime timestamp;
  final String livreurName;

  NotificationItem({
    required this.orderId,
    required this.status,
    required this.address,
    required this.timestamp,
    required this.livreurName,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      orderId: json['orderId'],
      status: json['status'],
      address: json['address'],
      timestamp: DateTime.parse(json['timestamp']),
      livreurName: json['livreurName'],
    );
  }
}

// Service to fetch notifications
class NotificationService {
  /// Simulates a network call to retrieve notifications
  static Future<List<NotificationItem>> fetchNotifications() async {
    await Future.delayed(const Duration(seconds: 1)); // simulated latency

    final dummyData = [
      {
        'orderId': '1234',
        'status': 'Delivered',
        'address': '12 rue de la Paix, Paris',
        'timestamp': '2025-05-17T14:20:00',
        'livreurName': 'Alice Dupont',
      },
      {
        'orderId': '5678',
        'status': 'In Transit',
        'address': '34 avenue Victor Hugo, Lyon',
        'timestamp': '2025-05-17T16:45:00',
        'livreurName': 'Bob Martin',
      },
      {
        'orderId': '9101',
        'status': 'Cancelled',
        'address': '56 boulevard Haussmann, Paris',
        'timestamp': '2025-05-18T09:15:00',
        'livreurName': 'Charlie Leroy',
      },
      {
        'orderId': '1121',
        'status': 'In Transit',
        'address': '78 rue Gambetta, Marseille',
        'timestamp': '2025-05-18T10:30:00',
        'livreurName': 'David Garcia',
      },
    ];

    return dummyData.map((json) => NotificationItem.fromJson(json)).toList();
  }
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late Future<List<NotificationItem>> _futureNotifications;

  @override
  void initState() {
    super.initState();
    _futureNotifications = NotificationService.fetchNotifications();
  }

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
        return Icons.check_circle_outline;
      case 'In Transit':
        return Icons.local_shipping_outlined;
      case 'Cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.notifications;
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _futureNotifications = NotificationService.fetchNotifications();
    });
    await _futureNotifications;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: FutureBuilder<List<NotificationItem>>(
        future: _futureNotifications,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final items = snapshot.data!;
          if (items.isEmpty) {
            return const Center(child: Text('No notifications'));
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final notification = items[index];
                return Card(
                  elevation: 2,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _statusColor(
                        notification.status,
                      ).withOpacity(0.1),
                      child: Icon(
                        _statusIcon(notification.status),
                        color: _statusColor(notification.status),
                      ),
                    ),
                    title: Text('Order #${notification.orderId}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Status: ${notification.status}'),
                        Text('Address: ${notification.address}'),
                        Text(
                          'Date: '
                          '${notification.timestamp.day}/${notification.timestamp.month}/${notification.timestamp.year} '
                          '${notification.timestamp.hour.toString().padLeft(2, '0')}:'
                          '${notification.timestamp.minute.toString().padLeft(2, '0')}',
                        ),
                        Text('Delivery by: ${notification.livreurName}'),
                      ],
                    ),
                    isThreeLine: true,
                    onTap: () {
                      // Navigate to notification detail page (to be implemented)
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
