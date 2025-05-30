import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:ui' as ui;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'responsive/sizer_ext.dart';

// User account model (simplified)
class Account {
  final String id;
  final String name;
  final String email;

  Account({required this.id, required this.name, required this.email});
}

List<Account> accounts = [];

// Position model for when Google Maps is not available
class LatLng {
  final double latitude;
  final double longitude;

  const LatLng(this.latitude, this.longitude);

  @override
  String toString() => 'LatLng($latitude, $longitude)';

  @override
  bool operator ==(Object other) {
    return other is LatLng &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode => Object.hash(latitude, longitude);
}

// Mock BitmapDescriptor for when Google Maps is not available
class BitmapDescriptor {
  final int value;

  const BitmapDescriptor._(this.value);

  static const BitmapDescriptor defaultMarker = BitmapDescriptor._(0);
  static const BitmapDescriptor defaultMarkerWithHue = BitmapDescriptor._(1);

  static BitmapDescriptor fromBytes(List<int> bytes) {
    return const BitmapDescriptor._(2);
  }
}

// Using dotenv for environment variables
String baseUrl = dotenv.env['BASE_URL'] ?? 'http://192.168.100.41:3000/api';
// Ensure a working GraphHopper API key is provided
// You need to sign up at https://graphhopper.com to get a free API key
String apiKey = '';

// Function to ensure API key is properly loaded from .env
void initializeApiKey() {
  apiKey = dotenv.env['GRAPH_HOPPER_API_KEY'] ?? '';
  if (apiKey.isEmpty ||
      apiKey == 'your_graphhopper_api_key_here' ||
      apiKey == 'default_key') {
    debugPrint(
      'Warning: Valid GraphHopper API key not configured. Routing will use fallback method.',
    );
  }
}

final String baseUrlWS =
    dotenv.env['BASE_URL_WS'] ?? 'ws://192.168.100.41:3000';
const Color hintColor = Color.fromARGB(64, 0, 0, 0);

// SharedPreferences instance to be initialized in main.dart
late SharedPreferences prefs;

// Initialize shared preferences
Future<void> initPrefs() async {
  prefs = await SharedPreferences.getInstance();
}

Future<double> getLatFromSharedPrefs() async {
  await initPrefs(); // Ensure prefs is initialized
  return prefs.getDouble('latitude') ?? 0.0;
}

Future<double> getLngFromSharedPrefs() async {
  await initPrefs(); // Ensure prefs is initialized
  return prefs.getDouble('longitude') ?? 0.0;
}

Future<String> getIdFromSharedPrefs() async {
  await initPrefs(); // Ensure prefs is initialized
  return prefs.getString('user_id') ?? '';
}

Future<String> getTokenFromSharedPrefs() async {
  await initPrefs(); // Ensure prefs is initialized
  return prefs.getString('token') ?? '';
}

/*Map getDecodedResponseFromSharedPrefs(int index) {
  String key = 'restaurant--$index';
  Map response = json.decode(prefs.getString(key)!);
  return response;
}

num getDistanceFromSharedPrefs(int index) {
  num distance = getDecodedResponseFromSharedPrefs(index)['distance'];
  return distance;
}

num getDurationFromSharedPrefs(int index) {
  num duration = getDecodedResponseFromSharedPrefs(index)['duration'];
  return duration;
}

Map getGeometryFromSharedPrefs(int index) {
  Map geometry = getDecodedResponseFromSharedPrefs(index)['geometry'];
  return geometry;
}

*/

Future<LatLng> getCoordinatesFromAddressGraphHopper(String address) async {
  // Check if API key is available and valid
  if (apiKey.isEmpty ||
      apiKey == 'your_graphhopper_api_key_here' ||
      apiKey == 'default_key') {
    debugPrint('GraphHopper API key not configured, using fallback geocoding');
    return await _fallbackGeocoding(address);
  }

  try {
    final encodedAddress = Uri.encodeComponent(address);

    // Construct the URL for the GraphHopper Geocoding API
    final url = Uri.parse(
      'https://graphhopper.com/api/1/geocode?q=$encodedAddress&locale=en&key=$apiKey',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['hits'].isNotEmpty) {
        // Assuming the first hit is the most relevant one
        final firstHit = jsonResponse['hits'][0];
        final location = firstHit['point'];
        return LatLng(location['lat'], location['lng']);
      } else {
        debugPrint('No geocoding results found, using fallback');
        return await _fallbackGeocoding(address);
      }
    } else {
      debugPrint(
        'GraphHopper API error: ${response.statusCode}, using fallback',
      );
      return await _fallbackGeocoding(address);
    }
  } catch (e) {
    debugPrint('GraphHopper geocoding failed: $e, using fallback');
    return await _fallbackGeocoding(address);
  }
}

// Fallback geocoding using backend service or default coordinates
Future<LatLng> _fallbackGeocoding(String address) async {
  try {
    // Try to use the backend's geocoding service
    final response = await http.get(
      Uri.parse('$baseUrl/geocode/search?q=${Uri.encodeComponent(address)}'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['lat'] != null && data['lng'] != null) {
        return LatLng(data['lat'], data['lng']);
      }
    }
  } catch (e) {
    debugPrint('Backend geocoding failed: $e');
  }

  // Final fallback: return Mahdia coordinates instead of default Tunisia coordinates
  debugPrint('All geocoding methods failed, using Mahdia coordinates');
  return const LatLng(35.5270204, 11.0332198); // Mahdia coordinates
}

