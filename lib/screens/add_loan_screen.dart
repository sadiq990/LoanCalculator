import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import '../core/theme/app_theme.dart';
import '../core/widgets/animated_button.dart';
import '../models/loan.dart';
import '../services/storage_service.dart';
import '../core/utils/input_formatters.dart';
import '../core/constants/loan_icons.dart';

/// Screen to add a new loan
class AddLoanScreen extends StatefulWidget {
  const AddLoanScreen({super.key});

  @override
  State<AddLoanScreen> createState() => _AddLoanScreenState();
}

class _AddLoanScreenState extends State<AddLoanScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _rateController = TextEditingController();
  final _monthsController = TextEditingController();

  final _storage = StorageService();

  int _selectedDay = 15;
  String _selectedIcon = 'default';
  bool _isYears = false; // Toggle for term unit
  bool _isLoading = false;
  double _calculatedMonthlyPayment = 0;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: AppTheme.animMedium,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: AppTheme.curveDefault),
    );
    _animController.forward();

    _amountController.addListener(_updateEstimate);
    _rateController.addListener(_updateEstimate);
    _monthsController.addListener(_updateEstimate);
  }

  void _updateEstimate() {
    // Remove commas for parsing
    final amountText = _amountController.text.replaceAll(',', '');
    final amount = double.tryParse(amountText) ?? 0;

    final rate = double.tryParse(_rateController.text) ?? 0;

    int months = int.tryParse(_monthsController.text) ?? 0;
    if (_isYears) months *= 12; // Convert years to months for calc

    if (amount > 0 && months > 0) {
      double monthly;
      if (rate <= 0) {
        monthly = amount / months;
      } else {
        final r = (rate / 100) / 12;
        monthly = amount * r * (pow(1 + r, months)) / (pow(1 + r, months) - 1);
      }
      setState(() {
        _calculatedMonthlyPayment = monthly;
      });
    } else {
      if (_calculatedMonthlyPayment != 0) {
        setState(() => _calculatedMonthlyPayment = 0);
      }
    }
  }

  void _toggleTermUnit() {
    setState(() {
      _isYears = !_isYears;
      _updateEstimate(); // Recalculate with new unit
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _amountController.dispose();
    _rateController.dispose();
    _monthsController.dispose();
    super.dispose();
  }

  Future<void> _saveLoan() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    final rawAmount = _amountController.text.replaceAll(RegExp(r'[^0-9.]'), '');
    final amount = double.tryParse(rawAmount);
    final rate = double.tryParse(_rateController.text.trim());
    int? months = int.tryParse(_monthsController.text.trim());
    if (_isYears && months != null) {
      months *= 12;
    }

    if (amount == null || amount <= 0 || rate == null || rate < 0 || months == null || months <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid loan details'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    var didSave = false;
    try {
      final loan = Loan(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        totalAmount: amount,
        interestRate: rate,
        termMonths: months,
        paymentDay: _selectedDay,
        createdAt: DateTime.now(),
        iconId: _selectedIcon,
      );

      await _storage.addLoan(loan);
      didSave = true;

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save loan. Please try again.'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted && !didSave) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: AnimatedIconButton(
          icon: Icons.close_rounded,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Add New Loan'),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildIconPicker(),
                const SizedBox(height: 24),

                // Name
                _buildTextField(
                  controller: _nameController,
                  label: 'Loan Name',
                  hint: 'e.g., Tesla Model 3',
                  icon: Icons.label_outline_rounded,
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Required'
                      : null,
                ),
                const SizedBox(height: 20),

                // Amount (Formatted)
                _buildTextField(
                  controller: _amountController,
                  label: 'Total Loan Amount',
                  hint: '20,000',
                  icon: Icons.account_balance_outlined,
                  keyboardType: TextInputType.number,
                  inputFormatters: [CurrencyInputFormatter()],
                  suffix: '₼',
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    final v = double.tryParse(value.replaceAll(',', ''));
                    if (v == null || v <= 0) return 'Invalid amount';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: _buildTextField(
                        controller: _rateController,
                        label: 'Interest (%)',
                        hint: '14.5',
                        icon: Icons.percent_rounded,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        suffix: '%',
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Req';
                          final v = double.tryParse(value);
                          if (v == null) return 'Invalid';
                          if (v < 0) return 'Positive only';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 5,
                      child: Stack(
                        children: [
                          _buildTextField(
                            controller: _monthsController,
                            label: _isYears ? 'Term (Years)' : 'Term (Months)',
                            hint: _isYears ? '3' : '36',
                            icon: Icons.calendar_month_rounded,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Req';
                              final v = int.tryParse(value);
                              if (v == null || v <= 0) return 'Must be > 0';
                              return null;
                            },
                          ),
                          Positioned(
                            right: 0,
                            top: 28,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: TextButton(
                                onPressed: _toggleTermUnit,
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  backgroundColor: AppTheme.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  foregroundColor: AppTheme.primary,
                                ),
                                child: Text(
                                  _isYears ? 'Years' : 'Months',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Calculated Estimate Card
                AnimatedOpacity(
                  opacity: _calculatedMonthlyPayment > 0 ? 1.0 : 0.0,
                  duration: AppTheme.animMedium,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Estimated Monthly:',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          formatCurrency(_calculatedMonthlyPayment),
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                _buildDayPicker(),
                const SizedBox(height: 40),
                AnimatedButton(
                  label: 'Create Loan',
                  icon: Icons.add_chart_rounded,
                  isLoading: _isLoading,
                  onPressed: _saveLoan,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category Icon',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 60,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: kLoanIcons.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final key = kLoanIcons.keys.elementAt(index);
              final icon = kLoanIcons[key]!;
              final color = kIconColors[key]!;
              final isSelected = _selectedIcon == key;

              return GestureDetector(
                onTap: () => setState(() => _selectedIcon = key),
                child: AnimatedContainer(
                  duration: AppTheme.animFast,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withValues(alpha: 0.15)
                        : AppTheme.surfaceLight,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? color : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? color : AppTheme.textLight,
                    size: 24,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.shadowPrimary,
      ),
      child: const Row(
        children: [
          Icon(Icons.auto_awesome, color: Colors.white, size: 24),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Let\'s set you up!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Fill in the details below.',
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? suffix,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppTheme.textLight, size: 20),
            suffixText: suffix,
            contentPadding: const EdgeInsets.only(
              left: 48,
              right: 16,
              top: 16,
              bottom: 16,
            ),
            suffixStyle: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDayPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monthly Payment Due Day',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.divider),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedDay,
              isExpanded: true,
              icon: Icon(
                Icons.expand_more_rounded,
                color: AppTheme.textSecondary,
              ),
              items: List.generate(28, (i) => i + 1).map((day) {
                return DropdownMenuItem(
                  value: day,
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 16,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Day $day of every month',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedDay = value);
              },
            ),
          ),
        ),
      ],
    );
  }
}


