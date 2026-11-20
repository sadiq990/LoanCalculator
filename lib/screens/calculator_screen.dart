import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app.dart';
import '../core/constants/app_disclaimers.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/currency_formatter.dart';
import '../core/utils/simple_loan_calculator.dart';
import '../core/widgets/animated_card.dart';
import '../core/widgets/app_scaffold.dart';
import '../models/loan.dart';
import '../providers/settings_provider.dart';
import '../services/storage_service.dart';
import 'add_loan_screen.dart';

class CalculatorScreen extends StatefulWidget {
  final bool isActive;
  const CalculatorScreen({super.key, this.isActive = true});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  static const String _prefAmount = 'calc_last_amount';
  static const String _prefRate = 'calc_last_rate';
  static const String _prefTerm = 'calc_last_term';
  static const String _prefIsYears = 'calc_term_is_years';

  final _amountController = TextEditingController(text: '10000');
  final _rateController = TextEditingController(text: '10');
  final _termController = TextEditingController(text: '12');

  bool _isYears = false;
  Timer? _debounceTimer;

  SimpleLoanCalculatorResult? _calculationResult;
  SimpleLoanCalculatorValidation? _validation;

  List<Loan> _activeLoans = [];
  bool _isLoadingLoans = true;
  StorageService? _storageService;

  @override
  void initState() {
    super.initState();
    // Compute immediate baseline so first frame renders calculated result without delay
    _recalculate(debounce: false);
    _loadSavedInputs();
    _loadLoans();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final storage = Provider.of<StorageService>(context, listen: false);
    if (_storageService != storage) {
      _storageService?.revision.removeListener(_loadLoans);
      _storageService = storage;
      _storageService?.revision.addListener(_loadLoans);
    }
  }

