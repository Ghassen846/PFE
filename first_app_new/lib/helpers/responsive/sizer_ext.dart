import 'sizer_util.dart';

// Extension for responsive sizes using Sizer package
extension SizerExt on num {
  // Get width based on screen size
  double get w => SizerUtil.w * this;

  // Get height based on screen size
  double get h => SizerUtil.h * this;

  // Get sp (scalable pixels) based on screen size
  double get sp => SizerUtil.w * this / 100;

  // Get percentage of screen width
  double get wp {
    return SizerUtil.width * this / 100;
  }

  // Get percentage of screen height
  double get hp {
    return SizerUtil.height * this / 100;
  }

  // For tablets and iPads
  double get hsp {
    if (SizerUtil.deviceType == DeviceType.tablet) {
      return SizerUtil.width * this / 100;
    } else {
      return SizerUtil.height * this / 100;
    }
  }

  // For tablets and iPads
  double get wsp {
    if (SizerUtil.deviceType == DeviceType.tablet) {
      return SizerUtil.height * this / 100;
    } else {
      return SizerUtil.width * this / 100;
    }
  }
}
