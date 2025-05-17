
import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';

class CustomButtonBottomNavigationBar extends StatelessWidget {
  final IconData iconlyLight;
  final bool isActive;
  final VoidCallback onPressed;
  const CustomButtonBottomNavigationBar({
    super.key, required this.iconlyLight, required this.isActive, required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return isActive ? GlassmorphicContainer(
        borderGradient: LinearGradient(colors: [
          Colors.white.withOpacity(0.2),
    Colors.white.withOpacity(0.2)
        ]),
        blur: 100,
        border: 0,
        linearGradient: LinearGradient(colors: [
          Colors.white.withOpacity(0.3),
    Colors.white.withOpacity(0.3)
        ]),
        height: 50,
        width: MediaQuery.sizeOf(context).width * 0.2,
        borderRadius: 20,
        child: Center(
          child: IconButton(

              onPressed: onPressed,
              icon:  Icon(iconlyLight, color: Colors.white, size: 30)),
        ))
  :IconButton(

              onPressed: onPressed,
              icon:  Icon(iconlyLight, color: Colors.white, size: 30));
  }
}
