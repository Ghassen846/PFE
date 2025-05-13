import 'package:first_app_new/menu.dart';
import 'package:first_app_new/side_menu_title.dart';
import 'package:flutter/material.dart';

class SideMenu extends StatefulWidget {
  final Function(int) onMenuSelected;

  const SideMenu({super.key, required this.onMenuSelected});

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  Menu? _selectedMenu;
  int _currentIndex = 0;
  bool _isProcessing = false;

  void _handleMenuSelection(Menu menu, int index) async {
    if (_isProcessing) return;
    debugPrint('Handling menu selection: ${menu.title}, index: $index');
    setState(() {
      _isProcessing = true;
      _selectedMenu = menu;
      _currentIndex = index;
    });

    widget.onMenuSelected(index);
    Navigator.pop(context); // Close the drawer

    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: 288,
        height: double.infinity,
        color: Colors.blue,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 24, top: 32, bottom: 16),
                child: Text(
                  "Menu".toUpperCase(),
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium!.copyWith(color: Colors.white70),
                ),
              ),
              ...sidebarMenus.asMap().entries.map((entry) {
                final index = entry.key;
                final menu = entry.value;
                debugPrint('Building menu: ${menu.title}, index: $index');
                return SideMenuTile(
                  menu: menu,
                  isActive: _selectedMenu == menu,
                  press: () => _handleMenuSelection(menu, index),
                );
              }),
              Padding(
                padding: const EdgeInsets.only(left: 24, top: 32, bottom: 16),
                child: Text(
                  "Support".toUpperCase(),
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium!.copyWith(color: Colors.white70),
                ),
              ),
              ...sidebarMenus2.asMap().entries.map((entry) {
                final index = entry.key + sidebarMenus.length;
                final menu = entry.value;
                debugPrint(
                  'Building support menu: ${menu.title}, index: $index',
                );
                return SideMenuTile(
                  menu: menu,
                  isActive: _selectedMenu == menu,
                  press: () => _handleMenuSelection(menu, index),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
