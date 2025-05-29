import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiKeyReminderDialog extends StatelessWidget {
  const ApiKeyReminderDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final apiKey = dotenv.env['GRAPH_HOPPER_API_KEY'] ?? 'Not found';
    final isDefaultKey =
        apiKey == 'your_graphhopper_api_key_here' ||
        apiKey == 'default_key' ||
        apiKey.isEmpty;
    return AlertDialog(
      title: const Text('GraphHopper API Key Reminder'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isDefaultKey
                ? 'You need to set up a valid GraphHopper API key for better routing.'
                : 'GraphHopper API key is configured.',
            style: TextStyle(
              color: isDefaultKey ? Colors.red : Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '1. Sign up at graphhopper.com\n'
            '2. Get a free API key (or use a paid plan for more requests)\n'
            '3. Add it to your .env file as GRAPH_HOPPER_API_KEY=your_key_here\n'
            '4. Restart the app after updating the .env file',
          ),
          const SizedBox(height: 16),
          Text(
            'Current API key: ${isDefaultKey ? "Not configured" : apiKey.substring(0, 8) + "..." + apiKey.substring(apiKey.length - 4)}',
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 8),
          const Text(
            'Note: The app will use fallback routing with less accuracy until a valid API key is provided.',
            style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
          ),
          const SizedBox(height: 8),
          const Text(
            'If you\'ve added a valid API key but still see this message, try rebuilding the app from scratch.',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              fontSize: 12,
              color: Colors.red,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Dismiss'),
        ),
      ],
    );
  }
}
