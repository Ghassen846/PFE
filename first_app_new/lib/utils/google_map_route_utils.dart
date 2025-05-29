import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GoogleMapRouteUtils {
  static Future<Set<Polyline>> generateThreePointRoute(
    GoogleMapController? mapController,
    List<double> fromCoords,
    List<double> restaurantCoords,
    List<double> customerCoords, {
    bool useGraphHopper = true,
  }) async {
    try {
      final Set<Polyline> routes = {};

      // First leg: Current location to restaurant
      final firstLeg = await _getRouteBetweenPoints(
        fromCoords[0],
        fromCoords[1],
        restaurantCoords[0],
        restaurantCoords[1],
        'route1',
        useGraphHopper: useGraphHopper,
        color: Colors.blue,
        width: 4,
      );
      if (firstLeg != null) routes.add(firstLeg);

      // Second leg: Restaurant to customer
      final secondLeg = await _getRouteBetweenPoints(
        restaurantCoords[0],
        restaurantCoords[1],
        customerCoords[0],
        customerCoords[1],
        'route2',
        useGraphHopper: useGraphHopper,
        color: Colors.green,
        width: 4,
      );
      if (secondLeg != null) routes.add(secondLeg);

      if (routes.isNotEmpty && mapController != null) {
        await _fitMapToRoutes(mapController, routes);
      }

      return routes;
    } catch (e) {
      debugPrint('Error generating route: $e');
      return {};
    }
  }

  static Future<void> _fitMapToRoutes(
    GoogleMapController mapController,
    Set<Polyline> routes,
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

      final bounds = LatLngBounds(
        southwest: LatLng(minLat - 0.01, minLng - 0.01),
        northeast: LatLng(maxLat + 0.01, maxLng + 0.01),
      );

      await mapController.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 50),
      );
    } catch (e) {
      debugPrint('Error fitting bounds: $e');
    }
  }

  static Future<Polyline?> _getRouteBetweenPoints(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
    String polylineId, {
    bool useGraphHopper = true,
    Color color = Colors.blue,
    int width = 4,
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
          routePoints = _decodeGraphHopperResponse(response);
        } else {
          routePoints = [LatLng(startLat, startLng), LatLng(endLat, endLng)];
        }
      } else {
        routePoints = [LatLng(startLat, startLng), LatLng(endLat, endLng)];
      }

      return Polyline(
        polylineId: PolylineId(polylineId),
        points: routePoints,
        color: color,
        width: width,
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

  static List<LatLng> _decodeGraphHopperResponse(
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
                    return LatLng(lat, lng);
                  } catch (e) {
                    debugPrint('Error parsing coordinate: $e');
                    return null;
                  }
                }
                return null;
              })
              .whereType<LatLng>()
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
