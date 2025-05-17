import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../helpers/navigation_helper.dart';
import '../debug_tools.dart';

class DebugScreen extends StatelessWidget {
  const DebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Print all environment variables for debugging
    final Map<String, String> envMap = dotenv.env;
    final baseUrl = dotenv.env['BASE_URL'] ?? 'Not found';
    final apiKey = dotenv.env['GRAPH_HOPPER_API_KEY'] ?? 'Not found';
    final wsUrl = dotenv.env['BASE_URL_WS'] ?? 'Not found';

    log("DotEnv values: $envMap");

    return Scaffold(
      appBar: AppBar(title: Text('Debug Environment')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('BASE_URL: $baseUrl', style: TextStyle(fontSize: 18)),
              SizedBox(height: 10),
              Text(
                'GRAPH_HOPPER_API_KEY: $apiKey',
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 10),
              Text('BASE_URL_WS: $wsUrl', style: TextStyle(fontSize: 18)),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => NavigationHelper.navigateToTestScreen(context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: Text(
                  'Run Fix Tests',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Back'),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DebugTestsScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: Text(
                  'API Diagnostics',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
