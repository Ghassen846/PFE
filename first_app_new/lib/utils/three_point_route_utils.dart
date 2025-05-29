import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as google_maps;

class ThreePointRouteUtils {
  // Helper method to convert Google Maps LatLng to flutter_map LatLng
  static LatLng _convertToFlutterMapLatLng(google_maps.LatLng point) {
    return LatLng(point.latitude, point.longitude);
  }

  static Future<List<Polyline>> generateThreePointRoute(
    MapController? mapController,
    List<double> fromCoords,
    List<double> restaurantCoords,
    List<double> customerCoords, {
    bool useGraphHopper = true,
  }) async {
    try {
      final List<Polyline> routes = [];

      // First leg: Current location to restaurant
      final firstLeg = await _getRouteBetweenPoints(
        fromCoords[0],
        fromCoords[1],
        restaurantCoords[0],
        restaurantCoords[1],
        useGraphHopper: useGraphHopper,
        color: Colors.blue,
        strokeWidth: 4.0,
      );
      if (firstLeg != null) routes.add(firstLeg);

      // Second leg: Restaurant to customer
      final secondLeg = await _getRouteBetweenPoints(
        restaurantCoords[0],
        restaurantCoords[1],
        customerCoords[0],
        customerCoords[1],
        useGraphHopper: useGraphHopper,
        color: Colors.green,
        strokeWidth: 4.0,
      );
      if (secondLeg != null) routes.add(secondLeg);

      if (routes.isNotEmpty && mapController != null) {
        await _fitMapToRoutes(mapController, routes);
      }

      return routes;
    } catch (e) {
      debugPrint('Error generating route: $e');
      return [];
    }
  }

  static Future<void> _fitMapToRoutes(
    MapController mapController,
    List<Polyline> routes,
  ) async {
    try {
      final allPoints = routes.expand((route) => route.points).toList();
      if (allPoints.isEmpty) {
        debugPrint('No points to fit bounds to');
        return;
      }

      double minLat = allPoints.first.latitude;
      double maxLat = allPoints.first.latitude;
      double minLng = allPoints.first.longitude;
      double maxLng = allPoints.first.longitude;

      for (var point in allPoints) {
        minLat = point.latitude < minLat ? point.latitude : minLat;
        maxLat = point.latitude > maxLat ? point.latitude : maxLat;
        minLng = point.longitude < minLng ? point.longitude : minLng;
        maxLng = point.longitude > maxLng ? point.longitude : maxLng;
      }
      const padding = 0.01; // About 1km
      final bounds = LatLngBounds(
        LatLng(minLat - padding, minLng - padding),
        LatLng(maxLat + padding, maxLng + padding),
      );

      await Future.delayed(const Duration(milliseconds: 100));
      await mapController.fitBounds(
        bounds,
        options: const FitBoundsOptions(padding: EdgeInsets.all(50.0)),
      );
    } catch (e) {
      debugPrint('Error fitting bounds: $e');
    }
  }

  static Future<Polyline?> _getRouteBetweenPoints(
    double startLat,
    double startLng,
    double endLat,
    double endLng, {
    bool useGraphHopper = true,
    Color color = Colors.blue,
    double strokeWidth = 4.0,
  }) async {
    try {
      List<LatLng> routePoints;

      if (useGraphHopper) {
        final response = await _fetchGraphHopperRoute(
          startLat,
          startLng,
          endLat,
          endLng,
        );

        if (response != null) {
          final googlePoints = _decodeGraphHopperResponse(response);
          routePoints = googlePoints.map(_convertToFlutterMapLatLng).toList();
        } else {
          routePoints = [LatLng(startLat, startLng), LatLng(endLat, endLng)];
        }
      } else {
        routePoints = [LatLng(startLat, startLng), LatLng(endLat, endLng)];
      }

      return Polyline(
        points: routePoints,
        color: color,
        strokeWidth: strokeWidth,
        isDotted: false,
      );
    } catch (e) {
      debugPrint('Error getting route between points: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> _fetchGraphHopperRoute(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) async {
    try {
      final apiKey =
          dotenv.env['GRAPH_HOPPER_API_KEY'] ??
          dotenv.env['GRAPHHOPPER_API_KEY'];
      if (apiKey == null ||
          apiKey.isEmpty ||
          apiKey == 'your_graphhopper_api_key_here' ||
          apiKey == 'default_key') {
        debugPrint('Valid GraphHopper API key not found');
        return null;
      }

      final url = Uri.parse(
        'https://graphhopper.com/api/1/route?'
        'point=$startLat,$startLng&'
        'point=$endLat,$endLng&'
        'vehicle=car&'
        'locale=en&'
        'calc_points=true&'
        'points_encoded=false&'
        'instructions=false&'
        'key=$apiKey',
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint('GraphHopper API error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching route: $e');
      return null;
    }
  }

  static List<google_maps.LatLng> _decodeGraphHopperResponse(
    Map<String, dynamic> response,
  ) {
    try {
      if (response['paths'] == null ||
          !(response['paths'] is List) ||
          response['paths'].isEmpty) {
        debugPrint('No paths found in response');
        return [];
      }

      final path = response['paths'][0];
      if (path == null) {
        debugPrint('First path is null');
        return [];
      }

      List<dynamic>? coordinates;

      if (path['points'] is Map && path['points']['coordinates'] is List) {
        coordinates = path['points']['coordinates'] as List;
      } else if (path['points'] is List) {
        coordinates = path['points'] as List;
      } else if (path['snapped_waypoints'] is Map &&
          path['snapped_waypoints']['coordinates'] is List) {
        coordinates = path['snapped_waypoints']['coordinates'] as List;
      }

      if (coordinates == null || coordinates.isEmpty) {
        debugPrint('No valid coordinates found in response');
        return [];
      }

      final points =
          coordinates
              .map((coord) {
                if (coord is List && coord.length >= 2) {
                  try {
                    final lat =
                        (coord[1] is num)
                            ? coord[1].toDouble()
                            : double.parse(coord[1].toString());
                    final lng =
                        (coord[0] is num)
                            ? coord[0].toDouble()
                            : double.parse(coord[0].toString());
                    return google_maps.LatLng(lat, lng);
                  } catch (e) {
                    debugPrint('Error parsing coordinate: $e');
                    return null;
                  }
                }
                return null;
              })
              .whereType<google_maps.LatLng>()
              .toList();

      if (points.isEmpty) {
        debugPrint('No valid points parsed from coordinates');
      }

      return points;
    } catch (e) {
      debugPrint('Error decoding route: $e');
      return [];
    }
  }
}
