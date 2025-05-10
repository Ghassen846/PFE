import 'package:flutter/material.dart';

class Menu {
  final String title;
  final IconData icon;

  Menu({required this.title, required this.icon});
}

List<Menu> sidebarMenus = [
  Menu(title: "Home", icon: Icons.home),
  Menu(title: "Search", icon: Icons.search),
  Menu(title: "History", icon: Icons.history),
  Menu(title: "Settings", icon: Icons.settings),
];

List<Menu> sidebarMenus2 = [
  Menu(title: "Help", icon: Icons.help),
  Menu(title: "Notifications", icon: Icons.notifications),
];

List<Menu> bottomNavItems = [
  Menu(title: "Home", icon: Icons.home),
  Menu(title: "Search", icon: Icons.search),
  Menu(title: "History", icon: Icons.history),
  Menu(title: "Settings", icon: Icons.settings),
];
