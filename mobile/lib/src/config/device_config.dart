import 'package:flutter/material.dart';

/// Device-specific configuration for optimal UX across Android phones
class DeviceConfig {
  static const Map<DeviceType, DeviceSpec> _deviceSpecs = {
    DeviceType.smallPhone: DeviceSpec(
      name: 'Small Phone',
      minWidth: 320,
      maxWidth: 360,
      recommendedFontSize: 14,
      buttonHeight: 44,
      cardPadding: 12,
      iconSize: 20,
      gridColumns: 2,
    ),
    DeviceType.normalPhone: DeviceSpec(
      name: 'Normal Phone',
      minWidth: 360,
      maxWidth: 420,
      recommendedFontSize: 16,
      buttonHeight: 48,
      cardPadding: 16,
      iconSize: 24,
      gridColumns: 2,
    ),
    DeviceType.largePhone: DeviceSpec(
      name: 'Large Phone',
      minWidth: 420,
      maxWidth: 480,
      recommendedFontSize: 18,
      buttonHeight: 52,
      cardPadding: 20,
      iconSize: 28,
      gridColumns: 3,
    ),
    DeviceType.smallTablet: DeviceSpec(
      name: 'Small Tablet',
      minWidth: 480,
      maxWidth: 720,
      recommendedFontSize: 18,
      buttonHeight: 56,
      cardPadding: 24,
      iconSize: 32,
      gridColumns: 4,
    ),
    DeviceType.largeTablet: DeviceSpec(
      name: 'Large Tablet',
      minWidth: 720,
      maxWidth: double.infinity,
      recommendedFontSize: 20,
      buttonHeight: 60,
      cardPadding: 28,
      iconSize: 36,
      gridColumns: 5,
    ),
  };

  /// Get device specification based on screen width
  static DeviceSpec getDeviceSpec(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return getDeviceSpecByWidth(width);
  }

  /// Get device specification by width
  static DeviceSpec getDeviceSpecByWidth(double width) {
    for (final entry in _deviceSpecs.entries) {
      if (width >= entry.value.minWidth && width < entry.value.maxWidth) {
        return entry.value;
      }
    }
    return _deviceSpecs[DeviceType.normalPhone]!;
  }

  /// Get device type
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < 360) return DeviceType.smallPhone;
    if (width < 420) return DeviceType.normalPhone;
    if (width < 480) return DeviceType.largePhone;
    if (width < 720) return DeviceType.smallTablet;
    return DeviceType.largeTablet;
  }

  /// Check if device is considered small
  static bool isSmallDevice(BuildContext context) {
    final type = getDeviceType(context);
    return type == DeviceType.smallPhone;
  }

  /// Check if device is considered large
  static bool isLargeDevice(BuildContext context) {
    final type = getDeviceType(context);
    return type == DeviceType.largePhone ||
           type == DeviceType.smallTablet ||
           type == DeviceType.largeTablet;
  }

  /// Get optimal text theme for device
  static TextTheme getOptimalTextTheme(BuildContext context) {
    final spec = getDeviceSpec(context);
    final baseTheme = Theme.of(context).textTheme;

    return baseTheme.copyWith(
      headlineLarge: baseTheme.headlineLarge?.copyWith(fontSize: spec.recommendedFontSize + 8),
      headlineMedium: baseTheme.headlineMedium?.copyWith(fontSize: spec.recommendedFontSize + 6),
      headlineSmall: baseTheme.headlineSmall?.copyWith(fontSize: spec.recommendedFontSize + 4),
      titleLarge: baseTheme.titleLarge?.copyWith(fontSize: spec.recommendedFontSize + 2),
      titleMedium: baseTheme.titleMedium?.copyWith(fontSize: spec.recommendedFontSize),
      titleSmall: baseTheme.titleSmall?.copyWith(fontSize: spec.recommendedFontSize - 2),
      bodyLarge: baseTheme.bodyLarge?.copyWith(fontSize: spec.recommendedFontSize),
      bodyMedium: baseTheme.bodyMedium?.copyWith(fontSize: spec.recommendedFontSize - 1),
      bodySmall: baseTheme.bodySmall?.copyWith(fontSize: spec.recommendedFontSize - 2),
      labelLarge: baseTheme.labelLarge?.copyWith(fontSize: spec.recommendedFontSize),
      labelMedium: baseTheme.labelMedium?.copyWith(fontSize: spec.recommendedFontSize - 1),
      labelSmall: baseTheme.labelSmall?.copyWith(fontSize: spec.recommendedFontSize - 2),
    );
  }

  /// Get optimal button theme for device
  static ButtonThemeData getOptimalButtonTheme(BuildContext context) {
    final spec = getDeviceSpec(context);

    return ButtonThemeData(
      height: spec.buttonHeight,
      minWidth: spec.buttonHeight * 2,
      buttonColor: Theme.of(context).primaryColor,
      textTheme: ButtonTextTheme.primary,
    );
  }

  /// Get optimal icon theme for device
  static IconThemeData getOptimalIconTheme(BuildContext context) {
    final spec = getDeviceSpec(context);

    return IconThemeData(
      size: spec.iconSize,
      color: Theme.of(context).iconTheme.color,
    );
  }

  /// Get optimal card theme for device
  static CardTheme getOptimalCardTheme(BuildContext context) {
    final spec = getDeviceSpec(context);

    return CardTheme(
      margin: EdgeInsets.all(spec.cardPadding * 0.5),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spec.cardPadding * 0.25),
      ),
    );
  }

  /// Get optimal app bar theme for device
  static AppBarTheme getOptimalAppBarTheme(BuildContext context) {
    final spec = getDeviceSpec(context);

    return AppBarTheme(
      toolbarHeight: spec.buttonHeight + 4,
      titleTextStyle: TextStyle(
        fontSize: spec.recommendedFontSize + 2,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(size: spec.iconSize),
      actionsIconTheme: IconThemeData(size: spec.iconSize),
    );
  }
}

enum DeviceType {
  smallPhone,    // < 360dp
  normalPhone,   // 360-420dp
  largePhone,    // 420-480dp
  smallTablet,   // 480-720dp
  largeTablet,   // > 720dp
}

class DeviceSpec {
  final String name;
  final double minWidth;
  final double maxWidth;
  final double recommendedFontSize;
  final double buttonHeight;
  final double cardPadding;
  final double iconSize;
  final int gridColumns;

  const DeviceSpec({
    required this.name,
    required this.minWidth,
    required this.maxWidth,
    required this.recommendedFontSize,
    required this.buttonHeight,
    required this.cardPadding,
    required this.iconSize,
    required this.gridColumns,
  });

  @override
  String toString() => '$name (${minWidth.toInt()}-${maxWidth == double.infinity ? '+' : maxWidth.toInt()}dp)';
}
