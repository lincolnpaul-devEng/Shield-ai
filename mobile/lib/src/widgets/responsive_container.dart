import 'package:flutter/material.dart';

/// Comprehensive responsive design system for Shield AI
/// Supports all Android phone screen sizes and orientations

/// Screen size breakpoints (Android focused)
class ScreenBreakpoints {
  static const double smallPhone = 360;    // Small phones (320-360dp)
  static const double normalPhone = 390;   // Normal phones (360-420dp)
  static const double largePhone = 480;    // Large phones (420-480dp)
  static const double tablet = 600;        // Small tablets
  static const double largeTablet = 840;   // Large tablets
}

/// Device type detection
enum DeviceType {
  smallPhone,    // < 360dp width
  normalPhone,   // 360-420dp width
  largePhone,    // 420-480dp width
  tablet,        // 480-840dp width
  largeTablet,   // > 840dp width
}

class DeviceInfo {
  final DeviceType type;
  final Size screenSize;
  final double devicePixelRatio;
  final double textScaleFactor;

  const DeviceInfo({
    required this.type,
    required this.screenSize,
    required this.devicePixelRatio,
    required this.textScaleFactor,
  });

  bool get isPhone => type == DeviceType.smallPhone ||
                     type == DeviceType.normalPhone ||
                     type == DeviceType.largePhone;

  bool get isTablet => type == DeviceType.tablet ||
                      type == DeviceType.largeTablet;

  bool get isSmallScreen => type == DeviceType.smallPhone;
  bool get isLargeScreen => type == DeviceType.largePhone ||
                           type == DeviceType.tablet ||
                           type == DeviceType.largeTablet;

  static DeviceInfo of(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;

    DeviceType type;
    if (width < ScreenBreakpoints.smallPhone) {
      type = DeviceType.smallPhone;
    } else if (width < ScreenBreakpoints.normalPhone) {
      type = DeviceType.normalPhone;
    } else if (width < ScreenBreakpoints.largePhone) {
      type = DeviceType.largePhone;
    } else if (width < ScreenBreakpoints.largeTablet) {
      type = DeviceType.tablet;
    } else {
      type = DeviceType.largeTablet;
    }

    return DeviceInfo(
      type: type,
      screenSize: mediaQuery.size,
      devicePixelRatio: mediaQuery.devicePixelRatio,
      textScaleFactor: mediaQuery.textScaler.scale(1.0),
    );
  }
}

/// Responsive container with adaptive sizing
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? maxWidth;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final device = DeviceInfo.of(context);

    return Container(
      margin: margin,
      padding: padding ?? _getAdaptivePadding(device),
      constraints: BoxConstraints(
        maxWidth: maxWidth ?? _getMaxWidth(device),
      ),
      child: child,
    );
  }

  EdgeInsets _getAdaptivePadding(DeviceInfo device) {
    switch (device.type) {
      case DeviceType.smallPhone:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
      case DeviceType.normalPhone:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
      case DeviceType.largePhone:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 16);
      case DeviceType.tablet:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 20);
      case DeviceType.largeTablet:
        return const EdgeInsets.symmetric(horizontal: 32, vertical: 24);
    }
  }

  double _getMaxWidth(DeviceInfo device) {
    if (device.isTablet) {
      return 480; // Cap tablet width for better UX
    }
    return double.infinity;
  }
}

/// Comprehensive responsive sizing utilities
class ResponsiveSize {
  /// Get horizontal scale factor based on screen width
  static double getHorizontalScale(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    const double baseWidth = 390; // Android normal phone width
    return (width / baseWidth).clamp(0.85, 1.3); // More conservative scaling
  }

  /// Get vertical scale factor based on screen height
  static double getVerticalScale(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    const double baseHeight = 844; // Standard Android height
    return (height / baseHeight).clamp(0.85, 1.2);
  }

  /// Responsive width with clamping
  static double responsiveWidth(BuildContext context, double width) {
    return width * getHorizontalScale(context);
  }

