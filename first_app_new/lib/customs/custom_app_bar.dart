import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget {
  final IconButton iconButton;
  final MainAxisAlignment mainAxisAlignment;
  const CustomAppBar({
    super.key,
    required this.iconButton,
    required this.mainAxisAlignment,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Row(
        mainAxisAlignment: mainAxisAlignment,
        children: [
          iconButton,
        ],
      ),
    );
  }
}
