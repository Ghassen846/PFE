import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DirectMapLauncher {
  /// Launches navigation directly to Mahdia location
  static Future<bool> openMahdiaInMaps(BuildContext context) async {
    try {
      // Coordinates for Mahdia, Tunisia
      const double mahdiaLat = 35.5270204;
      const double mahdiaLng = 11.0332198;

      // Use specific search query to force the map to open properly
      final Uri mapUrl = Uri.parse(
        'https://www.google.com/maps/search/Mahdia+Tunisia/@$mahdiaLat,$mahdiaLng,14z',
      );

      debugPrint('Opening Mahdia location at: $mapUrl');
      final bool launched = await launchUrl(
        mapUrl,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        // Try alternate URL
        final Uri altUrl = Uri.parse(
          'https://maps.google.com/?q=$mahdiaLat,$mahdiaLng',
        );
        return await launchUrl(altUrl, mode: LaunchMode.externalApplication);
      }

      return launched;
    } catch (e) {
      debugPrint('Error opening maps: $e');
      return false;
    }
  }

  /// Opens navigation from current location to Mahdia
  static Future<bool> navigateToMahdia(BuildContext context) async {
    try {
      // Coordinates for Mahdia, Tunisia
      const double mahdiaLat = 35.5270204;
      const double mahdiaLng = 11.0332198;

      // Destination query with place name to help maps app recognize it
      final Uri navUrl = Uri.parse(
        'https://www.google.com/maps/dir/?api=1'
        '&destination=$mahdiaLat,$mahdiaLng'
        '&destination_place_id=ChIJVVVVVVVVWhMR9MyLe5Eo_zs' // Google Maps place ID for Mahdia
        '&travelmode=driving',
      );

      debugPrint('Navigating to Mahdia using: $navUrl');

      final bool launched = await launchUrl(
        navUrl,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open navigation. Please install Google Maps.',
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }

      return launched;
    } catch (e) {
      debugPrint('Error opening navigation: $e');
      return false;
    }
  }

  /// Opens navigation from current location to specific coordinates
  /// with fallback to Mahdia if coordinates are invalid
  static Future<bool> navigateToCoordinates(
    BuildContext context,
    double? destinationLat,
    double? destinationLng, {
    String? destinationName,
  }) async {
    try {
      // Validate coordinates, use Mahdia as fallback
      double lat = destinationLat ?? 35.5270204;
      double lng = destinationLng ?? 11.0332198;

      if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
        debugPrint(
          '⚠️ Invalid coordinates provided: $lat, $lng - using Mahdia instead',
        );
        lat = 35.5270204;
        lng = 11.0332198;
      }

      // Default to "Destination" if no name provided
      final String locationName = destinationName ?? 'Destination';

      // Destination URL with coordinates
      final Uri navUrl = Uri.parse(
        'https://www.google.com/maps/dir/?api=1'
        '&destination=$lat,$lng'
        '&destination_place_id=ChIJVVVVVVVVWhMR9MyLe5Eo_zs' // Generic place ID
        '&travelmode=driving',
      );

      debugPrint('Navigating to $locationName at ($lat, $lng) using: $navUrl');

      final bool launched = await launchUrl(
        navUrl,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open navigation. Please install Google Maps.',
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }

      return launched;
    } catch (e) {
      debugPrint('Error opening navigation: $e');
      return false;
    }
  }
}
