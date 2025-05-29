import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../helpers/bloc/home_bloc.dart';
import '../models/order_model/order_model.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String? orderId;
  final String? orderRef;

  const OrderDetailsScreen({Key? key, this.orderId, this.orderRef})
    : super(key: key);

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  bool isLoading = true;
  Order? order;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    if (widget.orderId == null && widget.orderRef == null) {
      setState(() {
        error = "No order ID or reference provided";
        isLoading = false;
      });
      return;
    }

    try {
      // In a real app, you'd fetch the order from your API or Bloc
      // For now, we'll just look it up in the existing orders list
      final homeState = context.read<HomeBloc>().state;

      Order? foundOrder;
      if (widget.orderId != null) {
        foundOrder = homeState.orderList.firstWhere(
          (o) => o.order == widget.orderId,
          orElse: () => null as Order,
        );
      } else if (widget.orderRef != null) {
        foundOrder = homeState.orderList.firstWhere(
          (o) => o.orderRef == widget.orderRef,
          orElse: () => null as Order,
        );
      }

      setState(() {
        order = foundOrder;
        isLoading = false;
        if (order == null) {
          error = "Order not found";
        }
      });
    } catch (e) {
      setState(() {
        error = "Error loading order details: $e";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Order ${widget.orderRef ?? "Details"}')),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : error != null
              ? Center(
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
                      error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              )
              : order != null
              ? SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOrderHeader(),
                    const SizedBox(height: 24),
                    _buildOrderDetails(),
                    const SizedBox(height: 24),
                    _buildCustomerInfo(),
                  ],
                ),
              )
              : const Center(child: Text('Order not found')),
    );
  }

  Widget _buildOrderHeader() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _getStatusColor(order!.status), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: _getStatusColor(order!.status).withOpacity(0.1),
              radius: 30,
              child: Icon(
                _getStatusIcon(order!.status),
                color: _getStatusColor(order!.status),
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #${order!.orderRef}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order!.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _formatStatus(order!.status),
                      style: TextStyle(
                        color: _getStatusColor(order!.status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Delivery Date: ${order!.deliveryDate}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetails() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildInfoRow(
              'Restaurant',
              order!.restaurantName ?? order!.pickupLocation,
            ),
            _buildInfoRow('Pickup Location', order!.pickupLocation),
            _buildInfoRow('Delivery Address', order!.deliveryAddress),
            _buildInfoRow('Reference', order!.reference),
            if (order!.validationCode?.isNotEmpty == true)
              _buildInfoRow('Validation Code', order!.validationCode!),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customer Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildInfoRow('Name', order!.customerName),
            _buildInfoRow('Phone', order!.customerPhone),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
      case 'completed':
        return Colors.green;
      case 'livring':
      case 'delivering':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'pending':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
      case 'completed':
        return Icons.check_circle;
      case 'livring':
      case 'delivering':
        return Icons.directions_bike;
      case 'cancelled':
        return Icons.cancel;
      case 'pending':
        return Icons.schedule;
      default:
        return Icons.help_outline;
    }
  }

  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'livring':
        return 'Delivering';
      default:
        return status.substring(0, 1).toUpperCase() +
            status.substring(1).toLowerCase();
    }
  }
}
