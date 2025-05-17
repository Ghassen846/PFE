import 'package:flutter/material.dart';
import 'package:first_app_new/helpers/theme/theme.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(color: ThemeHelper.greenColor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: AssetImage(
                    'assets/images/img_3d_food_icon_by_279x292.png',
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Delivery App',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
                Text(
                  'Menu',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to home
            },
          ),
          ListTile(
            leading: const Icon(Icons.delivery_dining),
            title: const Text('My Deliveries'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to deliveries
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('History'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to history
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_circle),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to profile
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to settings
            },
          ),
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text('Logout'),
            onTap: () {
              Navigator.pop(context);
              // Logout logic
            },
          ),
        ],
      ),
    );
  }
}
