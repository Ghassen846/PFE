import 'package:flutter/material.dart';
import 'package:first_app_new/services/api_service.dart';

// Notification model
class NotificationItem {
  final String id;
  final String type;
  final String message;
  final bool read;
  final DateTime timestamp;
  final Map<String, dynamic> data;
  final String? senderName;

  NotificationItem({
    required this.id,
    required this.type,
    required this.message,
    required this.timestamp,
    required this.read,
    this.data = const {},
    this.senderName,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    DateTime? timestamp;
    try {
      if (json['createdAt'] != null) {
        if (json['createdAt'] is String) {
          timestamp = DateTime.parse(json['createdAt']);
        } else {
          timestamp = DateTime.fromMillisecondsSinceEpoch(
            (json['createdAt'] as num).toInt(),
          );
        }
      }
    } catch (e) {
      debugPrint('Error parsing notification timestamp: $e');
    }

    Map<String, dynamic> data = {};
    if (json['data'] is Map) {
      data = Map<String, dynamic>.from(json['data'] as Map);
    }

    String senderName = '';
    if (json['sender'] is Map) {
      final sender = json['sender'] as Map;
      final firstName = sender['firstName']?.toString() ?? '';
      final name = sender['name']?.toString() ?? '';
      senderName = '$firstName $name'.trim();
    }

    return NotificationItem(
      id: json['_id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'system_message',
      message: json['message']?.toString() ?? '',
      read: json['read'] == true,
      timestamp: timestamp ?? DateTime.now(),
      data: data,
      senderName: senderName,
    );
  }
}

// Service to fetch notifications
class NotificationService {
  /// Fetches notifications from the backend API
  static Future<List<NotificationItem>> fetchNotifications() async {
    try {
      final dynamic response = await ApiService.get('notifications');

      // Extract notifications list from response
      List<dynamic> notificationsList = [];

      if (response is List) {
        notificationsList = response;
      } else if (response is Map<String, dynamic>) {
        if (response.containsKey('error')) {
          throw response['error'].toString();
        }
        notificationsList = response['notifications'] as List? ?? [];
      }

      // Map notifications to objects
      return notificationsList
          .whereType<Map>()
          .map(
            (item) =>
                NotificationItem.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList()
        ..sort(
          (a, b) => b.timestamp.compareTo(a.timestamp),
        ); // Sort by timestamp
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      rethrow;
    }
  }

  /// Marks a notification as read
  static Future<bool> markAsRead(String notificationId) async {
    try {
      final response = await ApiService.put(
        'notifications/$notificationId/read',
        {},
      );
      final message = response['message']?.toString() ?? '';
      return message.contains('read');
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      return false;
    }
  }

  /// Marks all notifications as read
  static Future<bool> markAllAsRead() async {
    try {
      final response = await ApiService.put('notifications/read-all', {});
      final message = response['message']?.toString() ?? '';
      return message.contains('read');
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      return false;
    }
  }

  /// Deletes a notification
  static Future<bool> deleteNotification(String notificationId) async {
    try {
      final response = await ApiService.delete('notifications/$notificationId');
      final message = response['message']?.toString() ?? '';
      return message.contains('deleted');
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      return false;
    }
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

  Color _typeColor(String type) {
    switch (type) {
      case 'delivery_assigned':
        return Colors.blue;
      case 'order_delivered':
        return Colors.green;
      case 'order_status_changed':
        return Colors.orange;
      case 'system_message':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'delivery_assigned':
        return Icons.assignment_ind;
      case 'order_delivered':
        return Icons.check_circle_outline;
      case 'order_status_changed':
        return Icons.local_shipping_outlined;
      case 'system_message':
        return Icons.notifications;
      default:
        return Icons.notifications;
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _futureNotifications = NotificationService.fetchNotifications();
    });
  }

  Future<void> _markAsRead(NotificationItem notification) async {
    if (!notification.read) {
      final success = await NotificationService.markAsRead(notification.id);
      if (success && mounted) {
        _refresh();
      }
    }
  }

  Future<void> _markAllAsRead() async {
    final success = await NotificationService.markAllAsRead();
    if (success && mounted) {
      _refresh();
    }
  }

  Future<void> _deleteNotification(NotificationItem notification) async {
    final success = await NotificationService.deleteNotification(
      notification.id,
    );
    if (success && mounted) {
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: _markAllAsRead,
            tooltip: 'Mark all as read',
          ),
        ],
      ),
      body: FutureBuilder<List<NotificationItem>>(
        future: _futureNotifications,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading notifications\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final items = snapshot.data!;
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.notifications_off,
                    size: 48,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text('No notifications'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final notification = items[index];
                return Dismissible(
                  key: Key(notification.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) => _deleteNotification(notification),
                  child: Card(
                    elevation: 2,
                    color:
                        !notification.read
                            ? Theme.of(context).colorScheme.primaryContainer
                            : null,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _typeColor(
                          notification.type,
                        ).withOpacity(0.1),
                        child: Icon(
                          _typeIcon(notification.type),
                          color: _typeColor(notification.type),
                        ),
                      ),
                      title: Text(
                        notification.message,
                        style:
                            !notification.read
                                ? const TextStyle(fontWeight: FontWeight.bold)
                                : null,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (notification.senderName?.isNotEmpty ?? false)
                            Text(
                              'From: ${notification.senderName}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          Text(
                            'Date: ${notification.timestamp.day}/${notification.timestamp.month}/${notification.timestamp.year} '
                            '${notification.timestamp.hour.toString().padLeft(2, '0')}:'
                            '${notification.timestamp.minute.toString().padLeft(2, '0')}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      trailing:
                          !notification.read
                              ? const Icon(Icons.mark_email_unread, size: 16)
                              : null,
                      onTap: () => _markAsRead(notification),
                    ),
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
