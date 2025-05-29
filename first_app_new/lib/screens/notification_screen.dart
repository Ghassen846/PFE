import 'package:flutter/material.dart';
import 'package:first_app_new/services/api_service.dart';
import 'dart:developer';

// Notification model
class NotificationItem {
  final String id;
  final String type;
  final String message;
  final bool read;
  final DateTime timestamp;
  final Map<String, dynamic> data;
  final String? senderName;

  // Added getters for order-specific information
  String? get orderId =>
      data.containsKey('orderId')
          ? (data['orderId'] is Map
              ? data['orderId']['\$oid']?.toString()
              : data['orderId']?.toString())
          : null;

  String? get orderReference {
    // Extract order reference from message if available (e.g. #894803)
    final regex = RegExp(r'#(\d+)');
    final match = regex.firstMatch(message);
    return match?.group(1);
  }

  String? get orderStatus => data['status']?.toString();

  bool get isOrderRelated =>
      type == 'order_status_changed' ||
      type == 'delivery_assigned' ||
      type == 'order_delivered';

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
        } else if (json['createdAt'] is Map &&
            json['createdAt']['\$date'] != null) {
          // Handle MongoDB date format
          final dateStr = json['createdAt']['\$date'].toString();
          timestamp = DateTime.parse(dateStr);
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

    String? orderId;
    if (json['data'] != null && json['data'] is Map) {
      if (json['data']['orderId'] != null) {
        if (json['data']['orderId'] is String) {
          orderId = json['data']['orderId'];
        } else if (json['data']['orderId'] is Map &&
            json['data']['orderId']['\$oid'] != null) {
          orderId = json['data']['orderId']['\$oid'].toString();
        }
      }
    }

    if (orderId != null) {
      data['orderId'] = orderId;
    }

    return NotificationItem(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
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
      log('Fetching notifications from API');
      final dynamic response = await ApiService.get('notifications');

      log('API response received: ${response.runtimeType}');

      // Log the response for debugging
      if (response is Map) {
        log('Response data: ${response.keys}');
      } else if (response is List) {
        log('Response is a list with ${response.length} items');
      } else {
        log('Response is of unexpected type: ${response.runtimeType}');
      }

      // Extract notifications list from response
      List<dynamic> notificationsList = [];

      if (response is List) {
        notificationsList = response;
        log('Notifications list extracted directly from response array');
      } else if (response is Map<String, dynamic>) {
        if (response.containsKey('error')) {
          throw response['error'].toString();
        }

        // Try different possible paths for notifications in the response
        if (response.containsKey('notifications')) {
          notificationsList = response['notifications'] as List? ?? [];
          log('Notifications found in response.notifications');
        } else if (response.containsKey('data') &&
            response['data'] is Map &&
            response['data'].containsKey('notifications')) {
          notificationsList = response['data']['notifications'] as List? ?? [];
          log('Notifications found in response.data.notifications');
        } else if (response.containsKey('data') && response['data'] is List) {
          notificationsList = response['data'] as List? ?? [];
          log('Notifications found in response.data as list');
        } else {
          // If no recognized format, log keys to help troubleshoot
          log(
            'Could not find notifications in response. Keys: ${response.keys.join(', ')}',
          );

          // Try to use the whole response if it seems like it might be the notifications data
          if (response.containsKey('_id') || response.containsKey('message')) {
            notificationsList = [response];
            log('Using entire response as a single notification');
          }
        }
      }

      if (notificationsList.isEmpty) {
        log('No notifications found in the API response');
      }

      log('Processing ${notificationsList.length} notifications');

      // Map notifications to objects
      final result =
          notificationsList
              .whereType<Map>()
              .map((item) {
                try {
                  return NotificationItem.fromJson(
                    Map<String, dynamic>.from(item),
                  );
                } catch (e) {
                  log('Error parsing notification: $e');
                  return null;
                }
              })
              .whereType<NotificationItem>()
              .toList()
            ..sort(
              (a, b) => b.timestamp.compareTo(a.timestamp),
            ); // Sort by timestamp

      log('Returning ${result.length} parsed notifications');
      return result;
    } catch (e) {
      log('Error fetching notifications: $e');
      // Just rethrow the error to show the error state in UI
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
  bool _isDebugMode = false;
  String _debugInfo = '';

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
      _debugInfo = '';
    });
  }

  void _toggleDebugMode() {
    setState(() {
      _isDebugMode = !_isDebugMode;
      if (!_isDebugMode) {
        _debugInfo = '';
      }
    });
  }

  Future<void> _inspectApiResponse() async {
    try {
      final response = await ApiService.get('notifications');
      setState(() {
        _debugInfo = 'API Response: $response';
      });
    } catch (e) {
      setState(() {
        _debugInfo = 'API Error: $e';
      });
    }
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

  void _onNotificationTap(NotificationItem notification) async {
    // Mark as read
    await _markAsRead(notification);

    if (!mounted) return;

    // Handle navigation based on notification type
    if (notification.isOrderRelated && notification.orderId != null) {
      _navigateToOrderDetails(notification);
    } else {
      // Show details in a dialog for non-order notifications
      _showNotificationDetails(notification);
    }
  }

  void _navigateToOrderDetails(NotificationItem notification) {
    final orderId = notification.orderId;
    if (orderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order ID not found in notification')),
      );
      return;
    }

    // Show basic order info if we can't navigate
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Order ${notification.orderReference ?? "Details"}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Status: ${notification.orderStatus ?? "Unknown"}'),
                Text('Order ID: $orderId'),
                const SizedBox(height: 8),
                const Text(
                  'Navigate to order details not implemented.\nUpdate your navigation to handle order details.',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Close'),
              ),
            ],
          ),
    );

    // Uncomment when you have the route ready
    // Navigator.of(context).pushNamed(
    //   '/order-details',
    //   arguments: {'orderId': orderId, 'orderRef': notification.orderReference},
    // );
  }

  void _showNotificationDetails(NotificationItem notification) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(notification.type.replaceAll('_', ' ').toUpperCase()),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notification.message),
                const SizedBox(height: 8),
                Text(
                  'Received: ${_formatDateTime(notification.timestamp)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (notification.data.isNotEmpty) ...[
                  const Divider(),
                  const Text('Additional Information:'),
                  const SizedBox(height: 8),
                  ...notification.data.entries.map(
                    (e) => Text(
                      '${e.key}: ${e.value}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
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
          IconButton(
            icon: Icon(_isDebugMode ? Icons.bug_report : Icons.info_outline),
            onPressed: _toggleDebugMode,
            tooltip: _isDebugMode ? 'Hide debug info' : 'Show debug info',
          ),
        ],
      ),
      body: Column(
        children: [
          // Debug section
          if (_isDebugMode) ...[
            Container(
              color: Colors.black87,
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'DEBUG MODE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: _inspectApiResponse,
                        child: const Text('Inspect API'),
                      ),
                      ElevatedButton(
                        onPressed: _refresh,
                        child: const Text('Refresh Data'),
                      ),
                    ],
                  ),
                  if (_debugInfo.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(8),
                      color: Colors.grey[800],
                      height: 100,
                      child: SingleChildScrollView(
                        child: Text(
                          _debugInfo,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],

          // Notifications list
          Expanded(
            child: FutureBuilder<List<NotificationItem>>(
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
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
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
                        if (_isDebugMode)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text(
                              'Debug info: ${snapshot.error}',
                              style: const TextStyle(fontSize: 12),
                            ),
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
                        onDismissed:
                            (direction) => _deleteNotification(notification),
                        child: Card(
                          elevation: 2,
                          color:
                              !notification.read
                                  ? Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer
                                  : null,
                          shape:
                              notification.isOrderRelated
                                  ? RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: _typeColor(notification.type),
                                      width: 1.5,
                                    ),
                                  )
                                  : null,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
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
                                      ? const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      )
                                      : null,
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (notification.senderName?.isNotEmpty ??
                                    false)
                                  Text(
                                    'From: ${notification.senderName}',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                Text(
                                  'Date: ${notification.timestamp.day}/${notification.timestamp.month}/${notification.timestamp.year} '
                                  '${notification.timestamp.hour.toString().padLeft(2, '0')}:'
                                  '${notification.timestamp.minute.toString().padLeft(2, '0')}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                // Show order status if available
                                if (notification.orderStatus != null)
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(
                                        notification.orderStatus!,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      notification.orderStatus!.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!notification.read)
                                  const Icon(Icons.mark_email_unread, size: 16),
                                if (notification.isOrderRelated)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                    ),
                                    onPressed:
                                        () => _navigateToOrderDetails(
                                          notification,
                                        ),
                                    tooltip: 'View order details',
                                  ),
                              ],
                            ),
                            onTap: () {
                              _markAsRead(notification);
                              if (notification.isOrderRelated) {
                                _navigateToOrderDetails(notification);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'delivered':
        return Colors.green;
      case 'livring':
      case 'delivering':
        return Colors.orange;
      case 'pending':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
