import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_budget_plan.dart';
import '../providers/financial_provider.dart';
import '../providers/user_provider.dart';

class BudgetCreationScreen extends StatefulWidget {
  const BudgetCreationScreen({super.key});

  @override
  State<BudgetCreationScreen> createState() => _BudgetCreationScreenState();
}

class _BudgetCreationScreenState extends State<BudgetCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  UserBudgetPlan? _planToEdit;

  bool get _isEditing => _planToEdit != null;

  // Step 1: Basic Info
  final _planNameController = TextEditingController();
  final _incomeController = TextEditingController();
  final _savingsGoalController = TextEditingController();
  final _savingsMonthsController = TextEditingController();
  final _pinController = TextEditingController();

  // Step 2: Category Allocation
  final Map<String, TextEditingController> _categoryControllers = {};
  final List<String> _defaultCategories = [
    'Food & Groceries',
    'Transport',
    'Airtime & Data',
    'Entertainment',
    'Utilities',
    'Healthcare',
    'Education',
    'Savings',
    'Miscellaneous'
  ];

  // Step 3: Review
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeCategoryControllers();
    _loadTemplates();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Access route arguments after the widget is fully built
    if (_planToEdit == null) {
      _planToEdit = ModalRoute.of(context)?.settings.arguments as UserBudgetPlan?;
      _initializeForEditing();
    }
  }

  void _initializeForEditing() {
    if (_isEditing && _planToEdit != null) {
      final plan = _planToEdit!;
      _planNameController.text = plan.planName;
      _incomeController.text = plan.monthlyIncome.toString();
      if (plan.savingsGoal != null) {
        _savingsGoalController.text = plan.savingsGoal.toString();
      }
      if (plan.savingsPeriodMonths != null) {
        _savingsMonthsController.text = plan.savingsPeriodMonths.toString();
      }

      // Pre-populate category allocations
      plan.allocations.forEach((category, amount) {
        if (_categoryControllers.containsKey(category)) {
          _categoryControllers[category]!.text = amount.toString();
        }
      });
    }
  }

  void _initializeCategoryControllers() {
    for (final category in _defaultCategories) {
      _categoryControllers[category] = TextEditingController(text: '0');
    }
  }

  Future<void> _loadTemplates() async {
    final financialProvider = context.read<FinancialProvider>();
    await financialProvider.loadBudgetTemplates();
  }

  @override
  void dispose() {
    _planNameController.dispose();
    _incomeController.dispose();
    _savingsGoalController.dispose();
    _savingsMonthsController.dispose();
    _pinController.dispose();
    for (final controller in _categoryControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      if (_validateCurrentStep()) {
        setState(() {
          _currentStep++;
        });
      }
    } else {
      _createOrUpdatePlan();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _planNameController.text.isNotEmpty &&
                _incomeController.text.isNotEmpty &&
                double.tryParse(_incomeController.text) != null &&
                _pinController.text.isNotEmpty &&
                _pinController.text.length == 4;
      case 1:
        final total = _calculateTotalAllocation();
        final income = double.tryParse(_incomeController.text) ?? 0;
        return total <= income && total > 0;
      default:
        return true;
    }
  }

  double _calculateTotalAllocation() {
    double total = 0;
    for (final controller in _categoryControllers.values) {
      final value = double.tryParse(controller.text) ?? 0;
      total += value;
    }
    return total;
  }

  String _getUserFriendlyErrorMessage(String error) {
    if (error.contains('conflict') || error.contains('already exists')) {
      return 'A budget plan with this name already exists. Please choose a different name.';
    } else if (error.contains('unauthorized') || error.contains('Invalid PIN')) {
      return 'Invalid PIN. Please check your M-Pesa PIN and try again.';
    } else if (error.contains('bad_request')) {
      return 'Invalid plan details. Please check your inputs and try again.';
    } else {
      return 'Failed to create budget plan. Please try again.';
    }
  }

  Future<void> _createOrUpdatePlan() async {
    final userProvider = context.read<UserProvider>();
    final financialProvider = context.read<FinancialProvider>();

    if (userProvider.currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final plan = UserBudgetPlan(
        id: _isEditing ? _planToEdit!.id : '', // Will be set by backend for new plans
        userId: userProvider.currentUser!.phone,
        planName: _planNameController.text.trim(),
        planDescription: _isEditing
            ? _planToEdit!.planDescription
            : 'Custom budget plan created on ${DateTime.now().toString().split(' ')[0]}',
        monthlyIncome: double.parse(_incomeController.text),
        savingsGoal: _savingsGoalController.text.isNotEmpty
            ? double.tryParse(_savingsGoalController.text)
            : null,
        savingsPeriodMonths: _savingsMonthsController.text.isNotEmpty
            ? int.tryParse(_savingsMonthsController.text)
            : null,
        allocations: _categoryControllers.map((key, controller) =>
            MapEntry(key, double.tryParse(controller.text) ?? 0)),
        isActive: _isEditing ? _planToEdit!.isActive : true,
        createdAt: _isEditing ? _planToEdit!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final success = _isEditing
          ? await financialProvider.updateUserPlan(plan, userProvider.currentUser!.phone, _pinController.text)
          : await financialProvider.createUserPlan(plan, userProvider.currentUser!.phone, _pinController.text);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditing ? 'Budget plan updated successfully!' : 'Budget plan created successfully!')),
        );

        // Refresh the plans list to include the updated/new plan
        final financialProvider = context.read<FinancialProvider>();
        final userProvider = context.read<UserProvider>();
        if (userProvider.currentUser != null) {
          await financialProvider.loadUserPlans(
            userProvider.currentUser!.phone,
            _pinController.text,
          );
        }

        // Navigate back to financial planning screen
        Navigator.pushReplacementNamed(context, '/financial-planning');
      } else {
        // Handle operation failure
        if (mounted) {
          final financialProvider = context.read<FinancialProvider>();
          String errorMessage = _getUserFriendlyErrorMessage(financialProvider.error ?? (_isEditing ? 'Plan update failed' : 'Plan creation failed'));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.warning, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(child: Text(errorMessage)),
                ],
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: Duration(seconds: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to ${_isEditing ? 'update' : 'create'} plan: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _applyTemplate(BudgetTemplate template) {
    final income = double.tryParse(_incomeController.text) ?? 0;
    if (income > 0) {
      final allocations = template.getAllocationsForIncome(income);
      setState(() {
        for (final entry in allocations.entries) {
          if (_categoryControllers.containsKey(entry.key)) {
            _categoryControllers[entry.key]!.text = entry.value.toStringAsFixed(0);
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Budget Plan' : 'Create Budget Plan'),
        actions: [
          if (_currentStep > 0)
            TextButton(
              onPressed: _previousStep,
              child: const Text('Back'),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildCurrentStep(),
            ),
          ),
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    final steps = ['Basic Info', 'Categories', 'Review'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        children: List.generate(steps.length, (index) {
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;

          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted
                        ? Colors.green
                        : isActive
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : Text(
                            '${index + 1}',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                  ),
                ),
                if (index < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isCompleted ? Colors.green : Colors.grey,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildBasicInfoStep();
      case 1:
        return _buildCategoriesStep();
      case 2:
        return _buildReviewStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBasicInfoStep() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Basic Information',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Let\'s start by setting up your basic budget information.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),

          TextFormField(
            controller: _planNameController,
            decoration: const InputDecoration(
              labelText: 'Plan Name',
              hintText: 'e.g., Monthly Budget 2024',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please enter a plan name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _incomeController,
            decoration: const InputDecoration(
              labelText: 'Monthly Income (KES)',
              hintText: '50000',
              border: OutlineInputBorder(),
              prefixText: 'KES ',
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please enter your monthly income';
              }
              final income = double.tryParse(value!);
              if (income == null || income <= 0) {
                return 'Please enter a valid income amount';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _savingsGoalController,
            decoration: const InputDecoration(
              labelText: 'Savings Goal (Optional)',
              hintText: '100000',
              border: OutlineInputBorder(),
              prefixText: 'KES ',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _savingsMonthsController,
            decoration: const InputDecoration(
              labelText: 'Time Period (Months)',
              hintText: '12',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _pinController,
            decoration: const InputDecoration(
              labelText: 'M-Pesa PIN',
              hintText: '••••',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 4,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please enter your M-Pesa PIN';
              }
              if (value!.length != 4) {
                return 'PIN must be 4 digits';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesStep() {
    final income = double.tryParse(_incomeController.text) ?? 0;
    final totalAllocated = _calculateTotalAllocation();
    final remaining = income - totalAllocated;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category Allocation',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Allocate your KES ${income.toStringAsFixed(0)} monthly income across different categories.',
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),

        // Budget Summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Income:', style: TextStyle(fontWeight: FontWeight.w500)),
                  Text('KES ${income.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Allocated:', style: TextStyle(fontWeight: FontWeight.w500)),
                  Text(
                    'KES ${totalAllocated.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: totalAllocated > income ? Colors.red : Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Remaining:', style: TextStyle(fontWeight: FontWeight.w500)),
                  Text(
                    'KES ${remaining.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: remaining < 0 ? Colors.red : Colors.blue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Templates
        Consumer<FinancialProvider>(
          builder: (context, financialProvider, child) {
            if (financialProvider.budgetTemplates.isNotEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Quick Templates:', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: financialProvider.budgetTemplates.map((template) {
                      return ElevatedButton(
                        onPressed: () => _applyTemplate(template),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                          foregroundColor: Theme.of(context).colorScheme.onSurface,
                        ),
                        child: Text(template.name),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),

        // Category Inputs
        ..._categoryControllers.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextFormField(
              controller: entry.value,
              decoration: InputDecoration(
                labelText: entry.key,
                border: const OutlineInputBorder(),
                prefixText: 'KES ',
                suffixText: income > 0 ? '${((double.tryParse(entry.value.text) ?? 0) / income * 100).toStringAsFixed(1)}%' : '',
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) => setState(() {}),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildReviewStep() {
    final income = double.tryParse(_incomeController.text) ?? 0;
    final totalAllocated = _calculateTotalAllocation();
    final savingsGoal = double.tryParse(_savingsGoalController.text) ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Review Your Plan',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Please review your budget plan before saving.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 24),

        // Plan Summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _planNameController.text,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Monthly Income: KES ${income.toStringAsFixed(0)}'),
              if (savingsGoal > 0) ...[
                const SizedBox(height: 4),
                Text('Savings Goal: KES ${savingsGoal.toStringAsFixed(0)}'),
              ],
              const SizedBox(height: 4),
              Text('Total Allocated: KES ${totalAllocated.toStringAsFixed(0)}'),
              Text(
                'Remaining: KES ${(income - totalAllocated).toStringAsFixed(0)}',
                style: TextStyle(
                  color: (income - totalAllocated) < 0 ? Colors.red : Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Authentication: PIN verified',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Category Breakdown
        const Text('Category Breakdown:', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        ..._categoryControllers.entries.where((entry) {
          final amount = double.tryParse(entry.value.text) ?? 0;
          return amount > 0;
        }).map((entry) {
          final amount = double.tryParse(entry.value.text) ?? 0;
          final percentage = income > 0 ? (amount / income * 100) : 0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(entry.key),
                Text('KES ${amount.toStringAsFixed(0)} (${percentage.toStringAsFixed(1)}%)'),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                child: const Text('Back'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_currentStep < 2 ? 'Next' : (_isEditing ? 'Update Plan' : 'Create Plan')),
            ),
          ),
        ],
      ),
    );
  }
}