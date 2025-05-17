import 'package:flutter/material.dart';
import 'package:first_app_new/helpers/responsive/sizer_ext.dart';

class CustomAppBarName extends StatelessWidget {
  const CustomAppBarName({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 7.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            "Hocus Pocus,\n It's Dinner Time",
            style: TextStyle(
              fontSize: 23.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Image.asset(
            'assets/images/img_3d_food_icon_by_108x108.png',
            height: 15.h,
            width: 25.w,
          ),
        ],
      ),
    );
  }
}
