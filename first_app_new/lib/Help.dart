import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(
            title: Text('How to use the app?'),
            subtitle: Text('Tap the menu to navigate between screens.'),
          ),
          ListTile(
            title: Text('How to enable dark mode?'),
            subtitle: Text('Use the sun/moon icon in the app bar.'),
          ),
          ListTile(
            title: Text('Contact Support'),
            subtitle: Text('Email: support@example.com'),
          ),
        ],
      ),
    );
  }
}
