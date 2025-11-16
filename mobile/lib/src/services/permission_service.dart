import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Request SMS read permission for M-Pesa transaction sync
  static Future<bool> requestSmsPermission() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  /// Check if SMS permission is granted
  static Future<bool> hasSmsPermission() async {
    final status = await Permission.sms.status;
    return status.isGranted;
  }

  /// Request notification permission for fraud alerts
  static Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Check if notification permission is granted
  static Future<bool> hasNotificationPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// Request location permission for transaction location tracking
  static Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  /// Check if location permission is granted
  static Future<bool> hasLocationPermission() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }

  /// Request all required permissions at once
  static Future<Map<Permission, PermissionStatus>> requestAllPermissions() async {
    final permissions = [
      Permission.sms,
      Permission.notification,
      Permission.location,
    ];

    final statuses = await permissions.request();
    return statuses;
  }

  /// Check status of all required permissions
  static Future<Map<String, bool>> checkAllPermissions() async {
    final smsGranted = await hasSmsPermission();
    final notificationGranted = await hasNotificationPermission();
    final locationGranted = await hasLocationPermission();

    return {
      'sms': smsGranted,
      'notification': notificationGranted,
      'location': locationGranted,
    };
  }

  /// Open app settings for manual permission management
  static Future<bool> openSettings() async {
    return await openAppSettings();
  }

  /// Check if any permission is permanently denied
  static Future<bool> hasPermanentlyDeniedPermissions() async {
    final smsStatus = await Permission.sms.status;
    final notificationStatus = await Permission.notification.status;
    final locationStatus = await Permission.location.status;

    return smsStatus.isPermanentlyDenied ||
           notificationStatus.isPermanentlyDenied ||
           locationStatus.isPermanentlyDenied;
  }
}