import 'package:flutter/material.dart';
import 'package:first_app/menu.dart';

class SideMenuTile extends StatelessWidget {
  const SideMenuTile({
    super.key,
    required this.menu,
    required this.press,
    required this.isActive,
  });

  final Menu menu;
  final VoidCallback press;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 24),
          child: Divider(color: Colors.white24, height: 1),
        ),
        ListTile(
          onTap: press,
          leading: SizedBox(
            height: 34,
            width: 34,
            child: Icon(
              menu.icon,
              color: isActive ? Colors.white : Colors.white70,
              size: 24,
            ),
          ),
          title: Text(
            menu.title,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white70,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}
