import 'package:flutter/material.dart';
import 'dart:io';

import '../config/device_config.dart';

/// Debug overlay to display comprehensive device information for troubleshooting UI issues
/// Remove this in production builds
class DebugOverlay extends StatelessWidget {
  final Widget child;

  const DebugOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Only show in debug mode
    if (!Platform.isAndroid || !const bool.fromEnvironment('dart.vm.product')) {
      return child;
    }

    final mediaQuery = MediaQuery.of(context);
    final deviceType = DeviceConfig.getDeviceType(context);
    final deviceSpec = DeviceConfig.getDeviceSpec(context);

    return Stack(
      children: [
        child,
        // Debug info overlay (top-right corner)
        Positioned(
          top: 40,
          right: 10,
          child: Container(
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(maxWidth: 200),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '📱 ${deviceSpec.name}',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Screen: ${mediaQuery.size.width.toInt()}×${mediaQuery.size.height.toInt()}',
                  style: const TextStyle(color: Colors.white, fontSize: 9),
                ),
                Text(
                  'DPR: ${mediaQuery.devicePixelRatio.toStringAsFixed(1)}',
                  style: const TextStyle(color: Colors.white, fontSize: 9),
                ),
                Text(
                  'Text: ${mediaQuery.textScaler.scale(1.0).toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white, fontSize: 9),
                ),
                Text(
                  'Safe: T${mediaQuery.padding.top.toInt()} B${mediaQuery.padding.bottom.toInt()}',
                  style: const TextStyle(color: Colors.white, fontSize: 9),
                ),
                Text(
                  'Grid: ${deviceSpec.gridColumns} cols',
                  style: const TextStyle(color: Colors.white, fontSize: 9),
                ),
                Text(
                  'Font: ${deviceSpec.recommendedFontSize.toInt()}sp',
                  style: const TextStyle(color: Colors.white, fontSize: 9),
                ),
                // Status indicators
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      mediaQuery.size.width < 360 ? Icons.warning : Icons.check_circle,
                      color: mediaQuery.size.width < 360 ? Colors.orange : Colors.green,
                      size: 10,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      mediaQuery.size.width < 360 ? 'Small Screen' : 'Responsive',
                      style: const TextStyle(color: Colors.white, fontSize: 8),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Performance warning for very small screens
        if (mediaQuery.size.width < 360)
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '⚠️ Screen width < 360dp\nSome content may be cramped\nConsider using a larger device for optimal experience',
                style: TextStyle(color: Colors.white, fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
