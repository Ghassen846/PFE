import 'package:flutter/material.dart';

// DeviceType enum to categorize devices
enum DeviceType {
  mobile,
  tablet,
  desktop
}

// SizerUtil implementation for backward compatibility
class SizerUtil {
  static late Size _screenSize;
  static late double _pixelRatio;
  static late DeviceType _deviceType;
  static late double _statusBarHeight;
  static late double _bottomBarHeight;
  static late double _appBarHeight;
  static late bool _isLandscape;

  // Static values for width and height percentages
  static late double width;
  static late double height;
  
  // Percentage values
  static late double w;
  static late double h;

  // Initialize SizerUtil with BuildContext
  static void init(BuildContext context) {
    MediaQueryData mediaQuery = MediaQuery.of(context);
    _screenSize = mediaQuery.size;
    _pixelRatio = mediaQuery.devicePixelRatio;
    _statusBarHeight = mediaQuery.padding.top;
    _bottomBarHeight = mediaQuery.padding.bottom;
    _appBarHeight = AppBar().preferredSize.height;
    _isLandscape = _screenSize.width > _screenSize.height;
    
    width = _screenSize.width;
    height = _screenSize.height;
    
    // Set percentage values
    w = _screenSize.width / 100;
    h = _screenSize.height / 100;

    // Set device type based on width
    if (_screenSize.width > 1200) {
      _deviceType = DeviceType.desktop;
    } else if (_screenSize.width >= 600) {
      _deviceType = DeviceType.tablet;
    } else {
      _deviceType = DeviceType.mobile;
    }
  }

  // Getters for the private fields
  static double get screenWidth => _screenSize.width;
  static double get screenHeight => _screenSize.height;
  static Size get screenSize => _screenSize;
  static double get pixelRatio => _pixelRatio;
  static double get statusBarHeight => _statusBarHeight;
  static double get bottomBarHeight => _bottomBarHeight;
  static double get appBarHeight => _appBarHeight;
  static bool get isLandscape => _isLandscape;
  static DeviceType get deviceType => _deviceType;
}
