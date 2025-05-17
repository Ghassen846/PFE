import 'package:flutter/material.dart';
import '../main.dart';

class NavigationHelper {
  // Navigate to home screen with footer
  static void navigateToHome(
    BuildContext context, {
    bool replaceRoute = false,
  }) {
    if (replaceRoute) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushNamed(context, '/home');
    }
  }

  // Navigate to orders screen with footer
  static void navigateToOrders(
    BuildContext context, {
    bool replaceRoute = false,
  }) {
    if (replaceRoute) {
      Navigator.pushReplacementNamed(context, '/order');
    } else {
      Navigator.pushNamed(context, '/order');
    }
  }

  // Navigate to notifications screen with footer
  static void navigateToNotifications(
    BuildContext context, {
    bool replaceRoute = false,
  }) {
    if (replaceRoute) {
      Navigator.pushReplacementNamed(context, '/notification');
    } else {
      Navigator.pushNamed(context, '/notification');
    }
  }

  // Navigate to history screen with footer
  static void navigateToHistory(
    BuildContext context, {
    bool replaceRoute = false,
  }) {
    if (replaceRoute) {
      Navigator.pushReplacementNamed(context, '/history');
    } else {
      Navigator.pushNamed(context, '/history');
    }
  }

  // Navigate to any screen using the global navigator key
  static void navigateToRoute(String routeName, {Object? arguments}) {
    navigatorKey.currentState?.pushNamed(routeName, arguments: arguments);
  }

  // Navigate to test screen
  static void navigateToTestScreen(BuildContext context) {
    Navigator.pushNamed(context, '/testing');
  }
}
