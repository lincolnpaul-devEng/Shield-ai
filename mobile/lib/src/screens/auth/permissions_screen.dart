 import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  final Map<PermissionType, PermissionStatus> _permissionStatuses = {};
  final Map<PermissionType, bool> _isRequesting = {};
  bool _isCheckingAll = false;

  @override
  void initState() {
    super.initState();
    _checkAllPermissions();
  }

  Future<void> _checkAllPermissions() async {
    setState(() => _isCheckingAll = true);

    for (final permissionType in PermissionType.values) {
      await _checkPermissionStatus(permissionType);
    }

    setState(() => _isCheckingAll = false);
  }

  Future<void> _checkPermissionStatus(PermissionType permissionType) async {
    final permission = _getPermission(permissionType);
    final status = await permission.status;
    setState(() {
      _permissionStatuses[permissionType] = status;
    });
  }

  Future<void> _requestPermission(PermissionType permissionType) async {
    setState(() => _isRequesting[permissionType] = true);

    final permission = _getPermission(permissionType);
    final status = await permission.request();

    setState(() {
      _permissionStatuses[permissionType] = status;
      _isRequesting[permissionType] = false;
    });
  }

  Permission _getPermission(PermissionType type) {
    switch (type) {
      case PermissionType.sms:
        return Permission.sms;
      case PermissionType.notifications:
        return Permission.notification;
      case PermissionType.location:
        return Permission.location;
      case PermissionType.phone:
        return Permission.phone;
    }
  }

  bool get _allCriticalPermissionsGranted {
    return _permissionStatuses[PermissionType.sms]?.isGranted == true &&
           _permissionStatuses[PermissionType.notifications]?.isGranted == true;
  }

  void _continueToDashboard() {
    Navigator.pushReplacementNamed(context, '/main');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enable Protection'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        automaticallyImplyLeading: false, // No back button
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Shield AI Header
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.security,
                  size: 50,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Complete Your Protection Setup',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              Text(
                'To provide the best fraud protection for your M-Pesa transactions, Shield AI needs access to some features on your device.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Permission Cards
              ...PermissionType.values.map((permissionType) =>
                _PermissionCard(
                  permissionType: permissionType,
                  status: _permissionStatuses[permissionType],
                  isRequesting: _isRequesting[permissionType] ?? false,
                  onRequest: () => _requestPermission(permissionType),
                ),
              ),

              const SizedBox(height: 32),

              // Progress Indicator
              if (_isCheckingAll) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Checking permissions...',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],

              const SizedBox(height: 24),

              // Continue Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _allCriticalPermissionsGranted ? _continueToDashboard : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _allCriticalPermissionsGranted
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    foregroundColor: _allCriticalPermissionsGranted
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _allCriticalPermissionsGranted
                        ? 'Start Protecting My Account'
                        : 'Grant Required Permissions First',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Skip Option (only if not all critical permissions granted)
              if (!_allCriticalPermissionsGranted) ...[
                TextButton(
                  onPressed: _continueToDashboard,
                  child: Text(
                    'Continue with Limited Protection',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Some fraud detection features will be limited without these permissions.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 32),

              // Privacy Notice
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.privacy_tip,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Your Privacy Matters',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Shield AI only uses these permissions to analyze your transaction patterns and protect you from fraud. Your data is processed locally and never stored on our servers.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum PermissionType {
  sms,
  notifications,
  location,
  phone,
}

extension PermissionTypeExtension on PermissionType {
  String get title {
    switch (this) {
      case PermissionType.sms:
        return 'SMS Access';
      case PermissionType.notifications:
        return 'Notifications';
      case PermissionType.location:
        return 'Location Access';
      case PermissionType.phone:
        return 'Phone State';
    }
  }

  String get description {
    switch (this) {
      case PermissionType.sms:
        return 'Read M-Pesa transaction messages to learn your spending patterns and detect unusual activity.';
      case PermissionType.notifications:
        return 'Send instant alerts when suspicious transactions are detected, allowing you to block them immediately.';
      case PermissionType.location:
        return 'Track transaction locations to identify unusual geographic patterns that may indicate fraud.';
      case PermissionType.phone:
        return 'Access basic phone information to associate transactions with your device.';
    }
  }

  String get fraudProtectionBenefit {
    switch (this) {
      case PermissionType.sms:
        return 'Detects amount anomalies, time patterns, and recipient changes by analyzing your M-Pesa SMS history.';
      case PermissionType.notifications:
        return 'Provides real-time alerts for high-risk transactions, giving you immediate action options.';
      case PermissionType.location:
        return 'Identifies transactions from unusual locations that differ from your normal geographic patterns.';
      case PermissionType.phone:
        return 'Ensures transaction analysis is tied to your specific device for accurate protection.';
    }
  }

  IconData get icon {
    switch (this) {
      case PermissionType.sms:
        return Icons.sms;
      case PermissionType.notifications:
        return Icons.notifications;
      case PermissionType.location:
        return Icons.location_on;
      case PermissionType.phone:
        return Icons.phone_android;
    }
  }

  bool get isCritical {
    return this == PermissionType.sms || this == PermissionType.notifications;
  }
}

class _PermissionCard extends StatelessWidget {
  final PermissionType permissionType;
  final PermissionStatus? status;
  final bool isRequesting;
  final VoidCallback onRequest;

  const _PermissionCard({
    required this.permissionType,
    required this.status,
    required this.isRequesting,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    final isGranted = status?.isGranted == true;
    final isDenied = status?.isDenied == true;
    final isPermanentlyDenied = status?.isPermanentlyDenied == true;

    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (isGranted) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Granted';
    } else if (isPermanentlyDenied) {
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
      statusText = 'Permanently Denied';
    } else if (isDenied) {
      statusColor = Colors.orange;
      statusIcon = Icons.warning;
      statusText = 'Denied';
    } else {
      statusColor = Colors.grey;
      statusIcon = Icons.help_outline;
      statusText = 'Not Requested';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    permissionType.icon,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        permissionType.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(statusIcon, color: statusColor, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (permissionType.isCritical) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Required',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (!isGranted && !isRequesting) ...[
                  ElevatedButton(
                    onPressed: onRequest,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text('Grant'),
                  ),
                ] else if (isRequesting) ...[
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              permissionType.description,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 8),

            // Fraud protection benefit
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.shield,
                    color: Theme.of(context).colorScheme.secondary,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      permissionType.fraudProtectionBenefit,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Settings hint for permanently denied
            if (isPermanentlyDenied) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.settings,
                      color: Theme.of(context).colorScheme.error,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Go to device settings to enable this permission.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => openAppSettings(),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                      ),
                      child: Text(
                        'Open Settings',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}