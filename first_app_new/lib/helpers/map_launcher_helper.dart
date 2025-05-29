import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;

class MapLauncherHelper {
  static Future<bool> launchDirections({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    required BuildContext context,
  }) async {
    try {
      // Validate coordinates before proceeding
      if (!_isValidCoordinate(startLat, startLng) ||
          !_isValidCoordinate(endLat, endLng)) {
        debugPrint(
          '⚠️ Invalid coordinates detected, using Mahdia coordinates as fallback',
        );

        // If start coordinates are invalid, use Mahdia
        if (!_isValidCoordinate(startLat, startLng)) {
          startLat = 35.5270204;
          startLng = 11.0332198;
        }

        // If end coordinates are invalid, use slightly offset Mahdia coordinates
        if (!_isValidCoordinate(endLat, endLng)) {
          endLat = 35.5350204; // Slightly different from start
          endLng = 11.0392198; // to avoid same-point navigation
        }
      }

      // Format coordinates with precision of 6 decimal places
      final String startCoord =
          '${startLat.toStringAsFixed(6)},${startLng.toStringAsFixed(6)}';
      final String endCoord =
          '${endLat.toStringAsFixed(6)},${endLng.toStringAsFixed(6)}';

      debugPrint('Launching directions from $startCoord to $endCoord');

      // For Android, try different URL formats
      if (Platform.isAndroid) {
        // Try Google Maps app directly with package name
        final Uri intentUri = Uri.parse(
          'google.navigation:q=$endLat,$endLng&mode=d',
        );
        debugPrint('Trying direct intent: $intentUri');

        if (await canLaunchUrl(intentUri)) {
          return await launchUrl(intentUri);
        }

        // Try waze as fallback
        final Uri wazeUri = Uri.parse(
          'waze://?ll=$endLat,$endLng&navigate=yes',
        );
        debugPrint('Trying Waze intent: $wazeUri');

        if (await canLaunchUrl(wazeUri)) {
          return await launchUrl(wazeUri);
        }

        // Last resort - open browser with Google Maps
        final Uri mapUrl = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$endLat,$endLng',
        );
        debugPrint('Trying web URL: $mapUrl');

        return await launchUrl(mapUrl, mode: LaunchMode.externalApplication);
      }
      // For iOS and other platforms
      else {
        final Uri mapUrl = Uri.parse(
          'https://maps.apple.com/?daddr=$endLat,$endLng&dirflg=d',
        );

        if (await canLaunchUrl(mapUrl)) {
          return await launchUrl(mapUrl);
        }

        // Fallback to Google Maps web URL
        final Uri webUrl = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$endLat,$endLng',
        );

        return await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Map launch error: $e');
      return false;
    }
  }

  // Helper method to validate coordinates
  static bool _isValidCoordinate(double? lat, double? lng) {
    if (lat == null || lng == null) return false;

    // Check latitude is between -90 and 90
    if (lat < -90 || lat > 90) return false;

    // Check longitude is between -180 and 180
    if (lng < -180 || lng > 180) return false;

    // Check if coordinates are the default Tunisia coordinates
    if (lat == 36.8065 && lng == 10.1815) return false;

    return true;
  }
}
