import 'package:flutter/material.dart';
import 'sizer_util.dart';

class ResponsiveWidget extends StatelessWidget {
  final Widget? mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveWidget({super.key, this.mobile, this.tablet, this.desktop});

  @override
  Widget build(BuildContext context) {
    // Mobile screen
    if (SizerUtil.deviceType == DeviceType.mobile) {
      return mobile ?? const SizedBox.shrink();
    }
    // Tablet screen
    else if (SizerUtil.deviceType == DeviceType.tablet) {
      return tablet ?? mobile ?? const SizedBox.shrink();
    }
    // Desktop screen
    else {
      return desktop ?? tablet ?? mobile ?? const SizedBox.shrink();
    }
  }
}
