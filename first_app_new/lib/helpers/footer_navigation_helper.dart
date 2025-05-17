// Helper for navigating to details screens while keeping the footer
import 'package:flutter/material.dart';

class FooterNavigationHelper {
  // Navigate to delivery details screen with bottom navigation bar preserved
  static void navigateToDeliveryDetails(
    BuildContext context, {
    required String category,
    required String title,
  }) {
    // Use named routes with arguments to leverage the route defined in main.dart
    Navigator.of(context).pushNamed(
      '/delivery-details',
      arguments: {'category': category, 'title': title},
    );
  }

  // Helper method to determine if we should use replacement navigation
  static void navigateWithFooter(
    BuildContext context,
    String routeName, {
    bool replaceRoute = false,
    Object? arguments,
  }) {
    if (replaceRoute) {
      Navigator.of(
        context,
      ).pushReplacementNamed(routeName, arguments: arguments);
    } else {
      Navigator.of(context).pushNamed(routeName, arguments: arguments);
    }
  }
}
