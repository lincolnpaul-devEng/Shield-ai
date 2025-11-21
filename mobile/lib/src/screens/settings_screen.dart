import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/demo_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Feature toggles (stubbed; persist with shared_preferences or provider)
  bool _realtimeAlerts = true;
  bool _backgroundMonitoring = false;

  // Permissions status (stubbed; wire to permission_handler/geolocator/notifications)
  bool _smsGranted = false;
  bool _notificationsGranted = true;
  bool _locationGranted = false;

  // Profile fields (stubbed)
  final _phoneController = TextEditingController();
  final _limitController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final demoProvider = context.watch<DemoProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Permissions', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _PermissionTile(
            title: 'SMS Read Access',
            granted: _smsGranted,
            explanation:
                'We use SMS (e.g., M-Pesa messages) to learn your transaction patterns and detect fraud faster. Your data stays on-device or is encrypted for protection.',
            onRequest: () async {
              // TODO: Request READ_SMS (Android) via permission_handler/telephony
              setState(() => _smsGranted = true);
            },
          ),
          _PermissionTile(
            title: 'Notifications',
            granted: _notificationsGranted,
            explanation:
                'Notifications are used to alert you immediately if suspicious activity is detected, allowing you to block or allow a transaction quickly.',
            onRequest: () async {
              // TODO: Request notification permission (iOS) or ensure channel (Android)
              setState(() => _notificationsGranted = true);
            },
          ),
          _PermissionTile(
            title: 'Location Access',
            granted: _locationGranted,
            explanation:
                'Location helps detect unusual transaction locations, a common sign of fraud. We request precise location only when needed.',
            onRequest: () async {
              // TODO: Request location via geolocator
              setState(() => _locationGranted = true);
            },
          ),
          const Divider(height: 32),

          Text('M-Pesa Sync', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.sync),
                      const SizedBox(width: 8),
                      Text('Transaction Synchronization',
                          style: Theme.of(context).textTheme.titleSmall),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Automatically sync your M-Pesa transactions to improve fraud detection accuracy. '
                    'This helps Shield AI learn your spending patterns and detect unusual activity.',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            // TODO: Implement manual sync
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Syncing M-Pesa transactions...')),
                            );
                          },
                          icon: const Icon(Icons.sync),
                          label: const Text('Sync Now'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Last sync: Never',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 32),

          Text('Features', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Real-time Fraud Alerts'),
            subtitle: const Text('Get immediate alerts for suspicious transactions'),
            value: _realtimeAlerts,
            onChanged: (v) => setState(() => _realtimeAlerts = v),
          ),
          SwitchListTile(
            title: const Text('Background Monitoring'),
            subtitle: const Text('Analyze patterns continuously for better protection'),
            value: _backgroundMonitoring,
            onChanged: (v) => setState(() => _backgroundMonitoring = v),
          ),

          const Divider(height: 32),
          Text('Profile', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone (e.g., 2547XXXXXXXX)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _limitController,
            decoration: const InputDecoration(
              labelText: 'Normal Spending Limit (KSH)',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _saveProfile,
              icon: const Icon(Icons.save),
              label: const Text('Save'),
            ),
          ),

          const Divider(height: 32),
          Text('Demo Mode', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Developer Mode'),
            subtitle: const Text('Enable advanced demo controls and testing features'),
            value: demoProvider.isDeveloperMode,
            onChanged: (v) => demoProvider.toggleDeveloperMode(),
          ),
          if (demoProvider.isDeveloperMode) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/demo'),
                    icon: const Icon(Icons.developer_mode),
                    label: const Text('Demo Controls'),
                  ),
                ),
              ],
            ),
          ],

          const Divider(height: 32),
          Text('About', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Shield AI'),
              subtitle: const Text('A Kenyan mobile money fraud protection app.'),
              trailing: const Text('v1.0.0'),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Why these permissions?\n\n'
            '• SMS: Helps us learn your M-Pesa patterns to detect unusual activity.\n'
            '• Notifications: Allows instant alerts to block suspicious transactions.\n'
            '• Location: Detects unusual locations compared to your normal usage.\n\n'
            'Your privacy matters: data is protected and used only to keep you safe.\n\n'
            'Proudly crafted by Lincoln Paul 😎',
          ),
        ],
      ),
    );
  }

  void _saveProfile() {
    // TODO: Persist profile via provider/API
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved')));
  }
}

class _PermissionTile extends StatelessWidget {
  final String title;
  final bool granted;
  final String explanation;
  final VoidCallback onRequest;

  const _PermissionTile({
    required this.title,
    required this.granted,
    required this.explanation,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    final color = granted ? Colors.green : Colors.red;
    final icon = granted ? Icons.check_circle : Icons.error_outline;
    final status = granted ? 'Granted' : 'Not granted';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                Text(status, style: TextStyle(color: color)),
              ],
            ),
            const SizedBox(height: 8),
            Text(explanation),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: onRequest,
                child: const Text('Request Permission'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
