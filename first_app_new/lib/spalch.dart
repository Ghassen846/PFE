import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'services/AuthService.dart';
import 'services/ApiService.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  // Check if user is already logged in and update online status
  Future<void> checkLoginStatus(BuildContext context) async {
    try {
      final bool isLoggedIn = await AuthService.isLoggedIn();

      if (isLoggedIn) {
        debugPrint('User already logged in, updating online status...');
        // Verify server connection before updating online status
        final bool serverConnected = await _verifyServerConnection();
        if (serverConnected) {
          // Set user as online
          await AuthService.setOnlineStatus(true);
          await AuthService.updateOnlineStatusToServer(true);

          // Start periodic status updates
          AuthService.startPeriodicOnlineUpdates();

          // Navigate to home page
          if (context.mounted) {
            Navigator.pushReplacementNamed(context, '/home');
          }
        } else {
          debugPrint('Server connection failed, redirecting to login page');
          await initializeLocationAndSave(context);
          if (context.mounted) {
            Navigator.pushReplacementNamed(context, '/login');
          }
        }
      } else {
        // User is not logged in, continue with location check
        await initializeLocationAndSave(context);
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    } catch (e) {
      debugPrint('Error checking login status: $e');
      // Default to login page if there's an error
      await initializeLocationAndSave(context);
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  // Additional method to verify connection to backend before marking user as online
  Future<bool> _verifyServerConnection() async {
    try {
      // First check basic internet connectivity
      final hasInternet = await ApiService.hasInternetConnection();
      if (!hasInternet) {
        debugPrint('No internet connection detected');
        Fluttertoast.showToast(
          msg: 'No internet connection. Please check your network settings.',
          toastLength: Toast.LENGTH_LONG,
          backgroundColor: Colors.red,
        );
        return false;
      }

      // Then try pinging the server directly
      final serverReachable = await ApiService.pingServer();
      if (!serverReachable) {
        debugPrint('Server is unreachable');
        Fluttertoast.showToast(
          msg: 'Server is currently unavailable. Please try again later.',
          toastLength: Toast.LENGTH_LONG,
          backgroundColor: Colors.orange,
        );
        return false;
      }

      // Finally, try authenticated API call
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId == null || userId.isEmpty) {
        debugPrint('No user ID found in preferences');
        return false;
      }

      final response = await ApiService.get('user/profile');

      if (response.containsKey('error')) {
        debugPrint('Error verifying connection: ${response['error']}');
        return false;
      }

      // All checks passed, connection successful
      return true;
    } catch (e) {
      debugPrint('Failed to verify server connection: $e');
      return false;
    }
  }

  Future<void> initializeLocationAndSave(BuildContext context) async {
    try {
      Location location = Location();
      bool serviceEnabled;
      PermissionStatus permissionGranted;

      // Check if location service is enabled
      serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          Fluttertoast.showToast(
            msg: 'Location services are disabled. Please enable them.',
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
          return;
        }
      }

      // Check and request location permission
      permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied ||
          permissionGranted == PermissionStatus.deniedForever) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted &&
            permissionGranted != PermissionStatus.grantedLimited) {
          Fluttertoast.showToast(
            msg: 'Location permission denied. Unable to proceed.',
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
          return;
        }
      }

      // Get and save location data
      LocationData locationData = await location.getLocation();
      if (locationData.latitude != null && locationData.longitude != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble('latitude', locationData.latitude!);
        await prefs.setDouble('longitude', locationData.longitude!);
        debugPrint(
          'Location saved: (${locationData.latitude}, ${locationData.longitude})',
        );
      } else {
        Fluttertoast.showToast(
          msg: 'Failed to retrieve location data.',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      Fluttertoast.showToast(
        msg: 'Error accessing location: $e',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    var screenHeight = MediaQuery.of(context).size.height;
    var screenWidth = MediaQuery.of(context).size.width;
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: screenHeight,
        decoration: BoxDecoration(
          color: isDark ? Colors.blueGrey[900] : Colors.white,
        ),
        child: Stack(
          children: [
            Positioned(
              bottom: screenHeight * 0.1,
              left: screenWidth * 0.52,
              top: 0,
              right: 0,
              child: Image.asset('assets/images/img_3d_food_icon_by.png'),
            ),
            Positioned(
              bottom: screenHeight * 0.57,
              left: screenWidth * 0.09,
              top: screenHeight * 0.18,
              right: screenWidth * 0.09,
              child: Container(
                width: screenWidth * 0.8,
                height: screenHeight * 0.25,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white.withOpacity(0.1),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.05),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "FOODINI",
                      style: TextStyle(
                        fontSize: 32,
                        color: isDark ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Deliver your favorite food",
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Developed by Ben Younes Web",
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Image.asset('assets/images/logoBw.png', height: 20),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: screenWidth * 0.1,
              right: screenWidth * 0.1,
              child: Container(
                width: screenWidth * 0.8,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  color: Colors.white.withOpacity(0.1),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.05),
                    ],
                  ),
                ),
                child: TextButton(
                  onPressed: () async {
                    await checkLoginStatus(context);
                  },
                  child: const Text(
                    "Get Started",
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