Future<String> getAddressFromCoordinatesGraphHopper(
  double latitude,
  double longitude,
  String apiKey,
) async {
  // Check if API key is available and valid
  if (apiKey.isEmpty ||
      apiKey == 'your_graphhopper_api_key_here' ||
      apiKey == 'default_key') {
    debugPrint(
      'GraphHopper API key not configured, using fallback reverse geocoding',
    );
    return await _fallbackReverseGeocoding(latitude, longitude);
  }

  try {
    // Construct the URL for the GraphHopper Reverse Geocoding API
    final url = Uri.parse(
      'https://graphhopper.com/api/1/geocode?point=$latitude,$longitude&locale=en&reverse=true&key=$apiKey',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['hits'].isNotEmpty) {
        // Assuming the first hit is the most relevant one
        final firstHit = jsonResponse['hits'][0];
        // Extracting the full address
        final address = firstHit['name'];
        return address;
      } else {
        debugPrint('No reverse geocoding results found, using fallback');
        return await _fallbackReverseGeocoding(latitude, longitude);
      }
    } else {
      debugPrint(
        'GraphHopper API error: ${response.statusCode}, using fallback',
      );
      return await _fallbackReverseGeocoding(latitude, longitude);
    }
  } catch (e) {
    debugPrint('GraphHopper reverse geocoding failed: $e, using fallback');
    return await _fallbackReverseGeocoding(latitude, longitude);
  }
}

// Fallback reverse geocoding using backend service or default address
Future<String> _fallbackReverseGeocoding(
  double latitude,
  double longitude,
) async {
  try {
    // Try to use the backend's reverse geocoding service
    final response = await http.get(
      Uri.parse('$baseUrl/geocode/reverse?lat=$latitude&lon=$longitude'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['address'] != null) {
        return data['address'];
      }
    }
  } catch (e) {
    debugPrint('Backend reverse geocoding failed: $e');
  }

  // Final fallback: return a location description for Mahdia
  debugPrint('All reverse geocoding methods failed, using Mahdia address');
  return 'Mahdia, Tunisia';
}

Future<BitmapDescriptor> getMarkerFromAsset(
  String assetPath, {
  int width = 200,
  int height = 200,
}) async {
  // Load the image from the asset bundle
  ByteData data = await rootBundle.load(assetPath);
  ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
  ui.FrameInfo fi = await codec.getNextFrame();

  // Create a new picture recorder and canvas
  ui.PictureRecorder recorder = ui.PictureRecorder();
  Canvas canvas = Canvas(recorder);

  // Create a paint object (if you want to modify the painting style)
  Paint paint = Paint()..color = ui.Color(Colors.white.value);

  // Draw the image onto the canvas, resizing it to the desired width and height
  ui.Image image = fi.image;
  canvas.drawImageRect(
    image,
    Rect.fromLTRB(0, 0, image.width.toDouble(), image.height.toDouble()),
    Rect.fromLTRB(0, 0, width.toDouble(), height.toDouble()),
    paint,
  );

  // Convert the canvas into an image
  ui.Image resizedImage = await recorder.endRecording().toImage(width, height);

  // Convert the image to bytes in PNG format
  final Uint8List markerImageBytes =
      (await resizedImage.toByteData(
        format: ui.ImageByteFormat.png,
      ))!.buffer.asUint8List();

  // Create a BitmapDescriptor from the image bytes
  return BitmapDescriptor.fromBytes(markerImageBytes);
}

Future<String> getDistanceAndDuration(String start, String destination) async {
  LatLng startLatLng = await getCoordinatesFromAddressGraphHopper(start);
  LatLng destinationLatLng = await getCoordinatesFromAddressGraphHopper(
    destination,
  );
  var response = await http.get(
    Uri.parse(
      'https://graphhopper.com/api/1/route?point=${startLatLng.latitude},${startLatLng.longitude}&point=${destinationLatLng.latitude},${destinationLatLng.longitude}&vehicle=car&locale=en&key=$apiKey',
    ),
  );
  var jsonData = jsonDecode(response.body);
  double distanceInMeters = jsonData["paths"][0]["distance"];
  int timeInMillis = jsonData["paths"][0]["time"];

  // Convert distance to kilometers (if needed) and format time
  double distanceInKm = distanceInMeters / 1000;
  String estimatedTime = _formatDuration(Duration(milliseconds: timeInMillis));
  return "Distance: ${distanceInKm.toStringAsFixed(2)} km, Duration: $estimatedTime";
}

String _formatDuration(Duration duration) {
  int totalMinutes = duration.inMinutes;
  return "$totalMinutes min";
}

double calculateDeliveryFee(double distance) {
  double baseFee = 2.0;

  double feePerKilometer = 0.5;

  double freeDeliveryDistance = 5.0;

  double additionalDistance = distance - freeDeliveryDistance;

  if (additionalDistance <= 0) {
    return baseFee;
  } else {
    return baseFee + (additionalDistance * feePerKilometer);
  }
}

void showCustomDialog(
  BuildContext context,
  String title,
  String message,
  Color color1,
  Color color2,
  IconData icon,
) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Container(
          width: 300.w,
          height: 30.h,
          decoration: BoxDecoration(
            color: color1,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(icon, size: 60.sp, color: Colors.white),
                    SizedBox(height: 2.h),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 1.h,
                      ),
                      child: Center(
                        child: Text(
                          message,
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

// Get stored coordinates from SharedPreferences
Future<LatLng> getStoredCoordinates() async {
  double lat = await getLatFromSharedPrefs();
  double lng = await getLngFromSharedPrefs();

  // Check if coordinates are valid
  if (lat == 0.0 && lng == 0.0) {
    throw Exception('Invalid coordinates. Please check location settings.');
  }

  return LatLng(lat, lng);
}
