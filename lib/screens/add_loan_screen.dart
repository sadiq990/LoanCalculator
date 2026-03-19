import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'dart:math';
import '../core/theme/app_theme.dart';
import '../core/widgets/app_scaffold.dart';
import '../core/widgets/animated_button.dart';
import '../core/constants/loan_icons.dart';
import '../core/utils/currency_formatter.dart';
import '../core/utils/input_formatters.dart';
import '../models/loan.dart';
import '../services/storage_service.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class AddLoanScreen extends StatefulWidget {
  const AddLoanScreen({super.key});
  @override
  State<AddLoanScreen> createState() => _AddLoanScreenState();
}

class _AddLoanScreenState extends State<AddLoanScreen> {
  final _pageController = PageController();

  int _currentStep = 0;
  final _totalSteps = 4;

  // Step 1: Category
  String _selectedIcon = 'default';
  final _nameController = TextEditingController();

  // Step 2: Amount
  final _amountController = TextEditingController();
  final _rateController = TextEditingController();

  // Step 3: Schedule
  final _termController = TextEditingController();
  bool _termInYears = true;
  int _paymentDay = 15;

  bool _isSaving = false;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _amountController.dispose();
    _rateController.dispose();
    _termController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (!_validateCurrentStep()) return;
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: AppTheme.animMedium,
        curve: AppTheme.curveDefault,
      );
      HapticFeedback.selectionClick();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: AppTheme.animMedium,
        curve: AppTheme.curveDefault,
      );
    } else {
      Navigator.pop(context);
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        if (_nameController.text.trim().isEmpty) {
          _showError('Please enter a loan name');
          return false;
        }
        return true;
      case 1:
        final amount = double.tryParse(
          _amountController.text.replaceAll('.', '').replaceAll(',', '.'),
        );
        final rate = double.tryParse(_rateController.text);
        if (amount == null || amount <= 0) {
          _showError('Please enter a valid amount');
          return false;
        }
        if (rate == null || rate < 0 || rate > 100) {
          _showError('Please enter a valid interest rate (0-100)');
          return false;
        }
        return true;
      case 2:
        final term = int.tryParse(_termController.text);
        if (term == null || term <= 0) {
          _showError('Please enter a valid term');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.error),
    );
  }

  Future<void> _saveLoan() async {
    setState(() => _isSaving = true);
    try {
      final amount = double.parse(
        _amountController.text.replaceAll('.', '').replaceAll(',', '.'),
      );
      final rate = double.parse(_rateController.text);
      final rawTerm = int.parse(_termController.text);
      final termMonths = _termInYears ? rawTerm * 12 : rawTerm;

      final loan = Loan(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        totalAmount: amount,
        interestRate: rate,
        termMonths: termMonths,
        paymentDay: _paymentDay,
        createdAt: DateTime.now(),
        payments: [],
        iconId: _selectedIcon,
      );

      final storage = Provider.of<StorageService>(context, listen: false);
      await storage.addLoan(loan);
      HapticFeedback.mediumImpact();
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Error creating loan: $e');
      _showError('Failed to create loan: ${e.toString()}');
    }
    setState(() => _isSaving = false);
  }

  double? get _estimatedMonthly {
    final amount = double.tryParse(
      _amountController.text.replaceAll('.', '').replaceAll(',', '.'),
    );
    final rate = double.tryParse(_rateController.text);
    final rawTerm = int.tryParse(_termController.text);
    if (amount == null || rate == null || rawTerm == null) return null;
    if (amount <= 0 || rawTerm <= 0) return null;
    final termMonths = _termInYears ? rawTerm * 12 : rawTerm;
    if (rate == 0) return amount / termMonths;
    final r = rate / 100 / 12;
    return amount * r * pow(1 + r, termMonths) / (pow(1 + r, termMonths) - 1);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      useSafeArea: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _prevStep,
        ),
        title: Text('Step ${_currentStep + 1} of $_totalSteps'),
        actions: [
          if (_currentStep > 0)
            TextButton(
              onPressed: _prevStep,
              child: const Text('Back'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Progress dots
          _buildProgressDots(),
          // Pages
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1Category(),
                _buildStep2Amount(),
                _buildStep3Schedule(),
                _buildStep4Review(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressDots() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: List.generate(_totalSteps, (i) {
          final isActive = i <= _currentStep;
          return Expanded(
            child: AnimatedContainer(
              duration: AppTheme.animFast,
              height: 4,
              margin: EdgeInsets.only(right: i < _totalSteps - 1 ? 6 : 0),
              decoration: BoxDecoration(
                color: isActive ? AppTheme.primary : AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  // Step 1: Category + Name
  Widget _buildStep1Category() {
    final icons = kLoanIcons.keys.toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What type of loan?',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ) ?? TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
          const SizedBox(height: AppTheme.spacing8),
          Text('Select a category and name your loan',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textLight) ?? TextStyle(fontSize: 15, color: AppTheme.textLight)),
          const SizedBox(height: AppTheme.spacing24),

          // Icon Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: AppTheme.spacing12,
              crossAxisSpacing: AppTheme.spacing12,
              childAspectRatio: 0.9,
            ),
            itemCount: icons.length,
            itemBuilder: (_, i) {
              final id = icons[i];
              final selected = _selectedIcon == id;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedIcon = id);
                },
                child: AnimatedContainer(
                  duration: AppTheme.animFast,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.primary.withValues(alpha: 0.1)
                        : AppTheme.surfaceLight.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(
                      color: selected ? AppTheme.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      buildGradientIcon(id, size: 36),
                      const SizedBox(height: 6),
                      Text(
                        kLoanIconLabel(id),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? AppTheme.primary : AppTheme.textLight,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: AppTheme.spacing24),
          // Name
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Loan Name',
              prefixIcon: Icon(Icons.edit_rounded),
              hintText: 'e.g. Home Mortgage',
            ),
          ),
          const SizedBox(height: AppTheme.spacing32),
          AnimatedButton(label: 'Continue', icon: Icons.arrow_forward_rounded,
              onPressed: _nextStep),
        ],
      ),
    );
  }

  // Step 2: Amount + Rate
  Widget _buildStep2Amount() {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How much?',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ) ?? TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
          const SizedBox(height: AppTheme.spacing8),
          Text('Enter the loan amount and interest rate',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textLight) ?? TextStyle(fontSize: 15, color: AppTheme.textLight)),
          const SizedBox(height: AppTheme.spacing24),

          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [CurrencyInputFormatter()],
            style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800, color: AppTheme.textPrimary) ?? TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
            decoration: InputDecoration(
              labelText: 'Loan Amount',
              prefixIcon: const Icon(Icons.payments_rounded),
              suffixText: settings.currencySymbol,
            ),
          ),
          const SizedBox(height: AppTheme.spacing20),
          TextFormField(
            controller: _rateController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Annual Interest Rate',
              prefixIcon: Icon(Icons.percent_rounded),
              suffixText: '%',
            ),
          ),
          const SizedBox(height: AppTheme.spacing32),
          AnimatedButton(label: 'Continue', icon: Icons.arrow_forward_rounded,
              onPressed: _nextStep),
        ],
      ),
    );
  }

  // Step 3: Schedule
  Widget _buildStep3Schedule() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payment schedule',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ) ?? TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
          const SizedBox(height: AppTheme.spacing8),
          Text('Set the loan term and payment day',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textLight) ?? TextStyle(fontSize: 15, color: AppTheme.textLight)),
          const SizedBox(height: AppTheme.spacing24),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _termController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: _termInYears ? 'Years' : 'Months',
                    prefixIcon: const Icon(Icons.calendar_month_rounded),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Toggle Years/Months
              GestureDetector(
                onTap: () => setState(() => _termInYears = !_termInYears),
                child: AnimatedContainer(
                  duration: AppTheme.animFast,
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing14, vertical: AppTheme.spacing14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: Text(
                    _termInYears ? 'Years' : 'Months',
                    style: TextStyle(fontWeight: FontWeight.w600,
                        color: AppTheme.primary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing20),

          // Payment Day
          Text('Payment Due Day',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary)),
          const SizedBox(height: 10),
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 28,
              itemBuilder: (_, i) {
                final day = i + 1;
                final selected = _paymentDay == day;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _paymentDay = day);
                    },
                    child: AnimatedContainer(
                      duration: AppTheme.animFast,
                      width: 44,
                      decoration: BoxDecoration(
                        gradient: selected ? AppTheme.primaryGradient : null,
                        color: selected ? null : AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(
                          color: selected ? Colors.transparent : AppTheme.divider,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$day',
                          style: TextStyle(
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected ? Colors.white : AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppTheme.spacing32),
          AnimatedButton(label: 'Continue', icon: Icons.arrow_forward_rounded,
              onPressed: _nextStep),
        ],
      ),
    );
  }

  // Step 4: Review
  Widget _buildStep4Review() {
    final settings = Provider.of<SettingsProvider>(context);
    final symbol = settings.currencySymbol;
    final amount = double.tryParse(
      _amountController.text.replaceAll('.', '').replaceAll(',', '.'),
    );
    final rate = double.tryParse(_rateController.text);
    final rawTerm = int.tryParse(_termController.text);
    final termMonths = _termInYears ? (rawTerm ?? 0) * 12 : (rawTerm ?? 0);
    final monthly = _estimatedMonthly;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Review & Confirm',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ) ?? TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
          const SizedBox(height: AppTheme.spacing8),
          Text('Make sure everything looks correct',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textLight) ?? TextStyle(fontSize: 15, color: AppTheme.textLight)),
          const SizedBox(height: AppTheme.spacing24),

          // Summary card
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing20),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              boxShadow: AppTheme.shadowPrimary,
            ),
            child: Column(
              children: [
                buildGradientIcon(_selectedIcon, size: 56),
                const SizedBox(height: AppTheme.spacing12),
                Text(
                  _nameController.text.trim(),
                  style: const TextStyle(color: Colors.white, fontSize: 20,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppTheme.spacingXs),
                Text(
                  kLoanIconLabel(_selectedIcon),
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13),
                ),
                const SizedBox(height: AppTheme.spacing20),
                Divider(color: Colors.white.withValues(alpha: 0.2)),
                const SizedBox(height: AppTheme.spacing12),
                _reviewRow('Amount', formatCurrency(amount ?? 0, symbol: symbol)),
                _reviewRow('Interest Rate', '${rate?.toStringAsFixed(1) ?? '0'}%'),
                _reviewRow('Term', '$termMonths months'),
                _reviewRow('Payment Day', 'Day $_paymentDay'),
                if (monthly != null) ...[
                  const SizedBox(height: 8),
                  Divider(color: Colors.white.withValues(alpha: 0.2)),
                  const SizedBox(height: 8),
                  _reviewRow('Total Interest', 
                      formatCurrency((monthly * termMonths) - (amount ?? 0), symbol: symbol)),
                  _reviewRow('Total Debt',
                      formatCurrency(monthly * termMonths, symbol: symbol), isBold: true),
                  _reviewRow('Est. Monthly',
                      formatCurrency(monthly, symbol: symbol), isBold: true),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),
          AnimatedButton(
            label: 'Create Loan',
            icon: Icons.check_rounded,
            isLoading: _isSaving,
            onPressed: _saveLoan,
          ),
        ],
      ),
    );
  }

  Widget _reviewRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14)),
          Text(value,
              style: TextStyle(color: Colors.white, fontSize: 14,
                  fontWeight: isBold ? FontWeight.w800 : FontWeight.w600)),
        ],
      ),
    );
  }
}
