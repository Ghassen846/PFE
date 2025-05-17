import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;

// Utility class for responsive design
class Util {
  static bool isPhone(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.width < 600; // Standard breakpoint for mobile
  }

  static bool isTablet(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.width >= 600 && size.width < 1200; // Standard tablet breakpoint
  }

  static bool isDesktop(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.width >= 1200; // Standard desktop breakpoint
  }

  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  // Get device pixel ratio
  static double getDevicePixelRatio() {
    return window.devicePixelRatio;
  }
  
  // Get screen orientation
  static Orientation getOrientation(BuildContext context) {
    return MediaQuery.of(context).orientation;
  }
  
  // Is the app running on the web?
  static bool get isWebPlatform => kIsWeb;
}