  @override
  void didUpdateWidget(CalculatorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _loadLoans();
    }
  }

  @override
  void dispose() {
    _storageService?.revision.removeListener(_loadLoans);
    _debounceTimer?.cancel();
    _amountController.dispose();
    _rateController.dispose();
    _termController.dispose();
    super.dispose();
  }

  Future<void> _loadLoans() async {
    try {
      final storage = Provider.of<StorageService>(context, listen: false);
      final all = await storage.getLoans();
      if (mounted) {
        setState(() {
          _activeLoans = all.where((l) => !l.isPaidOff).toList();
          _isLoadingLoans = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingLoans = false);
      }
    }
  }

  Future<void> _loadSavedInputs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedAmount = prefs.getString(_prefAmount);
    final savedRate = prefs.getString(_prefRate);
    final savedTerm = prefs.getString(_prefTerm);
    final savedIsYears = prefs.getBool(_prefIsYears);

    if (savedAmount != null && savedAmount.isNotEmpty) {
      _amountController.text = savedAmount;
    }
    if (savedRate != null && savedRate.isNotEmpty) {
      _rateController.text = savedRate;
    }
    if (savedTerm != null && savedTerm.isNotEmpty) {
      _termController.text = savedTerm;
    }
    if (savedIsYears != null) {
      _isYears = savedIsYears;
    }

    _recalculate(debounce: false);
  }

  Future<void> _persistInputs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefAmount, _amountController.text);
    await prefs.setString(_prefRate, _rateController.text);
    await prefs.setString(_prefTerm, _termController.text);
    await prefs.setBool(_prefIsYears, _isYears);
  }

  void _onInputChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 150), () {
      _recalculate(debounce: false);
      _persistInputs();
    });
  }

  void _recalculate({bool debounce = true}) {
    if (debounce) {
      _onInputChanged();
      return;
    }

    final validation = SimpleLoanCalculator.validate(
      amountText: _amountController.text,
      rateText: _rateController.text,
      termText: _termController.text,
      isYears: _isYears,
    );

    SimpleLoanCalculatorResult? result;
    if (validation.isValid) {
      final amount = AddLoanScreen.parseAmount(_amountController.text)!;
      final rate = AddLoanScreen.parseAmount(_rateController.text)!;
      final rawTerm = int.parse(_termController.text.trim());
      final termMonths = _isYears ? rawTerm * 12 : rawTerm;

      result = SimpleLoanCalculator.calculate(
        amount: amount,
        annualRate: rate,
        termMonths: termMonths,
      );
    }

    if (mounted) {
      setState(() {
        _validation = validation;
        _calculationResult = result;
      });
    }
  }

  Future<void> _clearInputs() async {
    HapticFeedback.selectionClick();
    _debounceTimer?.cancel();
    _amountController.clear();
    _rateController.clear();
    _termController.text = '12';
    _isYears = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefAmount);
    await prefs.remove(_prefRate);
    await prefs.remove(_prefTerm);
    await prefs.remove(_prefIsYears);

    if (mounted) {
      setState(() {
        _validation = null;
        _calculationResult = null;
      });
    }
  }

  void _switchToMyLoans() {
    HapticFeedback.selectionClick();
    MainShell.switchToTab(context, MainShellState.tabHome);
  }

  Future<void> _saveAsLoan() async {
    if (_calculationResult == null) return;
    HapticFeedback.selectionClick();

    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddLoanScreen(
          initialAmount: _calculationResult!.amount,
          initialRate: _calculationResult!.annualRate,
          initialTermMonths: _calculationResult!.termMonths,
        ),
      ),
    );

    if (saved == true && mounted) {
      await _loadLoans();
      _switchToMyLoans();
    }
  }

  // Quick preset setters for ABB Bank style interactive feel
  void _setAmount(double amount) {
    HapticFeedback.selectionClick();
    _amountController.text = amount.toInt().toString();
    _recalculate(debounce: false);
    _persistInputs();
  }

  void _setTerm(int term, {bool isYears = false}) {
    HapticFeedback.selectionClick();
    setState(() => _isYears = isYears);
    _termController.text = term.toString();
    _recalculate(debounce: false);
    _persistInputs();
  }

  void _setRate(double rate) {
    HapticFeedback.selectionClick();
    _rateController.text = rate % 1 == 0 ? rate.toInt().toString() : rate.toString();
    _recalculate(debounce: false);
    _persistInputs();
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final symbol = settings.currencySymbol;

    return AppScaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadLoans,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 12),
                if (!_isLoadingLoans && _activeLoans.isNotEmpty)
                  _buildCurrentLoansStrip(symbol),
                const SizedBox(height: 16),
                _buildInputCard(symbol),
                const SizedBox(height: 20),
                if (_calculationResult != null) ...[
                  _buildResultsCard(symbol),
                  const SizedBox(height: 16),
                  _buildSaveAsLoanButton(),
                ] else
                  _buildEmptyHint(),
                const SizedBox(height: 28),
                _buildFooterDisclaimer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Loan Calculator',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Instant live payment & interest simulation',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textLight,
              ),
            ),
          ],
        ),
        Semantics(
          label: 'Clear all calculator inputs',
          button: true,
          child: TextButton.icon(
            onPressed: _clearInputs,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Clear'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.textLight,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentLoansStrip(String symbol) {
    final totalMonthly = _activeLoans.fold<double>(
      0.0,
      (sum, l) => sum + l.monthlyRequired,
    );
    final totalPrincipal = _activeLoans.fold<double>(
      0.0,
      (sum, l) => sum + l.remainingDebt,
    );

    final monthlyStr = formatCurrency(totalMonthly, symbol: symbol);
    final principalStr = formatCurrency(totalPrincipal, symbol: symbol);

    return Semantics(
      label:
          'Your current loans strip: Monthly payments $monthlyStr, Total principal $principalStr. Tap to open My Loans.',
      button: true,
      child: AnimatedCard(
        key: const Key('calc_current_loans_strip'),
        onTap: _switchToMyLoans,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: AppTheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'YOUR CURRENT LOANS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Monthly: $monthlyStr • Principal: $principalStr',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textLight,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard(String symbol) {
    // Current parsed numbers for interactive sliders
    final parsedAmount = AddLoanScreen.parseAmount(_amountController.text) ?? 10000;
    final currentSliderAmount = parsedAmount.clamp(500.0, 100000.0);

    final parsedRate = AddLoanScreen.parseAmount(_rateController.text) ?? 10.0;
    final currentSliderRate = parsedRate.clamp(0.0, 30.0);

    final parsedTerm = int.tryParse(_termController.text.trim()) ?? 12;
    final maxTerm = _isYears ? 30.0 : 60.0;
    final currentSliderTerm = parsedTerm.toDouble().clamp(1.0, maxTerm);

    return AnimatedCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Loan Amount Section (Slider + Text Input + Preset Chips)
          Semantics(
            label: 'Loan amount input field',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Loan Amount',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Slider up to 100 000 (Manual: any amount)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  key: const Key('calc_amount_input'),
                  controller: _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.done,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 14, right: 8),
                      child: Text(
                        symbol,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    prefixIconConstraints:
                        const BoxConstraints(minWidth: 0, minHeight: 0),
                    hintText: 'e.g. 10000, 100.000 or 500.000',
                    errorText: _amountController.text.isNotEmpty
                        ? _validation?.amountError
                        : null,
                  ),
                  onChanged: (_) => _recalculate(debounce: true),
                ),
                const SizedBox(height: 6),
                // Interactive Slider up to 100,000 like ABB Bank
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                    activeTrackColor: AppTheme.primary,
                    inactiveTrackColor: AppTheme.surfaceLight,
                    thumbColor: AppTheme.primary,
                    overlayColor: AppTheme.primary.withValues(alpha: 0.15),
                  ),
                  child: Slider(
                    value: currentSliderAmount,
                    min: 500,
                    max: 100000,
                    onChanged: (val) {
                      final snapped = val < 20000
                          ? (val / 500).round() * 500.0
                          : (val / 1000).round() * 1000.0;
                      _setAmount(snapped);
                    },
                  ),
                ),
                // Quick chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [1000.0, 5000.0, 10000.0, 20000.0, 50000.0, 100000.0]
                        .map((amt) => _buildQuickChip(
                              label: '$symbol${amt.toInt()}',
                              isSelected: parsedAmount == amt,
                              onTap: () => _setAmount(amt),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. Term Section (Months / Years toggle + Slider + Chips)
          Semantics(
            label: 'Loan term input and unit selection',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Term',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    CupertinoSlidingSegmentedControl<bool>(
                      groupValue: _isYears,
                      children: const {
                        false: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('Months', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                        true: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('Years', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      },
                      onValueChanged: (val) {
                        if (val != null && val != _isYears) {
                          HapticFeedback.selectionClick();
                          setState(() => _isYears = val);
                          _recalculate(debounce: false);
                          _persistInputs();
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  key: const Key('calc_term_input'),
                  controller: _termController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    hintText: _isYears ? 'e.g. 1' : 'e.g. 12',
                    suffixText: _isYears ? 'years' : 'months',
                    errorText: _termController.text.isNotEmpty
                        ? _validation?.termError
                        : null,
                  ),
                  onChanged: (_) => _recalculate(debounce: true),
                ),
                const SizedBox(height: 6),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                    activeTrackColor: AppTheme.primary,
                    inactiveTrackColor: AppTheme.surfaceLight,
                    thumbColor: AppTheme.primary,
                    overlayColor: AppTheme.primary.withValues(alpha: 0.15),
                  ),
                  child: Slider(
                    value: currentSliderTerm,
                    min: 1,
                    max: maxTerm,
                    divisions: _isYears ? 29 : 59,
                    onChanged: (val) {
                      _setTerm(val.round(), isYears: _isYears);
                    },
                  ),
                ),
                // Quick term chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _isYears
                        ? [1, 2, 3, 5, 10, 20]
                            .map((yr) => _buildQuickChip(
                                  label: '$yr yr${yr > 1 ? 's' : ''}',
                                  isSelected: parsedTerm == yr && _isYears,
                                  onTap: () => _setTerm(yr, isYears: true),
                                ))
                            .toList()
                        : [3, 6, 12, 24, 36, 48, 60]
                            .map((m) => _buildQuickChip(
                                  label: '$m months',
                                  isSelected: parsedTerm == m && !_isYears,
                                  onTap: () => _setTerm(m, isYears: false),
                                ))
                            .toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. Annual Interest Rate Section (Slider + Chips)
          Semantics(
            label: 'Annual interest rate input field in percent',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Annual Interest Rate (%)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      '0% — 30%+',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  key: const Key('calc_rate_input'),
                  controller: _rateController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.done,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    suffixIcon: const Padding(
                      padding: EdgeInsets.only(right: 14),
                      child: Icon(Icons.percent_rounded, size: 18),
                    ),
                    suffixIconConstraints:
                        const BoxConstraints(minWidth: 0, minHeight: 0),
                    hintText: 'e.g. 10.0',
                    errorText: _rateController.text.isNotEmpty
                        ? _validation?.rateError
                        : null,
                  ),
                  onChanged: (_) => _recalculate(debounce: true),
                ),
                const SizedBox(height: 6),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                    activeTrackColor: AppTheme.primary,
                    inactiveTrackColor: AppTheme.surfaceLight,
                    thumbColor: AppTheme.primary,
                    overlayColor: AppTheme.primary.withValues(alpha: 0.15),
                  ),
                  child: Slider(
                    value: currentSliderRate,
                    min: 0,
                    max: 30,
                    divisions: 60,
                    onChanged: (val) {
                      _setRate(val);
                    },
                  ),
                ),
                // Quick rate chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [0.0, 5.0, 8.0, 10.0, 14.0, 18.0]
                        .map((r) => _buildQuickChip(
                              label: '${r.toStringAsFixed(r % 1 == 0 ? 0 : 1)}%',
                              isSelected: (parsedRate - r).abs() < 0.05,
                              onTap: () => _setRate(r),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6, bottom: 2),
      child: ActionChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
        backgroundColor:
            isSelected ? AppTheme.primary : AppTheme.surfaceLight,
        side: BorderSide(
          color: isSelected
              ? AppTheme.primary
              : AppTheme.divider.withValues(alpha: 0.6),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildResultsCard(String symbol) {
    final res = _calculationResult!;
    final monthlyStr = formatCurrency(res.monthlyPayment, symbol: symbol);
    final interestStr = formatCurrency(res.totalInterest, symbol: symbol);
    final totalRepaidStr = formatCurrency(res.totalRepaid, symbol: symbol);

    double activeMonthlySum = 0.0;
    if (_activeLoans.isNotEmpty) {
      activeMonthlySum = _activeLoans.fold<double>(
        0.0,
        (sum, l) => sum + l.monthlyRequired,
      );
    }

    return AnimatedCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Monthly payment (Bank-grade Hero Display)
          Semantics(
            label: 'Monthly payment: $monthlyStr',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Monthly payment',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textLight,
                        letterSpacing: 0.2,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Live calculation',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  monthlyStr,
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.0,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),

          // 2. Extra interest you pay (total interest) & 3. Total you repay
          Row(
            children: [
              Expanded(
                child: Semantics(
                  label: 'Extra interest you pay: $interestStr',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Extra interest',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        interestStr,
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Semantics(
                  label: 'Total you repay: $totalRepaidStr',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total repay',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        totalRepaidStr,
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Plain sentence summary
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  res.plainSentence((v) => formatCurrency(v, symbol: symbol)),
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  res.interestSummary(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textLight,
                  ),
                ),
                if (res.hasDifferentLastPayment && res.lastPayment != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Last payment: ${formatCurrency(res.lastPayment!, symbol: symbol)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Strip connection: Total monthly payments with this loan
          if (_activeLoans.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                'Total monthly payments with this loan: current ${formatCurrency(activeMonthlySum, symbol: symbol)} + new ${formatCurrency(res.monthlyPayment, symbol: symbol)} = ${formatCurrency(activeMonthlySum + res.monthlyPayment, symbol: symbol)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryDark,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSaveAsLoanButton() {
    return Semantics(
      label: 'Save this calculation as a real loan in My Loans',
      button: true,
      child: FilledButton.icon(
        key: const Key('calc_save_as_loan_button'),
        onPressed: _saveAsLoan,
        icon: const Icon(Icons.add_circle_outline_rounded),
        label: const Text(
          'Save as loan',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyHint() {
    return AnimatedCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.calculate_outlined,
            size: 40,
            color: AppTheme.textLight,
          ),
          const SizedBox(height: 12),
          Text(
            'Enter amount, interest rate, and term to see your live loan calculation.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textLight,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterDisclaimer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        AppDisclaimers.financialDisclaimer,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          color: AppTheme.textLight,
          height: 1.4,
        ),
      ),
    );
  }
}
