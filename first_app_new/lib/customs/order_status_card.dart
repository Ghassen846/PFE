import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../helpers/responsive/sizer_ext.dart';

class OrderStatusCard extends StatelessWidget {
  final String status;
  final String time;
  final Color color;

  const OrderStatusCard({
    super.key,
    required this.status,
    required this.time,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassmorphicContainer(
      width: 70.w,
      height: 8.h, // Define a fixed height for the button container
      borderRadius: 20,
      blur: 10,
      alignment: Alignment.bottomCenter,
      border: 0,
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFffffff).withOpacity(0.1),
          const Color(0xFFFFFFFF).withOpacity(0.05),
        ],
        stops: const [0.1, 1],
      ),
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFffffff).withOpacity(0.5),
          const Color((0xFFFFFFFF)).withOpacity(0.5),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          // Adjust the color to match the design
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: <Widget>[
            SizedBox(width: 2.w),
            Container(
              width: 4.w,
              height: 5.h,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            SizedBox(width: 5.w),
            Expanded(
              flex: 2,
              child: Text(status, style: const TextStyle(color: Colors.white)),
            ),
            Expanded(
              flex: 1,
              child: Text(time, style: TextStyle(color: Colors.grey[400])),
            ),
          ],
        ),
      ),
    );
  }
}
