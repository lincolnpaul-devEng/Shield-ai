import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/demo_provider.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Feature toggles
  bool _realtimeAlerts = true;
  bool _backgroundMonitoring = false;

  // Profile fields
  final _phoneController = TextEditingController(text: '254712345678');
  final _limitController = TextEditingController(text: '15000');

  @override
  void dispose() {
    _phoneController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildProfileSection(),
          const SizedBox(height: 24),
          _buildAppearanceSection(),
          const SizedBox(height: 24),
          _buildSecuritySection(),
          const SizedBox(height: 24),
          _buildDeveloperSection(),
          const SizedBox(height: 24),
          _buildAboutSection(),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return _SettingsCard(
      title: 'Profile',
      icon: Icons.person_outline,
      children: [
        TextField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _limitController,
          decoration: const InputDecoration(
            labelText: 'Normal Spending Limit (KSH)',
            prefixIcon: Icon(Icons.attach_money_outlined),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: _saveProfile,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save'),
          ),
        ),
      ],
    );
  }

  Widget _buildAppearanceSection() {
    return _SettingsCard(
      title: 'Appearance',
      icon: Icons.palette_outlined,
      children: [
        _SettingsSwitchTile(
          title: 'Dark Mode',
          subtitle: 'Enable a darker theme',
          icon: Icons.dark_mode_outlined,
          value: context.watch<ThemeProvider>().isDarkMode,
          onChanged: (value) {
            context.read<ThemeProvider>().toggleTheme();
          },
        ),
      ],
    );
  }

  Widget _buildSecuritySection() {
    return _SettingsCard(
      title: 'Security & Privacy',
      icon: Icons.security_outlined,
      children: [
        _SettingsSwitchTile(
          title: 'Real-time Fraud Alerts',
          subtitle: 'Immediate alerts for suspicious activity',
          icon: Icons.notifications_active_outlined,
          value: _realtimeAlerts,
          onChanged: (v) => setState(() => _realtimeAlerts = v),
        ),
        _SettingsSwitchTile(
          title: 'Background Monitoring',
          subtitle: 'Analyze patterns for better protection',
          icon: Icons.sync_problem_outlined,
          value: _backgroundMonitoring,
          onChanged: (v) => setState(() => _backgroundMonitoring = v),
        ),
        const Divider(height: 24),
        _PermissionTile(
          permission: Permission.sms,
          title: 'SMS Read Access',
          explanation: 'Needed to analyze M-Pesa messages for fraud detection.',
        ),
        _PermissionTile(
          permission: Permission.location,
          title: 'Location Access',
          explanation: 'Helps detect unusual transaction locations.',
        ),
      ],
    );
  }

  Widget _buildDeveloperSection() {
    final demoProvider = context.watch<DemoProvider>();
    return _SettingsCard(
      title: 'Developer Options',
      icon: Icons.developer_mode_outlined,
      children: [
        _SettingsSwitchTile(
          title: 'Developer Mode',
          subtitle: 'Enable advanced demo controls',
          icon: Icons.bug_report_outlined,
          value: demoProvider.isDeveloperMode,
          onChanged: (v) => demoProvider.toggleDeveloperMode(),
        ),
        if (demoProvider.isDeveloperMode) ...[
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/demo'),
            icon: const Icon(Icons.smart_toy_outlined),
            label: const Text('Open Demo Controls'),
          ),
        ],
      ],
    );
  }

  Widget _buildAboutSection() {
    return _SettingsCard(
      title: 'About',
      icon: Icons.info_outline,
      children: [
        _SettingsLinkTile(
          title: 'Version',
          subtitle: '1.0.0',
          icon: Icons.tag,
          onTap: () {},
        ),
        _SettingsLinkTile(
          title: 'Terms of Service',
          icon: Icons.description_outlined,
          onTap: () {
            Navigator.pushNamed(context, '/terms-of-service');
          },
        ),
        _SettingsLinkTile(
          title: 'Privacy Policy',
          icon: Icons.privacy_tip_outlined,
          onTap: () {
            Navigator.pushNamed(context, '/privacy-policy');
          },
        ),
      ],
    );
  }

  void _saveProfile() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved')));
  }
}

class _SettingsCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SettingsCard({required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      secondary: Icon(icon),
      value: value,
      onChanged: onChanged,
      activeThumbColor: Theme.of(context).colorScheme.primary,
    );
  }
}

class _SettingsLinkTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _SettingsLinkTile({required this.title, this.subtitle, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}

class _PermissionTile extends StatefulWidget {
  final Permission permission;
  final String title;
  final String explanation;

  const _PermissionTile({required this.permission, required this.title, required this.explanation});

  @override
  State<_PermissionTile> createState() => _PermissionTileState();
}

class _PermissionTileState extends State<_PermissionTile> {
  PermissionStatus _status = PermissionStatus.denied;

  @override
  void initState() {
    super.initState();
    _checkPermissionStatus();
  }

  Future<void> _checkPermissionStatus() async {
    final status = await widget.permission.status;
    setState(() => _status = status);
  }

  Future<void> _requestPermission() async {
    final status = await widget.permission.request();
    if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
    setState(() => _status = status);
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        _status.isGranted ? Icons.check_circle_outline : Icons.error_outline,
        color: _status.isGranted ? Colors.green : Colors.red,
      ),
      title: Text(widget.title),
      subtitle: Text(widget.explanation),
      trailing: ElevatedButton(
        onPressed: _requestPermission,
        child: Text(_status.isGranted ? 'Granted' : 'Request'),
      ),
    );
  }
}
