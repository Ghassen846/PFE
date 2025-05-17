import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
      listener: (context, state) {},
      builder: (context, state) {
        final blocRef = HomeBloc.get(context);
        final isDark = state.isDark;
        return Container(
          margin: EdgeInsets.all(2.h),
          width: 100.w,
          height: 30.h,
          decoration: BoxDecoration(
            backgroundBlendMode: BlendMode.srcOver,
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
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 1.h,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              order.status == "on-the-way"
                                  ? Colors.blue
                                  : Colors.green,
                        ),
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Flexible(
                      child: Text(
                        order.status,
                        style: TextStyle(
                          color:
                              order.status.contains("on")
                                  ? Colors.blue
                                  : Colors.green,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => OrderMapScreen(
                                  initialPosition: LatLng(
                                    shared.getLatFromSharedPrefs(),
                                    shared.getLngFromSharedPrefs(),
                                  ),
                                  orderId: order.id ?? '',
                                  customerName: order.customerName,
                                  deliveryMan: state.username,
                                  onTheWay: order.status == "on-the-way",
                                  adress:
                                      order.status.contains("on")
                                          ? order.deliveryAddress
                                          : order.pickupLocation,
                                ),
                          ),
                        );
                      },
                      icon: Icon(
                        Icons.gps_fixed_sharp,
                        color:
                            isDark
                                ? ThemeHelper.darkIconColor()
                                : ThemeHelper.lightIconColor(),
                        size: 20.sp,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Text(
                      'Order #${order.orderRef}',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                        color:
                            isDark
                                ? ThemeHelper.whiteColor
                                : ThemeHelper.blackColor,
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      order.deliveryDate,
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                _buildInfoRow('Customer', order.customerName, isDark),
                _buildInfoRow('Phone', order.customerPhone, isDark),
                _buildInfoRow('Delivery To', order.deliveryAddress, isDark),
                _buildInfoRow('Pickup From', order.pickupLocation, isDark),

                Spacer(),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        if (order.status == "pending") {
                          blocRef.add(
                            HomeChangeOrderStatusEvent(
                              order: order,
                              status: "up-coming",
                            ),
                          );
                        } else if (order.status == "up-coming") {
                          blocRef.add(
                            HomeChangeOrderStatusEvent(
                              order: order,
                              status: "on-the-way",
                            ),
                          );
                        } else {
                          _showValidationCodeDialog(context, blocRef, order);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: Text(
                        order.status.contains('on')
                            ? 'Confirm'
                            : order.status == "pending"
                            ? "Accept"
                            : 'Deliver',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        blocRef.add(
                          HomeChangeOrderStatusEvent(
                            order: order,
                            status: "pending",
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white),
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

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.8.h),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12.sp,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12.sp,
                color: isDark ? Colors.white : Colors.black,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    switch (status.toLowerCase()) {
      case 'pending':
        chipColor = Colors.orange;
        break;
      case 'delivered':
        chipColor = Colors.green;
        break;
      case 'on-the-way':
      case 'up-coming':
        chipColor = Colors.blue;
        break;
      case 'cancelled':
        chipColor = Colors.red;
        break;
      default:
        chipColor = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: chipColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Validation Code'),
          content: TextField(
            controller: validationController,
            decoration: const InputDecoration(hintText: "Validation Code"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Submit'),
              onPressed: () {
                if (validationController.text == order.validationCode) {
                  blocRef.add(
                    HomeChangeOrderStatusEvent(
                      order: order,
                      status: "delivered",
                      validationCode: validationController.text,
                    ),
                  );
                  Navigator.of(context).pop();
                  _showSuccessDialog(context);
                } else {
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
