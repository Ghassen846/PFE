import 'package:first_app_new/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

// Import centralized services

class DeliveryDetailsScreen extends StatefulWidget {
  final String category;
  final String title;

  const DeliveryDetailsScreen({
    super.key,
    required this.category,
    required this.title,
  });

  @override
  State<DeliveryDetailsScreen> createState() => _DeliveryDetailsScreenState();
}

class _DeliveryDetailsScreenState extends State<DeliveryDetailsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _items = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    setState(() => _isLoading = true);

    try {
      // Get userId using ApiService's getUserId method which checks both SharedPreferences and secure storage
      final userId = await ApiService.getUserId();
      if (userId == null || userId.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'User ID not found, please log in again';
        });
        Fluttertoast.showToast(
          msg: "User ID not found. Please log in again.",
          backgroundColor: Colors.red,
          toastLength: Toast.LENGTH_LONG,
        );
        return;
      }

      // Determine which API endpoint to call based on category
      String endpoint;
      Map<String, String> queryParams = {'userId': userId};

      switch (widget.category) {
        case 'completed':
          endpoint = 'delivery/list';
          queryParams['status'] = 'delivered';
          break;
        case 'pending':
          endpoint = 'delivery/list';
          queryParams['status'] = 'pending,picked_up,delivering';
          break;
        case 'collected':
          endpoint = 'delivery/payments';
          break;
        case 'earnings':
          endpoint = 'delivery/earnings';
          break;
        default:
          endpoint = 'delivery/list';
          break;
      }

      final response = await ApiService.get(endpoint, queryParams: queryParams);

      if (response.containsKey('error')) {
        setState(() {
          _isLoading = false;
          _errorMessage = response['error'] ?? 'Failed to load data';
        });
        return;
      }

      setState(() {
        _isLoading = false;
        _items = _safelyBuildOrderItems(response);
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: $e';
      });

      Fluttertoast.showToast(
        msg: "Error loading details: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  // Safely convert API response to list of items
  List<Map<String, dynamic>> _safelyBuildOrderItems(dynamic response) {
    List<Map<String, dynamic>> result = [];

    if (response is List) {
      // If response is a list, process each item
      for (var item in response) {
        if (item is Map<String, dynamic>) {
          result.add(item);
        }
      }
    } else if (response is Map<String, dynamic>) {
      // If response is a map with items key
      if (response.containsKey('items') && response['items'] is List) {
        for (var item in response['items']) {
          if (item is Map<String, dynamic>) {
            result.add(item);
          }
        }
      } else if (response.containsKey('data') && response['data'] is List) {
        // Some APIs return data in a 'data' field
        for (var item in response['data']) {
          if (item is Map<String, dynamic>) {
            result.add(item);
          }
        }
      } else {
        // Fallback: treat the whole response as one item
        result.add(response);
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.orange,
        // Add back button that preserves the bottom navigation
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchDetails,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No ${widget.category} items found',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Build UI based on category
    switch (widget.category) {
      case 'completed':
      case 'pending':
        return _buildDeliveryList();
      case 'collected':
        return _buildPaymentsList();
      case 'earnings':
        return _buildEarningsList();
      default:
        return _buildDeliveryList();
    }
  }

  Widget _buildDeliveryList() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        final orderNumber = item['orderNumber'] ?? 'Unknown';
        final status = item['status'] ?? 'Unknown';
        final date =
            item['createdAt'] != null
                ? DateTime.parse(
                  item['createdAt'],
                ).toLocal().toString().split('.')[0]
                : 'Unknown date';

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getStatusColor(status),
              child: Icon(_getStatusIcon(status), color: Colors.white),
            ),
            title: Text('Order #$orderNumber'),
            subtitle: Text('Status: ${_formatStatus(status)}\nDate: $date'),
            isThreeLine: true,
            onTap: () {
              // Navigate to order details when tapped
              // This would be implemented in a future version
            },
          ),
        );
      },
    );
  }

  Widget _buildPaymentsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        final amount = item['amount'] ?? 0.0;
        final date =
            item['date'] != null
                ? DateTime.parse(
                  item['date'],
                ).toLocal().toString().split('.')[0]
                : 'Unknown date';
        final orderRef = item['orderReference'] ?? 'N/A';

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.green,
              child: Icon(Icons.attach_money, color: Colors.white),
            ),
            title: Text('\$${amount.toStringAsFixed(2)} collected'),
            subtitle: Text('Ref: $orderRef\nDate: $date'),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Widget _buildEarningsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        final amount = item['amount'] ?? 0.0;
        final date =
            item['paymentDate'] != null
                ? DateTime.parse(
                  item['paymentDate'],
                ).toLocal().toString().split('.')[0]
                : 'Unknown date';
        final type = item['type'] ?? 'Delivery fee';

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.purple,
              child: Icon(Icons.account_balance_wallet, color: Colors.white),
            ),
            title: Text('\$${amount.toStringAsFixed(2)} earned'),
            subtitle: Text('Type: $type\nDate: $date'),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green;
      case 'picked_up':
        return Colors.blue;
      case 'delivering':
        return Colors.amber;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Icons.check_circle;
      case 'picked_up':
        return Icons.directions_car;
      case 'delivering':
        return Icons.local_shipping;
      case 'pending':
        return Icons.pending_actions;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  String _formatStatus(String status) {
    if (status.isEmpty) return 'Unknown';

    // Convert snake_case to Title Case
    return status
        .split('_')
        .map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }
}
