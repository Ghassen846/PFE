import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> notifications = [
      'New update available!',
      'Your settings were changed.',
      'Welcome to the app!',
    ];

    return Scaffold(
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              title: Text(notifications[index]),
              leading: const Icon(Icons.notifications),
            ),
          );
        },
      ),
    );
  }
}
