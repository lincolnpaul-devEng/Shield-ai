import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';

class FraudAlertScreen extends StatefulWidget {
  final String recipient;
  final double amount;
  final DateTime timestamp;
  final String? location;
  final Duration countdown;
  final VoidCallback onBlock;
  final VoidCallback onAllow;

  const FraudAlertScreen({
    super.key,
    required this.recipient,
    required this.amount,
    required this.timestamp,
    this.location,
    this.countdown = const Duration(seconds: 10),
    required this.onBlock,
    required this.onAllow,
  });

  @override
  State<FraudAlertScreen> createState() => _FraudAlertScreenState();
}

class _FraudAlertScreenState extends State<FraudAlertScreen> with WidgetsBindingObserver {
  late int _secondsLeft;
  Timer? _timer;
  bool _handled = false;
  bool _emergencyMode = false;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _secondsLeft = widget.countdown.inSeconds;
    _startCountdown();
    _alertUser();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Keep attention by vibrating again when resumed
    if (state == AppLifecycleState.resumed) {
      _alertUser();
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        t.cancel();
        _autoBlock();
      } else {
        setState(() => _secondsLeft -= 1);
      }
    });
  }

  Future<void> _alertUser() async {
    // Vibrate device (may require permissions per platform)
    try {
      await HapticFeedback.heavyImpact();
      await HapticFeedback.vibrate();
    } catch (_) {}

    // Play urgent notification sound with flutter_local_notifications
    try {
      const androidDetails = AndroidNotificationDetails(
        'shield_ai_urgent',
        'Urgent Fraud Alerts',
        channelDescription: 'Emergency fraud alerts',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );
      const details = NotificationDetails(android: androidDetails);
      await FlutterLocalNotificationsPlugin().show(
        999,
        '🚨 FRAUD ALERT - ACT NOW!',
        'Suspicious transaction: KSH ${widget.amount.toStringAsFixed(2)} to ${widget.recipient}',
        details,
      );
    } catch (_) {}
  }

  void _autoBlock() {
    if (_handled) return;
    _handled = true;
    widget.onBlock();
    if (mounted) Navigator.of(context).pop();
  }

  void _block() {
    if (_handled) return;
    _handled = true;
    widget.onBlock();
    Navigator.of(context).pop();
  }

  void _allow() {
    if (_handled) return;
    _handled = true;
    widget.onAllow();
    Navigator.of(context).pop();
  }

  void _toggleEmergencyMode() {
    setState(() => _emergencyMode = !_emergencyMode);
    if (_emergencyMode) {
      _timer?.cancel(); // Pause countdown in emergency mode
      HapticFeedback.vibrate();
    } else {
      _startCountdown(); // Resume countdown
    }
  }

  Future<void> _callEmergency(String number, String service) async {
    final url = 'tel:$number';
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        _showSnackBar('Cannot call $service. Number: $number');
      }
    } catch (e) {
      _showSnackBar('Error calling $service: $e');
    }
  }

  Future<void> _sendEmergencySMS() async {
    try {
      final message = '🚨 URGENT: Fraud alert! Suspicious transaction of KSH ${widget.amount.toStringAsFixed(2)} to ${widget.recipient} at ${widget.timestamp.toLocal()}. Please contact me immediately!';

      // Use share_plus to share the message (user can choose SMS app)
      await Share.share(message, subject: 'URGENT FRAUD ALERT');
      _showSnackBar('Emergency message shared - send via SMS to trusted contacts');
    } catch (e) {
      _showSnackBar('Error sharing emergency message: $e');
    }
  }

  Future<void> _shareLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      setState(() {
        _isLoadingLocation = false;
      });

      final locationMessage = '🚨 EMERGENCY LOCATION: Lat ${position.latitude}, Lng ${position.longitude}\n'
          'Fraud incident: KSH ${widget.amount.toStringAsFixed(2)} to ${widget.recipient}\n'
          'Time: ${widget.timestamp.toLocal()}';

      await Share.share(locationMessage, subject: 'EMERGENCY LOCATION - FRAUD INCIDENT');
      _showSnackBar('Location shared with emergency contacts');
    } catch (e) {
      setState(() => _isLoadingLocation = false);
      _showSnackBar('Error getting location: $e');
    }
  }

  Future<void> _freezeAccount() async {
    // In real app, this would call backend API to freeze account
    _showSnackBar('Account freeze requested. Contacting your bank...');
    await Future.delayed(const Duration(seconds: 2));
    _showSnackBar('Account frozen successfully. Contact your bank to unfreeze.');
  }

  Future<void> _reportFraud() async {
    const fraudReportUrl = 'https://www.cert.or.ke/report-fraud/';
    try {
      if (await canLaunchUrl(Uri.parse(fraudReportUrl))) {
        await launchUrl(Uri.parse(fraudReportUrl));
      } else {
        _showSnackBar('Cannot open fraud reporting page. Visit: $fraudReportUrl');
      }
    } catch (e) {
      _showSnackBar('Error opening fraud report: $e');
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // prevent back
      child: Scaffold(
        backgroundColor: _emergencyMode ? Colors.red.shade900 : Colors.red.shade700,
        body: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Emergency Mode Toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'EMERGENCY MODE',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Switch(
                          value: _emergencyMode,
                          onChanged: (_) => _toggleEmergencyMode(),
                          activeThumbColor: Colors.white,
                          activeTrackColor: Colors.red.shade300,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Main Alert Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _emergencyMode ? Icons.emergency : Icons.warning_amber_rounded,
                            color: Colors.white,
                            size: _emergencyMode ? 100 : 80,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _emergencyMode ? '🚨 EMERGENCY MODE ACTIVE' : 'POTENTIAL FRAUD DETECTED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: _emergencyMode ? 20 : 24,
                              fontWeight: FontWeight.w800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          _DetailsCard(
                            recipient: widget.recipient,
                            amount: widget.amount,
                            timestamp: widget.timestamp,
                            location: widget.location,
                          ),
                          const SizedBox(height: 16),
                          if (!_emergencyMode) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Auto-blocking in $_secondsLeft seconds',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Emergency Actions Grid
                    if (_emergencyMode) ...[
                      const Text(
                        'EMERGENCY ACTIONS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        children: [
                          _EmergencyButton(
                            icon: Icons.local_police,
                            label: 'Call Police',
                            color: Colors.blue.shade600,
                            onPressed: () => _callEmergency('999', 'Police'),
                          ),
                          _EmergencyButton(
                            icon: Icons.account_balance,
                            label: 'Call Bank',
                            color: Colors.green.shade600,
                            onPressed: () => _callEmergency('100', 'Bank'),
                          ),
                          _EmergencyButton(
                            icon: Icons.location_on,
                            label: _isLoadingLocation ? 'Getting Location...' : 'Share Location',
                            color: Colors.orange.shade600,
                            onPressed: _isLoadingLocation ? null : _shareLocation,
                          ),
                          _EmergencyButton(
                            icon: Icons.sms,
                            label: 'Emergency SMS',
                            color: Colors.purple.shade600,
                            onPressed: _sendEmergencySMS,
                          ),
                          _EmergencyButton(
                            icon: Icons.ac_unit,
                            label: 'Freeze Account',
                            color: Colors.teal.shade600,
                            onPressed: _freezeAccount,
                          ),
                          _EmergencyButton(
                            icon: Icons.report,
                            label: 'Report Fraud',
                            color: Colors.indigo.shade600,
                            onPressed: _reportFraud,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Main Action Buttons
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.red.shade700,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _block,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.block, size: 24),
                                const SizedBox(width: 8),
                                const Text(
                                  'BLOCK TRANSACTION',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (!_emergencyMode) ...[
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.white.withValues(alpha: 0.9)),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _allow,
                              child: const Text(
                                'ALLOW TRANSACTION',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Emergency Hotline Numbers
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Emergency Hotlines',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _HotlineItem(
                            service: 'Police Emergency',
                            number: '999',
                            onTap: () => _callEmergency('999', 'Police'),
                          ),
                          _HotlineItem(
                            service: 'Communications Authority',
                            number: '020-4242000',
                            onTap: () => _callEmergency('020-4242000', 'Communications Authority'),
                          ),
                          _HotlineItem(
                            service: 'Central Bank of Kenya',
                            number: '020-2861000',
                            onTap: () => _callEmergency('020-2861000', 'Central Bank'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Safety Notice
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '⚠️ If you suspect fraud, act immediately. Do not share your PIN or OTP with anyone.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),

              // Emergency Mode Indicator
              Positioned(
                right: 16,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _emergencyMode ? Colors.red.shade300 : Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _emergencyMode ? 'EMERGENCY ACTIVE' : 'Emergency',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  final String recipient;
  final double amount;
  final DateTime timestamp;
  final String? location;
  const _DetailsCard({required this.recipient, required this.amount, required this.timestamp, this.location});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row('Amount', 'KSH ${amount.toStringAsFixed(2)}'),
          _row('Recipient', recipient),
          _row('Time', timestamp.toIso8601String()),
          if (location != null) _row('Location', location!),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70)),
            Flexible(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
          ],
        ),
      );
}

class _EmergencyButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  const _EmergencyButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _HotlineItem extends StatelessWidget {
  final String service;
  final String number;
  final VoidCallback onTap;

  const _HotlineItem({
    required this.service,
    required this.number,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Icon(Icons.phone, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    number,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.call, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}
