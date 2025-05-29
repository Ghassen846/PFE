import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;

class MapLauncherUtils {
  /// Opens Google Maps app with navigation directions
  static Future<void> launchGoogleMapsWithDirections({
    required double userLat,
    required double userLng,
    required double destinationLat,
    required double destinationLng,
    String? destinationName,
  }) async {
    String url;

    if (Platform.isAndroid) {
      // For Android, use Google Maps intent
      final encodedName = Uri.encodeComponent(destinationName ?? 'Destination');
      url =
          'https://www.google.com/maps/dir/?api=1&origin=$userLat,$userLng'
          '&destination=$destinationLat,$destinationLng'
          '&destination_place_id=$encodedName&travelmode=driving';
    } else if (Platform.isIOS) {
      // For iOS, use Apple Maps URL scheme
      url =
          'https://maps.apple.com/?saddr=$userLat,$userLng'
          '&daddr=$destinationLat,$destinationLng&dirflg=d';
    } else {
      // Fallback to web URL
      url =
          'https://www.google.com/maps/dir/?api=1&origin=$userLat,$userLng'
          '&destination=$destinationLat,$destinationLng&travelmode=driving';
    }

    debugPrint('Launching map URL: $url');

    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch $url');
    }
  }

  /// Opens Google Maps showing a specific location
  static Future<void> launchGoogleMapsLocation({
    required double lat,
    required double lng,
    String? label,
  }) async {
    final encodedLabel = Uri.encodeComponent(label ?? 'Location');
    final url =
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng&query_place_id=$encodedLabel';

    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch $url');
    }
  }
}