  /// Responsive height with clamping
  static double responsiveHeight(BuildContext context, double height) {
    return height * getVerticalScale(context);
  }

  /// Responsive font size (more conservative)
  static double responsiveFontSize(BuildContext context, double fontSize) {
    final scale = getHorizontalScale(context);
    return fontSize * scale.clamp(0.9, 1.1);
  }

  /// Get adaptive spacing based on screen size
  static double getSpacing(BuildContext context, Spacing size) {
    final device = DeviceInfo.of(context);
    final baseSpacing = _getBaseSpacing(size);

    if (device.isSmallScreen) {
      return baseSpacing * 0.8; // Smaller spacing on small screens
    } else if (device.isLargeScreen) {
      return baseSpacing * 1.2; // Larger spacing on big screens
    }
    return baseSpacing;
  }

  static double _getBaseSpacing(Spacing size) {
    switch (size) {
      case Spacing.xs: return 4;
      case Spacing.sm: return 8;
      case Spacing.md: return 16;
      case Spacing.lg: return 24;
      case Spacing.xl: return 32;
      case Spacing.xxl: return 48;
    }
  }
}

enum Spacing { xs, sm, md, lg, xl, xxl }

/// Responsive layout helpers
class ResponsiveLayout {
  /// Get cross axis count for grids based on screen size
  static int getGridCrossAxisCount(BuildContext context) {
    final device = DeviceInfo.of(context);

    switch (device.type) {
      case DeviceType.smallPhone:
        return 2;
      case DeviceType.normalPhone:
        return 2;
      case DeviceType.largePhone:
        return 3;
      case DeviceType.tablet:
        return 4;
      case DeviceType.largeTablet:
        return 5;
    }
  }

  /// Get main axis extent for grids
  static double getGridMainAxisExtent(BuildContext context) {
    final device = DeviceInfo.of(context);

    if (device.isSmallScreen) {
      return 120;
    } else if (device.isTablet) {
      return 160;
    }
    return 140;
  }

  /// Check if device is in landscape orientation
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Get adaptive app bar height
  static double getAppBarHeight(BuildContext context) {
    final device = DeviceInfo.of(context);
    final baseHeight = device.isTablet ? 64.0 : 56.0;
    return ResponsiveSize.responsiveHeight(context, baseHeight);
  }
}

/// Extension methods for easier responsive design
extension ResponsiveNumExtension on num {
  /// Convert to percentage of screen width
  double get wp => this * 0.01;

  /// Convert to percentage of screen height
  double get hp => this * 0.01;

  /// Convert to percentage of screen width (viewport width)
  double get vw => this * MediaQueryData.fromView(WidgetsBinding.instance.window).size.width * 0.01;

  /// Convert to percentage of screen height (viewport height)
  double get vh => this * MediaQueryData.fromView(WidgetsBinding.instance.window).size.height * 0.01;

  /// Responsive width
  double responsiveW(BuildContext context) =>
      ResponsiveSize.responsiveWidth(context, toDouble());

  /// Responsive height
  double responsiveH(BuildContext context) =>
      ResponsiveSize.responsiveHeight(context, toDouble());

  /// Responsive font size
  double responsiveSp(BuildContext context) =>
      ResponsiveSize.responsiveFontSize(context, toDouble());

  /// Get spacing value
  double spacing(BuildContext context, Spacing size) =>
      ResponsiveSize.getSpacing(context, size);
}

extension ResponsiveContextExtension on BuildContext {
  /// Get device info
  DeviceInfo get device => DeviceInfo.of(this);

  /// Check if device is phone
  bool get isPhone => device.isPhone;

  /// Check if device is tablet
  bool get isTablet => device.isTablet;

  /// Check if small screen
  bool get isSmallScreen => device.isSmallScreen;

  /// Check if large screen
  bool get isLargeScreen => device.isLargeScreen;

  /// Check if landscape
  bool get isLandscape => ResponsiveLayout.isLandscape(this);
}
