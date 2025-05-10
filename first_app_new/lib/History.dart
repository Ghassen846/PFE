import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> historyItems = [
      'Logged in at 2025-04-22 10:00',
      'Searched for "Flutter" at 2025-04-22 10:05',
      'Changed theme at 2025-04-22 10:10',
    ];

    return Scaffold(
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: historyItems.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              title: Text(historyItems[index]),
              leading: const Icon(Icons.history),
            ),
          );
        },
      ),
    );
  }
}
