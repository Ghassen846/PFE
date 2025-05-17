import 'package:flutter/material.dart';
// Remove the web socket channel import since it's causing issues
// We'll mock what we need for now

class ThemeHelper {
  // Removed WebSocketChannel reference
  static BoxDecoration darkBackGround() =>
      BoxDecoration(color: ThemeHelper.blackColor);
  static BoxDecoration lightBackGround() => BoxDecoration(
    gradient: LinearGradient(
      begin: const Alignment(1.27, 1.54),
      end: const Alignment(0, 0),
      colors: [
        Colors.green.shade100, // Lighter shade of green
        Colors.grey.shade200, // Much lighter gray
      ],
    ),
  );

  static Color darkTextColor() => const Color.fromRGBO(58, 58, 58, 1);
  static Color lightTextColor() => const Color.fromRGBO(255, 255, 255, 1);
  static Color darkIconColor() => const Color.fromRGBO(255, 255, 255, 1);
  static Color lightIconColor() => const Color.fromRGBO(255, 255, 255, 1);
  static Color blackColor = const Color.fromRGBO(58, 58, 58, 1);
  static Color whiteColor = const Color.fromRGBO(255, 255, 255, 1);
  static Color greenColor = const Color.fromRGBO(81, 188, 79, 1);
  static Color greyColor = const Color.fromRGBO(35, 35, 37, 1);
  static Color orangeColor = const Color.fromRGBO(253, 190, 27, 1);
  static List<Color> lightGradient() => [
    const Color.fromARGB(255, 61, 61, 61).withOpacity(0.1),
    const Color.fromARGB(255, 124, 124, 124).withOpacity(0.05),
  ];
  static List<Color> darkGradient() => [
    const Color(0xFFffffff).withOpacity(0.1),
    const Color((0xFFFFFFFF)).withOpacity(0.1),
  ];
  static Color darkColor() => Colors.black;
  static Color lightColor() => Colors.white;
}
