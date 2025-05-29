import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as google_maps;
import '../helpers/shared.dart' as shared;

class RouteUtils {
  /// Add a street-level route to the map, with fallbacks to different services

  /// Get a route using GraphHopper API
  static Future<Polyline> _getGraphHopperRoute(
    MapController mapController,
    List<double> from,
    List<double> to, {
    Color color = Colors.blue,
    String profile = 'driving',
  }) async {
    final url = Uri.parse(
      'https://graphhopper.com/api/1/route'
      '?point=${from[0]},${from[1]}'
      '&point=${to[0]},${to[1]}'
      '&vehicle=${profile == 'driving' ? 'car' : profile}'
      '&locale=en'
      '&key=${shared.apiKey}'
      '&points_encoded=false', // Request uncompressed points
    );

    final response = await http.get(url).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);

      if (jsonResponse.containsKey('paths') &&
          jsonResponse['paths'].isNotEmpty) {
        final path = jsonResponse['paths'][0];

        // Extract route points
        final points = path['points']['coordinates'];
        final List<google_maps.LatLng> routePoints = [];

        for (var point in points) {
          // GraphHopper returns [longitude, latitude] format
          routePoints.add(google_maps.LatLng(point[1], point[0]));
        }

        // Create and return polyline
        final polyline = Polyline(
          points: _convertToPolylinePoints(routePoints),
          color: color,
          strokeWidth: 4.0,
        );

        return polyline;
      } else {
        throw Exception('No route found');
      }
    } else {
      throw Exception('Failed to fetch route: ${response.statusCode}');
    }
  }

  /// Helper method to convert Google Maps LatLng to flutter_map points
  static List<LatLng> _convertToPolylinePoints(
    List<google_maps.LatLng> points,
  ) {
    return points
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList();
  }

  /// Calculate distance between two points using the Haversine formula
  static double _calculateDistance(
    google_maps.LatLng from,
    google_maps.LatLng to,
  ) {
    const R = 6371000; // Earth radius in meters
    final lat1 = from.latitude * (pi / 180);
    final lat2 = to.latitude * (pi / 180);
    final dLat = (to.latitude - from.latitude) * (pi / 180);
    final dLon = (to.longitude - from.longitude) * (pi / 180);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c; // Distance in meters
  }

  /// Create a simple straight line fallback route
  static Polyline _createFallbackRoute(
    MapController mapController,
    List<double> from,
    List<double> to, {
    Color color = Colors.red,
  }) {
    final fromLatLng = LatLng(from[0], from[1]);
    final toLatLng = LatLng(to[0], to[1]);

    return Polyline(
      points: [fromLatLng, toLatLng],
      color: color,
      strokeWidth: 3.0,
      isDotted: true, // Make it dotted to indicate it's a fallback
    );
  }

  /// Create an enhanced fallback route when GraphHopper is unavailable
  static Polyline createEnhancedFallbackRoute(
    MapController mapController,
    List<double> from,
    List<double> to, {
    Color color = Colors.orange,
    int numPoints = 5,
  }) {
    final routePoints = generateRouteWithWaypoints(
      from,
      to,
      numPoints: numPoints,
    );

    return Polyline(
      points: routePoints,
      color: color,
      strokeWidth: 4.0,
      isDotted: true, // Visual indicator that this is an estimated route
    );
  }

  /// Check if a coordinate is valid
  static bool _isValidCoordinate(List<double>? coord) {
    if (coord == null || coord.length != 2) return false;
    return coord[0] >= -90 &&
        coord[0] <= 90 &&
        coord[1] >= -180 &&
        coord[1] <= 180;
  }

  /// Get route information (distance and duration)
  static Future<Map<String, dynamic>> getRouteInfo(
    List<double> from,
    List<double> to, {
    String profile = 'driving',
  }) async {
    try {
      // Check if API key is available
      if (shared.apiKey.isEmpty) {
        debugPrint(
          'GraphHopper API key is missing - using estimated route info',
        );
        return _getEstimatedRouteInfo(from, to);
      }

      final url = Uri.parse(
        'https://graphhopper.com/api/1/route'
        '?point=${from[0]},${from[1]}'
        '&point=${to[0]},${to[1]}'
        '&vehicle=${profile == 'driving' ? 'car' : profile}'
        '&locale=en'
        '&key=${shared.apiKey}',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse.containsKey('paths') &&
            jsonResponse['paths'].isNotEmpty) {
          final path = jsonResponse['paths'][0];

          // Extract distance and time information
          final distance = path['distance']; // in meters
          final time = path['time']; // in milliseconds

          return {
            'distance': distance,
            'distanceText': '${(distance / 1000).toStringAsFixed(2)} km',
            'duration': time,
            'durationText': '${(time / 60000).toStringAsFixed(0)} min',
          };
        }
      } else {
        throw Exception('Failed to fetch route info: ${response.statusCode}');
      }

      return _getEstimatedRouteInfo(from, to);
    } catch (e) {
      debugPrint('Error getting route info: $e');
      return _getEstimatedRouteInfo(from, to);
    }
  }

  /// Get estimated route information when API is unavailable
  static Map<String, dynamic> _getEstimatedRouteInfo(
    List<double> from,
    List<double> to,
  ) {
    // Calculate straight-line distance
    final fromLatLng = google_maps.LatLng(from[0], from[1]);
    final toLatLng = google_maps.LatLng(to[0], to[1]);

    final distanceInMeters = _calculateDistance(fromLatLng, toLatLng);
    final distanceInKm = distanceInMeters / 1000;

    // Estimate duration (assume average speed of 40 km/h)
    final durationInMinutes = (distanceInKm / 40 * 60).round();

    return {
      'distance': distanceInMeters,
      'distanceText': '~${distanceInKm.toStringAsFixed(2)} km (estimated)',
      'duration': durationInMinutes * 60000,
      'durationText': '~$durationInMinutes min (estimated)',
      'isEstimate': true,
    };
  }

  /// Calculate the bearing (compass direction) between two points
  static double calculateBearing(List<double> from, List<double> to) {
    final lat1 = from[0] * (pi / 180);
    final lng1 = from[1] * (pi / 180);
    final lat2 = to[0] * (pi / 180);
    final lng2 = to[1] * (pi / 180);

    final y = sin(lng2 - lng1) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(lng2 - lng1);

    final bearing = atan2(y, x) * (180 / pi);
    return (bearing + 360) % 360; // Normalize to 0-360
  }

  /// Get a human-readable compass direction
  static String getBearingText(double bearing) {
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW', 'N'];
    return directions[(bearing / 45).round() % 8];
  }

  /// Calculate a point at a certain distance and bearing from a starting point
  static List<double> calculateDestination(
    List<double> start,
    double distanceInMeters,
    double bearingInDegrees,
  ) {
    const R = 6371000; // Earth's radius in meters

    final d = distanceInMeters / R;
    final bearing = bearingInDegrees * (pi / 180);
    final lat1 = start[0] * (pi / 180);
    final lng1 = start[1] * (pi / 180);

    final lat2 = asin(sin(lat1) * cos(d) + cos(lat1) * sin(d) * cos(bearing));
    final lng2 =
        lng1 +
        atan2(
          sin(bearing) * sin(d) * cos(lat1),
          cos(d) - sin(lat1) * sin(lat2),
        );

    return [lat2 * (180 / pi), lng2 * (180 / pi)];
  }

  /// Generate intermediate waypoints to simulate a realistic route
  static List<LatLng> generateRouteWithWaypoints(
    List<double> from,
    List<double> to, {
    int numPoints = 5,
  }) {
    final fromLatLng = LatLng(from[0], from[1]);
    final toLatLng = LatLng(to[0], to[1]);

    // If points are very close, just return direct line
    final google_from = google_maps.LatLng(from[0], from[1]);
    final google_to = google_maps.LatLng(to[0], to[1]);
    final distance = _calculateDistance(google_from, google_to);

    if (distance < 1000) {
      // Less than 1km
      return [fromLatLng, toLatLng];
    }

    final bearing = calculateBearing(from, to);
    final points = <LatLng>[fromLatLng];

    // Calculate segment distance
    final segmentDistance = distance / (numPoints + 1);

    // Generate waypoints with slight deviations
    for (int i = 1; i <= numPoints; i++) {
      // Calculate a point along the direct path
      final directPoint = calculateDestination(
        from,
        segmentDistance * i,
        bearing,
      );

      // Add some randomness to simulate a real route
      // More deviation in the middle of the route, less at start/end
      final deviation = sin(pi * i / (numPoints + 1)) * 0.005;

      // Random offset perpendicular to the bearing
      final offsetBearing = (bearing + 90) % 360;
      final offsetDistance = (i % 2 == 0 ? 1 : -1) * deviation * distance;

      final waypoint = calculateDestination(
        directPoint,
        offsetDistance,
        offsetBearing,
      );

      points.add(LatLng(waypoint[0], waypoint[1]));
    }

    points.add(toLatLng);
    return points;
  }

  /// Get maneuvers/turn-by-turn directions for a route
  static List<Map<String, dynamic>> getRouteDirections(
    List<LatLng> routePoints, {
    double minDistance = 100, // Min distance in meters between direction points
  }) {
    if (routePoints.length < 2) return [];

    final directions = <Map<String, dynamic>>[];
    LatLng prevPoint = routePoints.first;
    double totalDistance = 0;
    double lastDirectionDistance = 0;

    // Calculate distance and bearing changes along the route
    for (int i = 1; i < routePoints.length; i++) {
      final currentPoint = routePoints[i];

      // Calculate distance from previous point
      final google_prev = google_maps.LatLng(
        prevPoint.latitude,
        prevPoint.longitude,
      );
      final google_current = google_maps.LatLng(
        currentPoint.latitude,
        currentPoint.longitude,
      );
      final distance = _calculateDistance(google_prev, google_current);

      totalDistance += distance;

      // Only create a new direction if we've traveled minimum distance
      if (totalDistance - lastDirectionDistance >= minDistance) {
        // Calculate bearing
        final bearing = calculateBearing(
          [prevPoint.latitude, prevPoint.longitude],
          [currentPoint.latitude, currentPoint.longitude],
        );

        // Create direction entry
        directions.add({
          'distance': totalDistance - lastDirectionDistance,
          'distanceText':
              '${((totalDistance - lastDirectionDistance) / 1000).toStringAsFixed(1)} km',
          'bearing': bearing,
          'directionText': getBearingText(bearing),
          'point': currentPoint,
        });

        lastDirectionDistance = totalDistance;
      }

      prevPoint = currentPoint;
    }

    return directions;
  }

  /// Create a fallback route with a straight line if API key is missing or invalid
  static Future<Polyline> addStreetLevelRouteFallback(
    MapController mapController,
    List<double> from,
    List<double> to, {
    Color color = Colors.blue,
    String profile = 'driving',
  }) async {
    // Check if coordinates are valid
    if (!_isValidCoordinate(from) || !_isValidCoordinate(to)) {
      debugPrint('Invalid coordinates provided');
      return _createFallbackRoute(mapController, from, to, color: Colors.red);
    }

    // Check if API key is available
    if (shared.apiKey.isEmpty) {
      debugPrint('GraphHopper API key is missing - using fallback route');
      return createEnhancedFallbackRoute(
        mapController,
        from,
        to,
        color: Colors.orange,
      );
    }

    // Try GraphHopper first (primary service)
    try {
      // Use existing method
      return await _getGraphHopperRoute(
        mapController,
        from,
        to,
        color: color,
        profile: profile,
      );
    } catch (e) {
      debugPrint('GraphHopper routing failed: $e');
      return createEnhancedFallbackRoute(
        mapController,
        from,
        to,
        color: Colors.orange,
      );
    }
  }

  // Updated method to handle API key validation
  static Future<Polyline> addStreetLevelRoute(
    MapController mapController,
    List<double> from,
    List<double> to, {
    Color color = Colors.blue,
    String profile = 'driving',
  }) async {
    return addStreetLevelRouteFallback(
      mapController,
      from,
      to,
      color: color,
      profile: profile,
    );
  }
}
