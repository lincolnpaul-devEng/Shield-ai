import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import '../models/transaction.dart';

class MpesaSyncService {
  static const String _lastSyncKey = 'mpesa_last_sync';
  static const String _syncTaskName = 'mpesa_sync_task';

  late SharedPreferences _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();

    // Initialize WorkManager for background sync
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: true, // Set to false in production
    );

    // Schedule periodic sync every 4 hours
    await Workmanager().registerPeriodicTask(
      _syncTaskName,
      _syncTaskName,
      frequency: const Duration(hours: 4),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }

  /// Sync recent M-Pesa transactions
  /// Note: Direct SMS reading requires special permissions and native code
  /// This implementation provides a framework for SMS sync and demo data
  Future<List<TransactionModel>> syncRecentTransactions() async {
    final List<TransactionModel> transactions = [];

    try {
      // In a real implementation, this would:
      // 1. Request SMS read permission
      // 2. Query SMS database for M-Pesa messages
      // 3. Parse transaction data from SMS content
      // 4. Filter out already processed messages

      // For demo purposes, generate some sample transactions
      // In production, replace this with actual SMS reading logic
      transactions.addAll(_generateDemoTransactions());

      // Update last sync time
      await _prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());

    } catch (e) {
      // Error syncing M-Pesa transactions
    }

    return transactions;
  }

  /// Generate demo transactions for testing
  /// In production, replace with actual SMS parsing
  List<TransactionModel> _generateDemoTransactions() {
    final random = Random();
    final now = DateTime.now();
    final transactions = <TransactionModel>[];

    // Generate 0-3 random transactions
    final count = random.nextInt(4);

    for (int i = 0; i < count; i++) {
      final amount = (random.nextDouble() * 10000) + 100; // 100-10100 KSH
      final isIncoming = random.nextBool();

      // Random recipient phone numbers //real phone numbers will be used
      final recipients = [
        '+254712345678',
        '+254798765432',
        '+254723456789',
        '+254767890123',
      ];

      final recipient = recipients[random.nextInt(recipients.length)];

      // Random timestamp within last 24 hours
      final hoursAgo = random.nextInt(24);
      final timestamp = now.subtract(Duration(hours: hoursAgo));

      transactions.add(TransactionModel(
        amount: isIncoming ? -amount : amount, // Negative for incoming
        recipient: recipient,
        timestamp: timestamp,
        isFraudulent: false, // Will be checked by fraud detector
      ));
    }

    return transactions;
  }

  /// Manual sync trigger (can be called from UI)
  Future<void> syncNow() async {
    await syncRecentTransactions();
    // Manual sync completed
  }

  /// Background sync callback for WorkManager
  @pragma('vm:entry-point')
  static void callbackDispatcher() {
    Workmanager().executeTask((task, inputData) async {
      try {
        final service = MpesaSyncService();
        await service.initialize();
        await service.syncRecentTransactions();
        return true; // Success
      } catch (e) {
        return false; // Failure
      }
    });
  }

  /// Get last sync time
  DateTime? getLastSyncTime() {
    final lastSyncStr = _prefs.getString(_lastSyncKey);
    return lastSyncStr != null ? DateTime.parse(lastSyncStr) : null;
  }

  /// Check if sync is needed (every 4 hours)
  bool shouldSync() {
    final lastSync = getLastSyncTime();
    if (lastSync == null) return true;

    final fourHoursAgo = DateTime.now().subtract(const Duration(hours: 4));
    return lastSync.isBefore(fourHoursAgo);
  }
}