import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/user_provider.dart';
import '../models/transaction.dart';
import '../models/fraud_check_result.dart';

class SendMoneyScreen extends StatefulWidget {
  const SendMoneyScreen({super.key});

  @override
  State<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends State<SendMoneyScreen> {
  final _recipientController = TextEditingController();
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isAnalyzing = false;
  FraudCheckResult? _fraudResult;
  TransactionModel? _transaction;
  String? _error;

  @override
  void dispose() {
    _recipientController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _analyzeTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    final recipient = _recipientController.text.trim();
    final amountText = _amountController.text.trim();

    // Format phone number
    final fullRecipient = recipient.startsWith('+254') ? recipient : '+254$recipient';

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Please enter a valid amount');
      return;
    }

    // Validate Kenyan phone number
    if (!RegExp(r'^\+254[17]\d{8}$').hasMatch(fullRecipient)) {
      setState(() => _error = 'Please enter a valid Kenyan phone number');
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _fraudResult = null;
      _transaction = null;
      _error = null;
    });

    try {
      // Store context references before async operation
      final userProvider = context.read<UserProvider>();
      final transactionProvider = context.read<TransactionProvider>();

      final user = userProvider.currentUser;

      if (user == null) {
        setState(() => _error = 'User not logged in');
        return;
      }

      // Create transaction for analysis
      final transaction = TransactionModel(
        amount: amount,
        recipient: fullRecipient,
        timestamp: DateTime.now(),
        isFraudulent: false, // Will be determined by fraud detection
      );

      final fraudResult = await transactionProvider.addTransaction(user.phone, transaction);

      setState(() {
        _fraudResult = fraudResult;
        _transaction = transaction;
      });

    } catch (e) {
      setState(() => _error = 'Failed to analyze transaction: ${e.toString()}');
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _confirmSend() async {
    if (_fraudResult == null || _transaction == null) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Transaction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Send KSH ${_transaction!.amount.toStringAsFixed(2)}'),
            Text('To: ${_transaction!.recipient}'),
            const SizedBox(height: 16),
            if (_fraudResult!.isFraud) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '⚠️ Fraud Risk Detected\n${_fraudResult!.reason}',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Are you sure you want to proceed with this transaction?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '✅ Transaction appears safe\n${_fraudResult!.reason}',
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _fraudResult!.isFraud ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(_fraudResult!.isFraud ? 'Send Anyway' : 'Send Money'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // In a real app, this would send the money via M-Pesa API
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Transaction ${_fraudResult!.isFraud ? "sent with caution" : "completed successfully"}'
          ),
          backgroundColor: _fraudResult!.isFraud ? Colors.orange : Colors.green,
        ),
      );

      // Reset form
      _recipientController.clear();
      _amountController.clear();
      setState(() {
        _fraudResult = null;
        _transaction = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Money'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade400, Colors.green.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.send, color: Colors.white, size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Secure Money Transfer',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'AI-powered fraud protection for every transaction',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Recipient Field
              TextFormField(
                controller: _recipientController,
                decoration: InputDecoration(
                  labelText: 'Recipient Phone Number',
                  hintText: '712 345 678',
                  prefixText: '+254 ',
                  prefixStyle: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
                keyboardType: TextInputType.phone,
                maxLength: 9,
                buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter recipient phone number';
                  }
                  final fullNumber = value.startsWith('+254') ? value : '+254$value';
                  if (!RegExp(r'^\+254[17]\d{8}$').hasMatch(fullNumber)) {
                    return 'Please enter a valid Kenyan phone number';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Amount Field
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Amount (KSH)',
                  hintText: '1000.00',
                  prefixText: 'KSH ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  if (amount > 150000) {
                    return 'Maximum transaction amount is KSH 150,000';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Error Message
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Analyze Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isAnalyzing ? null : _analyzeTransaction,
                  icon: _isAnalyzing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.security),
                  label: Text(
                    _isAnalyzing ? 'Analyzing Transaction...' : 'Analyze Transaction',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Fraud Analysis Result
              if (_fraudResult != null) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _fraudResult!.isFraud
                        ? Colors.red.shade50
                        : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _fraudResult!.isFraud
                          ? Colors.red.shade200
                          : Colors.green.shade200,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _fraudResult!.isFraud ? Icons.warning : Icons.check_circle,
                            color: _fraudResult!.isFraud ? Colors.red : Colors.green,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _fraudResult!.isFraud ? '⚠️ Fraud Risk Detected' : '✅ Transaction Safe',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: _fraudResult!.isFraud ? Colors.red : Colors.green,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Confidence: ${(_fraudResult!.confidence * 100).toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    color: _fraudResult!.isFraud ? Colors.red : Colors.green,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _fraudResult!.reason,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _fraudResult = null;
                                  _transaction = null;
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                              ),
                              child: const Text('Modify'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _confirmSend,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _fraudResult!.isFraud ? Colors.red : Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              child: Text(_fraudResult!.isFraud ? 'Send Anyway' : 'Send Money'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Security Notice
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.shield,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Shield AI Protection',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Every transaction is analyzed for fraud patterns before processing.',
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
            ],
          ),
        ),
      ),
    );
  }
}