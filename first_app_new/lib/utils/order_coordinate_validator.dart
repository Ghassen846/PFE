import 'package:flutter/foundation.dart';
import '../helpers/shared.dart' as shared;

class OrderCoordinateValidator {
  // Default coordinates for Tunisia (Tunis)
  // This matches the backend default coordinates
  static const double DEFAULT_LAT = 36.8065;
  static const double DEFAULT_LNG = 10.1815;
  // Validate and fix coordinates for orders
  static Map<String, dynamic> validateOrderCoordinates(
    Map<String, dynamic> order,
  ) {
    final Map<String, dynamic> validatedOrder = Map<String, dynamic>.from(
      order,
    );

    // Debug output to see full order data
    debugPrint('🔍 Validating order coordinates');
    if (validatedOrder.containsKey('restaurant')) {
      debugPrint('Restaurant info: ${validatedOrder['restaurant']}');
    }

    // Helper function to validate a coordinate
    bool isValidLatitude(dynamic lat) {
      if (lat == null) return false;
      final double? parsedLat = _parseCoordinate(lat);
      return parsedLat != null && parsedLat >= -90 && parsedLat <= 90;
    }

    bool isValidLongitude(dynamic lng) {
      if (lng == null) return false;
      final double? parsedLng = _parseCoordinate(lng);
      return parsedLng != null && parsedLng >= -180 && parsedLng <= 180;
    }

    // Initial check for restaurant coordinates
    double? restaurantLat = _parseCoordinate(
      validatedOrder['restaurantLatitude'],
    );
    double? restaurantLng = _parseCoordinate(
      validatedOrder['restaurantLongitude'],
    );

    final bool validLat = isValidLatitude(restaurantLat);
    final bool validLng = isValidLongitude(restaurantLng);

    // Try to get coordinates from different sources if they're invalid
    if (!validLat || !validLng) {
      debugPrint(
        'Restaurant coordinates invalid, searching alternative sources',
      );

      // 1. First try restaurantLocation if it exists
      if (validatedOrder.containsKey('restaurantLocation') &&
          validatedOrder['restaurantLocation'] is Map) {
        final location = validatedOrder['restaurantLocation'] as Map;
        final double? locLat = _parseCoordinate(location['latitude']);
        final double? locLng = _parseCoordinate(location['longitude']);

        if (!validLat && isValidLatitude(locLat)) {
          restaurantLat = locLat;
          debugPrint('Using latitude from restaurantLocation: $restaurantLat');
        }

        if (!validLng && isValidLongitude(locLng)) {
          restaurantLng = locLng;
          debugPrint('Using longitude from restaurantLocation: $restaurantLng');
        }
      }

      // 2. Then try restaurant object if it exists
      if (validatedOrder.containsKey('restaurant') &&
          validatedOrder['restaurant'] is Map) {
        final restaurant = validatedOrder['restaurant'] as Map;
        final double? restLat = _parseCoordinate(restaurant['latitude']);
        final double? restLng = _parseCoordinate(restaurant['longitude']);

        if ((!validLat || restaurantLat == null) && isValidLatitude(restLat)) {
          restaurantLat = restLat;
          debugPrint('Using latitude from restaurant object: $restaurantLat');
        }

        if ((!validLng || restaurantLng == null) && isValidLongitude(restLng)) {
          restaurantLng = restLng;
          debugPrint('Using longitude from restaurant object: $restaurantLng');
        }

        // Get restaurant name and address if not already set
        if (!validatedOrder.containsKey('restaurantName') &&
            restaurant.containsKey('name')) {
          validatedOrder['restaurantName'] = restaurant['name'];
        }

        if (!validatedOrder.containsKey('restaurantAddress') &&
            restaurant.containsKey('address')) {
          validatedOrder['restaurantAddress'] = restaurant['address'];
        }
      }

      // 3. Try rawOrder.restaurant as a final fallback
      if (validatedOrder.containsKey('rawOrder') &&
          validatedOrder['rawOrder'] is Map &&
          validatedOrder['rawOrder'].containsKey('restaurant') &&
          validatedOrder['rawOrder']['restaurant'] is Map) {
        final rawRestaurant = validatedOrder['rawOrder']['restaurant'] as Map;

        final double? rawLat = _parseCoordinate(rawRestaurant['latitude']);
        final double? rawLng = _parseCoordinate(rawRestaurant['longitude']);

        if ((!validLat || restaurantLat == null) && isValidLatitude(rawLat)) {
          restaurantLat = rawLat;
          debugPrint('Using latitude from rawOrder.restaurant: $restaurantLat');
        }

        if ((!validLng || restaurantLng == null) && isValidLongitude(rawLng)) {
          restaurantLng = rawLng;
          debugPrint(
            'Using longitude from rawOrder.restaurant: $restaurantLng',
          );
        }
      }
    } // Perform a final validation and set defaults if needed
    if (!isValidLatitude(restaurantLat) || !isValidLongitude(restaurantLng)) {
      debugPrint(
        '❌ No valid restaurant coordinates found, checking specific values',
      );

      // Look in other fields for the restaurant coordinates before falling back to defaults
      if (validatedOrder.containsKey('pickupLocation') &&
          validatedOrder['pickupLocation'] is String) {
        // The address might contain coordinates in parentheses
        final String pickupLocation = validatedOrder['pickupLocation'];
        debugPrint('🔍 Checking pickup location: $pickupLocation');

        // Try to extract coordinates from the address if they're formatted like "Address (lat,lng)"
        final RegExp coordRegex = RegExp(r'\((-?\d+\.\d+),\s*(-?\d+\.\d+)\)');
        final match = coordRegex.firstMatch(pickupLocation);

        if (match != null && match.groupCount >= 2) {
          final double? extractedLat = double.tryParse(match.group(1)!);
          final double? extractedLng = double.tryParse(match.group(2)!);

          if (isValidLatitude(extractedLat) && isValidLongitude(extractedLng)) {
            restaurantLat = extractedLat;
            restaurantLng = extractedLng;
            debugPrint(
              '✅ Extracted restaurant coordinates from address: [$restaurantLat, $restaurantLng]',
            );
          }
        }
      } // If still no valid coordinates, use Mahdia defaults
      if (!isValidLatitude(restaurantLat) || !isValidLongitude(restaurantLng)) {
        debugPrint(
          '❌ Using Mahdia coordinates for restaurant instead of Tunisia defaults',
        );
        restaurantLat = 35.5270204; // Mahdia
        restaurantLng = 11.0332198;
      }
    } else {
      debugPrint(
        '✅ Using valid restaurant coordinates: [$restaurantLat, $restaurantLng]',
      );
    }

    // Update the order with validated coordinates
    validatedOrder['restaurantLatitude'] = restaurantLat;
    validatedOrder['restaurantLongitude'] = restaurantLng;

    // Client location validation with the same robust approach
    Map<String, dynamic> clientLocation = {};
    if (validatedOrder.containsKey('clientLocation') &&
        validatedOrder['clientLocation'] is Map) {
      clientLocation = Map<String, dynamic>.from(
        validatedOrder['clientLocation'] as Map,
      );
    } else {
      clientLocation = {'latitude': null, 'longitude': null};
    }

    // Parse client coordinates
    double? clientLat = _parseCoordinate(clientLocation['latitude']);
    double? clientLng = _parseCoordinate(clientLocation['longitude']);

    // Check if client coordinates are valid
    final bool validClientLat = isValidLatitude(clientLat);
    final bool validClientLng = isValidLongitude(
      clientLng,
    ); // Try alternative sources for client location
    if (!validClientLat || !validClientLng) {
      debugPrint(
        '🔍 Client coordinates invalid, searching alternative sources',
      );

      // First try to get user's location directly
      if (validatedOrder.containsKey('user') && validatedOrder['user'] is Map) {
        final user = validatedOrder['user'] as Map;

        // Direct location property on user
        if (user.containsKey('location') &&
            user['location'] is Map &&
            user['location'].containsKey('latitude') &&
            user['location'].containsKey('longitude')) {
          final userLocLat = _parseCoordinate(user['location']['latitude']);
          final userLocLng = _parseCoordinate(user['location']['longitude']);

          if (isValidLatitude(userLocLat) && !validClientLat) {
            clientLat = userLocLat;
            debugPrint('✅ Using latitude from user location: $clientLat');
          }

          if (isValidLongitude(userLocLng) && !validClientLng) {
            clientLng = userLocLng;
            debugPrint('✅ Using longitude from user location: $clientLng');
          }
        }

        // Check default address
        if ((!validClientLat || !validClientLng) &&
            user.containsKey('addresses') &&
            user['addresses'] is List) {
          debugPrint('🔍 Checking user addresses: ${user['addresses']}');

          for (var address in user['addresses']) {
            if (address is Map &&
                address.containsKey('isDefault') &&
                address['isDefault'] == true &&
                address.containsKey('latitude') &&
                address.containsKey('longitude')) {
              final addrLat = _parseCoordinate(address['latitude']);
              final addrLng = _parseCoordinate(address['longitude']);

              if (isValidLatitude(addrLat) && !validClientLat) {
                clientLat = addrLat;
                debugPrint('✅ Using latitude from default address: $clientLat');
              }

              if (isValidLongitude(addrLng) && !validClientLng) {
                clientLng = addrLng;
                debugPrint(
                  '✅ Using longitude from default address: $clientLng',
                );
              }

              break;
            }
          }
        }
      } // Next try order latitude/longitude
      if ((!validClientLat || !validClientLng) &&
          validatedOrder.containsKey('latitude') &&
          validatedOrder.containsKey('longitude')) {
        final double? orderLat = _parseCoordinate(validatedOrder['latitude']);
        final double? orderLng = _parseCoordinate(validatedOrder['longitude']);

        if (!validClientLat && isValidLatitude(orderLat)) {
          clientLat = orderLat;
          debugPrint('✅ Using latitude from order: $clientLat');
        }

        if (!validClientLng && isValidLongitude(orderLng)) {
          clientLng = orderLng;
          debugPrint('✅ Using longitude from order: $clientLng');
        }
      }

      // Try rawOrder data if available
      if ((!validClientLat || !validClientLng) &&
          validatedOrder.containsKey('rawOrder') &&
          validatedOrder['rawOrder'] is Map) {
        final rawOrder = validatedOrder['rawOrder'] as Map;
        final double? rawLat = _parseCoordinate(rawOrder['latitude']);
        final double? rawLng = _parseCoordinate(rawOrder['longitude']);

        if (!validClientLat && isValidLatitude(rawLat)) {
          clientLat = rawLat;
          debugPrint('Using latitude from rawOrder: $clientLat');
        }

        if (!validClientLng && isValidLongitude(rawLng)) {
          clientLng = rawLng;
          debugPrint('Using longitude from rawOrder: $clientLng');
        }
      }
    } // Set client coordinates - if still invalid, try to find any valid coordinates
    if (!isValidLatitude(clientLat) || !isValidLongitude(clientLng)) {
      debugPrint(
        '❌ No valid client coordinates found, searching through order data',
      );

      // Deep search through the order data for valid coordinates
      if (validatedOrder.containsKey('deliveryAddress') &&
          validatedOrder['deliveryAddress'] is String) {
        // The address might contain coordinates in parentheses
        final String deliveryAddress = validatedOrder['deliveryAddress'];
        debugPrint('🔍 Checking delivery address: $deliveryAddress');

        // Try to extract coordinates from the address if they're formatted like "Address (lat,lng)"
        final RegExp coordRegex = RegExp(r'\((-?\d+\.\d+),\s*(-?\d+\.\d+)\)');
        final match = coordRegex.firstMatch(deliveryAddress);

        if (match != null && match.groupCount >= 2) {
          final double? extractedLat = double.tryParse(match.group(1)!);
          final double? extractedLng = double.tryParse(match.group(2)!);

          if (isValidLatitude(extractedLat) && isValidLongitude(extractedLng)) {
            clientLat = extractedLat;
            clientLng = extractedLng;
            debugPrint(
              '✅ Extracted client coordinates from address: [$clientLat, $clientLng]',
            );
          }
        }
      }

      // Search for the specific location we want if nothing else works
      if (!isValidLatitude(clientLat) || !isValidLongitude(clientLng)) {
        // Hard-coded special case for Mahdia, Tunisia
        if (validatedOrder.containsKey('deliveryAddress') &&
            validatedOrder['deliveryAddress'] is String &&
            validatedOrder['deliveryAddress'].toLowerCase().contains(
              'mahdia',
            )) {
          clientLat = 35.5270204;
          clientLng = 11.0332198;
          debugPrint(
            '✅ Using special location for Mahdia: [$clientLat, $clientLng]',
          );
        }
      }

      // If still no valid coordinates, use restaurant with offset as last resort
      if (!isValidLatitude(clientLat) || !isValidLongitude(clientLng)) {
        debugPrint('⚠️ Falling back to restaurant coordinates with offset');
        if (isValidLatitude(restaurantLat) && isValidLongitude(restaurantLng)) {
          // If restaurant is using default coordinates, use different client coordinates
          if (restaurantLat == DEFAULT_LAT && restaurantLng == DEFAULT_LNG) {
            clientLat = 35.5270204; // Mahdia coordinates
            clientLng = 11.0332198;
            debugPrint(
              '✅ Using Mahdia coordinates for client: [$clientLat, $clientLng]',
            );
          } else {
            clientLat = restaurantLat;
            clientLng = restaurantLng;
            // Add a very small offset to avoid exact same coordinates
            clientLat = clientLat! + 0.0001;
            clientLng = clientLng! + 0.0001;
            debugPrint(
              '⚠️ Using restaurant coordinates with small offset: [$clientLat, $clientLng]',
            );
          }
        } else {
          // Absolute last resort - use defaults
          clientLat = 35.5270204; // Mahdia
          clientLng = 11.0332198;
          debugPrint(
            '⚠️ Using default Mahdia coordinates: [$clientLat, $clientLng]',
          );
        }
      } else {
        debugPrint(
          '✅ Using valid client coordinates: [$clientLat, $clientLng]',
        );
      }
    } else {
      debugPrint('✅ Using valid client coordinates: [$clientLat, $clientLng]');
    } // Update client location with validated coordinates
    clientLocation['latitude'] = clientLat;
    clientLocation['longitude'] = clientLng;
    validatedOrder['clientLocation'] = clientLocation;

    debugPrint(
      '✅ Final validated coordinates: restaurant: [$restaurantLat, $restaurantLng], client: [$clientLat, $clientLng]',
    );

    return validatedOrder;
  }

