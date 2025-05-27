import 'package:first_app_new/helpers/bloc/home_bloc.dart';
import 'package:first_app_new/models/order_model/order_model.dart';
import 'package:flutter/material.dart';

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
              decoration: const InputDecoration(hintText: "Validation Code"),
              keyboardType: TextInputType.number,
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
            child: const Text('Submit'),
            onPressed: () {
              final enteredCode = validationController.text;
              final expectedCode = order.validationCode;

              debugPrint('Validation code entered: $enteredCode');
              debugPrint('Expected validation code: $expectedCode');
              if (enteredCode == expectedCode) {
                debugPrint('Validation successful, completing order');
                blocRef.add(
                  HomeChangeOrderStatusEvent(
                    order: order,
                    status:
                        "completed", // Changed from "delivered" to "completed"
                    validationCode: enteredCode,
                  ),
                );
                Navigator.of(context).pop();
                _showSuccessDialog(context);
              } else {
                debugPrint('Validation failed: $enteredCode != $expectedCode');
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
