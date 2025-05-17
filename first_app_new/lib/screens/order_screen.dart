import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../helpers/bloc/home_bloc.dart';
import '../customs/custom_order_widget.dart';
import '../customs/order_status_card.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  _OrderScreenState createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  @override
  void initState() {
    super.initState();
    // Request order list data when screen initializes
    context.read<HomeBloc>().add(HomeInitialEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeBloc, HomeState>(
      listener: (context, state) {
        // Handle any state changes if needed
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Orders'),
            actions: [
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
                  : state.orderList.isEmpty
                  ? const Center(
                    child: Text(
                      'No orders available',
                      style: TextStyle(fontSize: 18),
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
                                    '${_countOrdersByStatus(state.orderList, 'delivered')}',
                                color: Colors.green,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Order list
                      Expanded(
                        child: ListView.builder(
                          itemCount: state.orderList.length,
                          itemBuilder: (context, index) {
                            return CustomOrderWidget(
                              order: state.orderList[index],
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

  // Helper method to count orders by status
  int _countOrdersByStatus(List<dynamic> orderList, String status) {
    return orderList.where((order) => order.status == status).length;
  }
}