  // Helper function to parse coordinate values safely
  static double? _parseCoordinate(dynamic value) {
    if (value == null) return null;

    if (value is String) {
      try {
        final parsed = double.parse(value);
        return parsed.isNaN ? null : parsed;
      } catch (e) {
        return null;
      }
    }

    if (value is int) {
      return value.toDouble();
    }

    if (value is double) {
      return value.isNaN ? null : value;
    }

    return null;
  }

  // Helper to create a LatLng from order data
  static shared.LatLng? getRestaurantLatLng(Map<String, dynamic> order) {
    final validatedOrder = validateOrderCoordinates(order);
    final lat = validatedOrder['restaurantLatitude'];
    final lng = validatedOrder['restaurantLongitude'];

    if (lat != null && lng != null) {
      return shared.LatLng(lat, lng);
    }

    return null;
  }

  // Helper to get client location as LatLng
  static shared.LatLng? getClientLatLng(Map<String, dynamic> order) {
    final validatedOrder = validateOrderCoordinates(order);

    if (validatedOrder.containsKey('clientLocation') &&
        validatedOrder['clientLocation'] is Map) {
      final location = validatedOrder['clientLocation'] as Map;
      final lat = location['latitude'];
      final lng = location['longitude'];

      if (lat != null && lng != null) {
        return shared.LatLng(lat, lng);
      }
    }

    return null;
  }

  // Helper to check if a string is a valid coordinate
  static bool isValidCoordinate(List<double>? coord) {
    if (coord == null || coord.length != 2) return false;
    return coord[0] >= -90 &&
        coord[0] <= 90 &&
        coord[1] >= -180 &&
        coord[1] <= 180;
  }
}
