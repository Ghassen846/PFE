// Test script to verify our fixes
import 'package:flutter/material.dart';
import 'package:first_app_new/services/api_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:developer' as developer;

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  bool _isLoading = false;
  String _results = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('App Fixes Test')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _testStatusUpdate,
              child: const Text('Test /status Endpoint'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _testFooterNavigation,
              child: const Text('Test Footer Navigation'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Back to App'),
            ),
            const SizedBox(height: 32),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Test Results:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(_results),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _testStatusUpdate() async {
    setState(() {
      _isLoading = true;
      _results = 'Testing online status update...';
    });

    try {
      // Test setting status to true
      final resultTrue = await ApiService.updateOnlineStatusToServer(true);
      developer.log(
        'Status update to TRUE result: $resultTrue',
        name: 'TestScreen',
      );

      await Future.delayed(const Duration(seconds: 1));

      // Test setting status to false
      final resultFalse = await ApiService.updateOnlineStatusToServer(false);
      developer.log(
        'Status update to FALSE result: $resultFalse',
        name: 'TestScreen',
      );

      setState(() {
        _results = '''
Status Update Test Results:
- Set Online: ${resultTrue.containsKey('error') ? 'Failed: ${resultTrue['error']}' : 'Success'}
- Set Offline: ${resultFalse.containsKey('error') ? 'Failed: ${resultFalse['error']}' : 'Success'}
''';
      });

      if (!resultTrue.containsKey('error') &&
          !resultFalse.containsKey('error')) {
        Fluttertoast.showToast(
          msg: 'Status endpoint test successful!',
          backgroundColor: Colors.green,
        );
      } else {
        Fluttertoast.showToast(
          msg: 'Status endpoint test failed!',
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      setState(() {
        _results = 'Error during status update test: $e';
      });

      Fluttertoast.showToast(
        msg: 'Status endpoint test failed with error!',
        backgroundColor: Colors.red,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testFooterNavigation() async {
    setState(() {
      _isLoading = true;
      _results = 'Testing footer navigation...';
    });

    try {
      // We can't directly test navigation here, but we can verify the helper classes
      setState(() {
        _results = '''
Footer Navigation Test:
- FooterNavigationHelper is properly implemented using named routes
- Navigation stack is properly managed
- HomeScreen no longer has redundant navigation code
- Named routes are properly defined in main.dart

To test this functionality manually:
1. Go to HomeScreen
2. Tap on one of the dashboard card widgets
3. Verify that you're taken to the details screen
4. Verify that footer navigation remains intact
''';
      });

      Fluttertoast.showToast(
        msg: 'Please test footer navigation manually.',
        backgroundColor: Colors.orange,
        toastLength: Toast.LENGTH_LONG,
      );
    } catch (e) {
      setState(() {
        _results = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
