import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../helpers/bloc/home_bloc.dart';
import '../customs/custom_order_widget.dart';
import '../customs/order_status_card.dart';
import '../widgets/network_status_widget.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  _OrderScreenState createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  bool _showCompletedOrders = false;

  @override
  void initState() {
    super.initState();
    // Request order list data when screen initializes
    context.read<HomeBloc>().add(HomeInitialEvent());
  }

  // Filter orders based on their status
  List<dynamic> _filterOrders(List<dynamic> orders) {
    if (_showCompletedOrders) {
      return orders; // Show all orders
    } else {
      // Filter out completed and canceled orders
      return orders
          .where(
            (order) =>
                order.status.toLowerCase() != 'completed' &&
                order.status.toLowerCase() != 'canceled',
          )
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeBloc, HomeState>(
      listener: (context, state) {
        // Handle any state changes if needed
      },
      builder: (context, state) {
        // Filter orders
        final filteredOrders = _filterOrders(state.orderList);

        return Scaffold(
          appBar: ConnectionStatusAppBar(
            title: 'Orders',
            actions: [
              // Toggle to show/hide completed orders
              IconButton(
                icon: Icon(
                  _showCompletedOrders
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                tooltip:
                    _showCompletedOrders
                        ? 'Hide completed orders'
                        : 'Show completed orders',
                onPressed: () {
                  setState(() {
                    _showCompletedOrders = !_showCompletedOrders;
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  // Refresh order list
                  context.read<HomeBloc>().add(HomeInitialEvent());
                },
              ),
            ],
          ),
          body:
              state.status == StateStatus.loading
                  ? const Center(child: CircularProgressIndicator())
                  : state.status == StateStatus.error
                  ? ConnectionErrorWidget(
                    onRetry: () {
                      context.read<HomeBloc>().add(HomeInitialEvent());
                    },
                  )
                  : filteredOrders.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'No active orders',
                          style: TextStyle(fontSize: 18),
                        ),
                        if (!_showCompletedOrders && state.orderList.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _showCompletedOrders = true;
                              });
                            },
                            child: const Text('Show completed orders'),
                          ),
                      ],
                    ),
                  )
                  : Column(
                    children: [
                      // Order status cards
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              OrderStatusCard(
                                status: 'Pending',
                                time:
                                    '${_countOrdersByStatus(state.orderList, 'pending')}',
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 10),
                              OrderStatusCard(
                                status: 'On the way',
                                time:
                                    '${_countOrdersByStatus(state.orderList, 'on-the-way')}',
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 10),
                              OrderStatusCard(
                                status: 'Delivered',
                                time:
                                    '${_countOrdersByStatus(state.orderList, 'completed')}',
                                color: Colors.green,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Filter indicator
                      if (!_showCompletedOrders)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 4.0,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.filter_list,
                                size: 16,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Showing active orders only',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Order list
                      Expanded(
                        child: ListView.builder(
                          itemCount: filteredOrders.length,
                          itemBuilder: (context, index) {
                            return CustomOrderWidget(
                              order: filteredOrders[index],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
        );
      },
    );
  }

  int _countOrdersByStatus(List<dynamic> orders, String status) {
    return orders
        .where((order) => order.status.toLowerCase() == status.toLowerCase())
        .length;
  }
}
