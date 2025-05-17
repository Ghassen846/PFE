import 'package:first_app_new/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  // Check if user is already logged in and update online status
  Future<void> checkLoginStatus(BuildContext context) async {
    try {
      final bool isLoggedIn = await ApiService.isLoggedIn();

      if (isLoggedIn) {
        debugPrint('User already logged in, updating online status...');

        // Set user as online
        await ApiService.setOnlineStatus(true);
        await ApiService.updateOnlineStatusToServer(true);

        // Start periodic status updates
        ApiService.startPeriodicOnlineUpdates(); // Navigate to home page with footer
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/home');
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

  // Additional method for initializing location
  Future<void> initializeLocationAndSave(BuildContext context) async {
    try {
      final Location location = Location();
      bool serviceEnabled;
      PermissionStatus permissionGranted;

      // Check if location service is enabled
      serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          return;
        }
      }

      // Check if location permission is granted
      permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          return;
        }
      }

      // Get location
      final locationData = await location.getLocation();

      // Save location to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('latitude', locationData.latitude!);
      await prefs.setDouble('longitude', locationData.longitude!);

      debugPrint('Location initialized and saved');
    } catch (e) {
      debugPrint('Error initializing location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Start the login check after the build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkLoginStatus(context);
    });

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logoBw.png', width: 200, height: 200),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            const Text(
              'Loading...',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
