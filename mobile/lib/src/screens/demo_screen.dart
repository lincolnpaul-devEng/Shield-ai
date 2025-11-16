import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/demo_provider.dart';
import '../services/demo_service.dart';

class DemoScreen extends StatefulWidget {
  const DemoScreen({super.key});

  @override
  State<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends State<DemoScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh demo status when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DemoProvider>().refreshDemoStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final demoProvider = context.watch<DemoProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Demo Controls'),
        actions: [
          IconButton(
            icon: Icon(
              demoProvider.isDeveloperMode ? Icons.developer_mode : Icons.developer_mode_outlined,
              color: demoProvider.isDeveloperMode ? Colors.green : null,
            ),
            onPressed: () => demoProvider.toggleDeveloperMode(),
            tooltip: 'Toggle Developer Mode',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Demo Status
            _DemoStatusCard(demoProvider: demoProvider),

            const SizedBox(height: 24),

            // Demo Scenarios
            const Text('Demo Scenarios', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...DemoService.scenarios.entries.map((entry) =>
              _DemoScenarioCard(
                scenarioKey: entry.key,
                scenario: entry.value,
                demoProvider: demoProvider,
              ),
            ),

            const SizedBox(height: 24),

            // Demo Flow Results
            if (demoProvider.demoFlowResults.isNotEmpty) ...[
              const Text('Demo Flow Results', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...demoProvider.demoFlowResults.map((result) =>
                _DemoFlowResultCard(result: result),
              ),
            ],

            // Error Display
            if (demoProvider.error != null) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.error, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Error', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(demoProvider.error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => demoProvider.clearError(),
                        child: const Text('Dismiss'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DemoStatusCard extends StatelessWidget {
  final DemoProvider demoProvider;

  const _DemoStatusCard({required this.demoProvider});

  @override
  Widget build(BuildContext context) {
    final status = demoProvider.demoStatus;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Demo Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (status == null) ...[
              const Text('Loading demo status...'),
              const SizedBox(height: 8),
              const CircularProgressIndicator(),
            ] else ...[
              Row(
                children: [
                  Icon(
                    Icons.circle,
                    color: status['status'] == 'active' ? Colors.green : Colors.red,
                    size: 12,
                  ),
                  const SizedBox(width: 8),
                  Text('Status: ${status['status']}'),
                ],
              ),
              const SizedBox(height: 8),
              Text('Users: ${status['total_users']}'),
              Text('Transactions: ${status['total_transactions']}'),
              Text('Fraudulent: ${status['total_fraudulent']}'),
              Text('Fraud Rate: ${status['fraud_rate']}%'),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: demoProvider.isRunningDemo ? null : () => demoProvider.resetDemoData(),
                    child: const Text('Reset Data'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => demoProvider.refreshDemoStatus(),
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DemoScenarioCard extends StatelessWidget {
  final String scenarioKey;
  final Map<String, dynamic> scenario;
  final DemoProvider demoProvider;

  const _DemoScenarioCard({
    required this.scenarioKey,
    required this.scenario,
    required this.demoProvider,
  });

  @override
  Widget build(BuildContext context) {
    final isRunning = demoProvider.isRunningDemo;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scenario['title'],
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        scenario['description'],
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'User: ${DemoService.demoUsers[scenario['userKey']]!['name']}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: isRunning ? null : () => demoProvider.runDemoFlow(scenarioKey),
                  child: isRunning
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Run Demo'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DemoFlowResultCard extends StatelessWidget {
  final Map<String, dynamic> result;

  const _DemoFlowResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final status = result['status'];
    final step = result['step'];
    final message = result['message'];

    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'running':
        statusColor = Colors.blue;
        statusIcon = Icons.hourglass_top;
        break;
      case 'failed':
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.replaceAll('_', ' ').toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  Text(message, style: const TextStyle(fontSize: 14)),
                  if (result['error'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      result['error'],
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}