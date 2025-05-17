import 'package:flutter/material.dart';
import 'package:first_app_new/services/api_service.dart';
import 'package:first_app_new/services/profile_update_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:developer' as developer;

class DebugUtils {
  /// Test delivery stats endpoint
  static Future<Map<String, dynamic>> testDeliveryStats() async {
    try {
      final userId = await ApiService.getUserId();
      if (userId == null) {
        throw Exception('User ID is null');
      }

      developer.log(
        'Testing delivery stats for user ID: $userId',
        name: 'DebugUtils',
      );

      // Make the API call
      final response = await ApiService.get(
        'delivery/stats',
        queryParams: {'userId': userId},
      );

      developer.log('Delivery stats response: $response', name: 'DebugUtils');
      return response;
    } catch (e) {
      developer.log('Error testing delivery stats: $e', name: 'DebugUtils');
      return {'error': e.toString()};
    }
  }

  /// Test user profile update
  static Future<Map<String, dynamic>> testProfileUpdate() async {
    try {
      // First, get the current profile
      final currentProfile = await ProfileUpdateService.getUserProfile();

      // Then update with the same data (no real changes)
      final response = await ProfileUpdateService.updateProfile(
        firstName: currentProfile['firstName'] ?? '',
        name: currentProfile['name'] ?? '',
        email: currentProfile['email'] ?? '',
        phone: currentProfile['phone'] ?? '',
        username: currentProfile['username'] ?? '',
      );

      developer.log('Profile update response: $response', name: 'DebugUtils');
      return response;
    } catch (e) {
      developer.log('Error testing profile update: $e', name: 'DebugUtils');
      return {'error': e.toString()};
    }
  }

  /// Test password change
  static Future<Map<String, dynamic>> testPasswordChange(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      // Try changing the password
      final success = await ProfileUpdateService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      developer.log('Password change success: $success', name: 'DebugUtils');
      return {'success': success};
    } catch (e) {
      developer.log('Error testing password change: $e', name: 'DebugUtils');
      return {'error': e.toString()};
    }
  }

  /// Test online status update
  static Future<Map<String, dynamic>> testOnlineStatus(bool isOnline) async {
    try {
      final response = await ApiService.updateOnlineStatusToServer(isOnline);
      developer.log(
        'Online status update response: $response',
        name: 'DebugUtils',
      );
      return response;
    } catch (e) {
      developer.log(
        'Error testing online status update: $e',
        name: 'DebugUtils',
      );
      return {'error': e.toString()};
    }
  }

  /// Show a debug toast message
  static void showDebugToast(String message, {bool error = false}) {
    Fluttertoast.showToast(
      msg: message,
      backgroundColor: error ? Colors.red : Colors.blue,
      toastLength: Toast.LENGTH_LONG,
    );
  }
}

// Simple UI for testing
class DebugTestsScreen extends StatefulWidget {
  const DebugTestsScreen({super.key});

  @override
  _DebugTestsScreenState createState() => _DebugTestsScreenState();
}

class _DebugTestsScreenState extends State<DebugTestsScreen> {
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  String _results = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _runDeliveryStatsTest() async {
    setState(() {
      _isLoading = true;
      _results = 'Testing delivery stats...';
    });

    try {
      final result = await DebugUtils.testDeliveryStats();
      setState(() {
        _results = 'Delivery Stats Test:\n${result.toString()}';
      });

      DebugUtils.showDebugToast(
        result.containsKey('error')
            ? 'Error: ${result['error']}'
            : 'Test successful!',
        error: result.containsKey('error'),
      );
    } catch (e) {
      setState(() {
        _results = 'Error: $e';
      });
      DebugUtils.showDebugToast('Test failed: $e', error: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _runProfileUpdateTest() async {
    setState(() {
      _isLoading = true;
      _results = 'Testing profile update...';
    });

    try {
      final result = await DebugUtils.testProfileUpdate();
      setState(() {
        _results = 'Profile Update Test:\n${result.toString()}';
      });

      DebugUtils.showDebugToast(
        result.containsKey('error')
            ? 'Error: ${result['error']}'
            : 'Test successful!',
        error: result.containsKey('error'),
      );
    } catch (e) {
      setState(() {
        _results = 'Error: $e';
      });
      DebugUtils.showDebugToast('Test failed: $e', error: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _runPasswordChangeTest() async {
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty) {
      DebugUtils.showDebugToast('Please enter both passwords', error: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _results = 'Testing password change...';
    });

    try {
      final result = await DebugUtils.testPasswordChange(
        _currentPasswordController.text,
        _newPasswordController.text,
      );

      setState(() {
        _results = 'Password Change Test:\n${result.toString()}';
      });

      DebugUtils.showDebugToast(
        result.containsKey('error')
            ? 'Error: ${result['error']}'
            : 'Test successful!',
        error: result.containsKey('error'),
      );
    } catch (e) {
      setState(() {
        _results = 'Error: $e';
      });
      DebugUtils.showDebugToast('Test failed: $e', error: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _runOnlineStatusTest() async {
    setState(() {
      _isLoading = true;
      _results = 'Testing online status update...';
    });

    try {
      final result = await DebugUtils.testOnlineStatus(true);
      setState(() {
        _results = 'Online Status Test:\n${result.toString()}';
      });

      DebugUtils.showDebugToast(
        result.containsKey('error')
            ? 'Error: ${result['error']}'
            : 'Test successful!',
        error: result.containsKey('error'),
      );
    } catch (e) {
      setState(() {
        _results = 'Error: $e';
      });
      DebugUtils.showDebugToast('Test failed: $e', error: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Debug Tests')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _runDeliveryStatsTest,
              child: const Text('Test Delivery Stats'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isLoading ? null : _runProfileUpdateTest,
              child: const Text('Test Profile Update'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isLoading ? null : _runOnlineStatusTest,
              child: const Text('Test Online Status'),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
            const Text(
              'Test Password Change',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _currentPasswordController,
              decoration: const InputDecoration(labelText: 'Current Password'),
              obscureText: true,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _newPasswordController,
              decoration: const InputDecoration(labelText: 'New Password'),
              obscureText: true,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isLoading ? null : _runPasswordChangeTest,
              child: const Text('Test Password Change'),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),
            const Text(
              'Results:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(5),
              ),
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Text(_results),
            ),
          ],
        ),
      ),
    );
  }
}
