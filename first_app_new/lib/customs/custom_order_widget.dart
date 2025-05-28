import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../helpers/bloc/home_bloc.dart';
import '../helpers/responsive/sizer_ext.dart';
import '../helpers/shared.dart' as shared;
import '../helpers/theme/theme.dart';
import '../models/order_model/order_model.dart';
import '../screens/order_map_screen.dart';

class CustomOrderWidget extends StatelessWidget {
  final Order order;

  const CustomOrderWidget({super.key, required this.order});
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeBloc, HomeState>(
      listener: (context, state) {
        final orderInState = state.orderList.firstWhere(
          (o) => o.order == order.order,
          orElse: () => order,
        );

        if (orderInState.status != order.status) {
          debugPrint(
            'Order status changed: ${order.order} from ${order.status} to ${orderInState.status}',
          );
        }
      },
      builder: (context, state) {
        final currentOrder = state.orderList.firstWhere(
          (o) => o.order == order.order,
          orElse: () => order,
        );

        final blocRef = HomeBloc.get(context);
        final isDark = state.isDark;

        return Container(
          margin: EdgeInsets.all(2.h),
          width: 100.w,
          decoration: BoxDecoration(
            color:
                isDark
                    ? const Color.fromRGBO(28, 25, 23, 1)
                    : const Color.fromRGBO(242, 242, 242, 1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              width: 1,
              color:
                  isDark
                      ? const Color.fromRGBO(39, 39, 42, 1)
                      : const Color.fromRGBO(228, 228, 231, 1),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status and Map Button Row
                Row(
                  children: [
                    // Status indicator
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                          currentOrder.status,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStatusIcon(currentOrder.status),
                            color: _getStatusColor(currentOrder.status),
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            _formatStatus(currentOrder.status),
                            style: TextStyle(
                              color: _getStatusColor(currentOrder.status),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Map button
                    IconButton(
                      onPressed:
                          () => _openMap(context, currentOrder, state.username),
                      icon: Icon(
                        Icons.map,
                        color:
                            isDark
                                ? ThemeHelper.darkIconColor()
                                : ThemeHelper.lightIconColor(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Order Info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${currentOrder.orderRef}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentOrder.deliveryDate,
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Ref: ${currentOrder.reference}',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Location & Customer Info
                _buildInfoRow(
                  icon: Icons.store,
                  label: 'Restaurant',
                  value: currentOrder.pickupLocation,
                  isDark: isDark,
                ),
                _buildInfoRow(
                  icon: Icons.person,
                  label: 'Customer',
                  value: currentOrder.customerName,
                  isDark: isDark,
                ),
                _buildInfoRow(
                  icon: Icons.phone,
                  label: 'Phone',
                  value: currentOrder.customerPhone,
                  isDark: isDark,
                ),
                _buildInfoRow(
                  icon: Icons.location_on,
                  label: 'Delivery To',
                  value: currentOrder.deliveryAddress,
                  isDark: isDark,
                ),

                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        onPressed:
                            () => _handlePrimaryAction(
                              context,
                              blocRef,
                              currentOrder,
                            ),
                        backgroundColor: Colors.green,
                        text: _getPrimaryActionText(currentOrder.status),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildActionButton(
                        onPressed:
                            () => _handleCancelAction(blocRef, currentOrder),
                        backgroundColor: Colors.red,
                        text: 'Cancel',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: isDark ? Colors.grey : Colors.grey[700]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              color: isDark ? Colors.grey : Colors.grey[700],
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required Color backgroundColor,
    required String text,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(text),
    );
  }

  String _getPrimaryActionText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Accept';
      case 'pending_livreur_acceptance':
        return 'Accept';
      case 'livring':
        return 'Confirm Delivery';
      case 'completed':
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Process';
    }
  }

  void _handlePrimaryAction(
    BuildContext context,
    HomeBloc blocRef,
    Order order,
  ) {
    debugPrint(
      'Handling primary action for order: ${order.order} with status: ${order.status}',
    );
    switch (order.status.toLowerCase()) {
      case 'pending':
      case 'pending_livreur_acceptance':
        debugPrint('Changing status from ${order.status} to livring');
        blocRef.add(
          HomeChangeOrderStatusEvent(order: order, status: "livring"),
        );
        break;
      case 'livring':
        debugPrint('Opening validation dialog for delivery confirmation');
        _showValidationCodeDialog(context, blocRef, order);
        break;
      default:
        debugPrint('Status ${order.status} not handled in primary action');
        // Show a message for unhandled status
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot process order with status: ${order.status}'),
          ),
        );
        break;
    }
  }

  void _handleCancelAction(HomeBloc blocRef, Order order) {
    if (order.status.toLowerCase() != 'completed' &&
        order.status.toLowerCase() != 'cancelled') {
      blocRef.add(
        HomeChangeOrderStatusEvent(order: order, status: "cancelled"),
      );
    }
  }

  Future<void> _openMap(
    BuildContext context,
    Order order,
    String username,
  ) async {
    // Fetch stored coordinates before navigation
    final lat = await shared.getLatFromSharedPrefs();
    final lng = await shared.getLngFromSharedPrefs();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => OrderMapScreen(
              initialPosition: shared.LatLng(lat, lng),
              orderId: order.id ?? '',
              customerName: order.customerName,
              deliveryMan: username,
              onTheWay: order.status == 'livring',
              adress:
                  order.status == 'livring'
                      ? order.deliveryAddress
                      : order.pickupLocation,
            ),
      ),
    );
  }

  void _showValidationCodeDialog(
    BuildContext context,
    HomeBloc blocRef,
    Order order,
  ) {
    TextEditingController validationController = TextEditingController();

    // Debug output to verify validation code
    debugPrint('Expected validation code: ${order.validationCode}');
    debugPrint('Order details: id=${order.order}, ref=${order.orderRef}');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Validation Code'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: validationController,
                decoration: const InputDecoration(
                  hintText: "Validation Code",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                autofocus: true,
              ),
              const SizedBox(height: 8),
              Text(
                'Order #${order.orderRef}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Submit'),
              onPressed: () {
                final enteredCode = validationController.text.trim();
                final expectedCode = order.validationCode;

                debugPrint('Validation code entered: $enteredCode');
                debugPrint('Expected validation code: $expectedCode');

                if (enteredCode.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a validation code'),
                    ),
                  );
                  return;
                }

                if (enteredCode == expectedCode) {
                  debugPrint('Validation successful, delivering order');
                  blocRef.add(
                    HomeChangeOrderStatusEvent(
                      order: order,
                      status:
                          "completed", // Using 'completed' to match backend Order model's enum
                      validationCode: enteredCode,
                    ),
                  );
                  Navigator.of(context).pop();
                  _showSuccessDialog(context);
                } else {
                  debugPrint(
                    'Validation failed: $enteredCode != $expectedCode',
                  );
                  Navigator.of(context).pop();
                  _showFailureDialog(context);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success'),
          content: const Text('Order delivered successfully.'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showFailureDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: const Text('Please enter a correct validation code.'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
