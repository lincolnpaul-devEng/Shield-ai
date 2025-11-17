import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart';

enum TxFilter { all, fraudulent, normal }

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _searchController = TextEditingController();
  TxFilter _filter = TxFilter.all;
  final String _userId = 'demo-user';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().fetchTransactions(_userId);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final items = _apply(provider.transactions);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          PopupMenuButton<TxFilter>(
            initialValue: _filter,
            onSelected: (v) => setState(() => _filter = v),
            itemBuilder: (context) => const [
              PopupMenuItem(value: TxFilter.all, child: Text('All')),
              PopupMenuItem(value: TxFilter.fraudulent, child: Text('Fraudulent')),
              PopupMenuItem(value: TxFilter.normal, child: Text('Normal')),
            ],
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<TransactionProvider>().fetchTransactions(_userId),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by recipient or amount',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? const _EmptyState()
                  : ListView.separated(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final t = items[index];
                        return _TransactionTile(
                          tx: t,
                          onTap: () => _openDetails(t),
                        );
                      },
                      separatorBuilder: (_, __) => const Divider(height: 1),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.read<TransactionProvider>().fetchTransactions(_userId),
        child: const Icon(Icons.refresh),
      ),
    );
  }

  List<TransactionModel> _apply(List<TransactionModel> input) {
    final query = _searchController.text.trim().toLowerCase();
    var list = input;

    switch (_filter) {
      case TxFilter.fraudulent:
        list = list.where((t) => t.isFraudulent).toList();
        break;
      case TxFilter.normal:
        list = list.where((t) => !t.isFraudulent).toList();
        break;
      case TxFilter.all:
        break;
    }

    if (query.isNotEmpty) {
      list = list.where((t) {
        final byRecipient = t.recipient.toLowerCase().contains(query);
        final byAmount = t.amount.toStringAsFixed(2).contains(query);
        return byRecipient || byAmount;
      }).toList();
    }

    return list;
  }

  void _openDetails(TransactionModel tx) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => _TransactionDetails(tx: tx)),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionModel tx;
  final VoidCallback onTap;
  const _TransactionTile({required this.tx, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isFraud = tx.isFraudulent;
    final color = isFraud ? Colors.red : Colors.green;
    final icon = isFraud ? Icons.flag : Icons.check_circle;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text('KSH ${tx.amount.toStringAsFixed(2)}'),
      subtitle: Text('${tx.recipient} • ${tx.timestamp.toIso8601String()}'),
      trailing: Text(isFraud ? 'Fraud' : 'Normal', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      onTap: onTap,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Text('No transactions found'),
        ),
      );
}

class _TransactionDetails extends StatelessWidget {
  final TransactionModel tx;
  const _TransactionDetails({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isFraud = tx.isFraudulent;
    final color = isFraud ? Colors.red : Colors.green;
    return Scaffold(
      appBar: AppBar(title: const Text('Transaction Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(isFraud ? Icons.flag : Icons.check_circle, color: color),
                const SizedBox(width: 8),
                Text(isFraud ? 'Fraudulent' : 'Normal', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            _row('Amount', 'KSH ${tx.amount.toStringAsFixed(2)}'),
            _row('Recipient', tx.recipient),
            _row('Time', tx.timestamp.toIso8601String()),
            if (tx.location != null) _row('Location', tx.location!),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Flexible(child: Text(value, textAlign: TextAlign.right)),
          ],
        ),
      );
}
