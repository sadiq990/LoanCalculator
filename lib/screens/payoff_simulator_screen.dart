import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/app_scaffold.dart';
import '../core/widgets/glass_card.dart';
import '../models/loan.dart';
import '../services/storage_service.dart';
import '../providers/settings_provider.dart';
import 'package:provider/provider.dart';
import '../core/utils/currency_formatter.dart';

class PayoffSimulatorScreen extends StatefulWidget {
  const PayoffSimulatorScreen({super.key});

  @override
  State<PayoffSimulatorScreen> createState() => _PayoffSimulatorScreenState();
}

class _PayoffSimulatorScreenState extends State<PayoffSimulatorScreen> {
  final StorageService _storage = StorageService();
  List<Loan> _loans = [];
  Loan? _selectedLoan;
  bool _isLoading = true;
  double _extraPayment = 0;

  @override
  void initState() {
    super.initState();
    _loadLoans();
  }

  Future<void> _loadLoans() async {
    final loans = await _storage.getLoans();
    // Filter active loans only
    final activeLoans = loans.where((l) => !l.isPaidOff).toList();

    if (mounted) {
      setState(() {
        _loans = activeLoans;
        if (activeLoans.isNotEmpty) {
          _selectedLoan = activeLoans.first;
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AppScaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_loans.isEmpty) {
      return AppScaffold(
        useSafeArea: false,
        appBar: AppBar(title: const Text('Payoff Simulator')),
        body: Center(
          child: Text(
            'No active loans to simulate',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
      );
    }

    return AppScaffold(
      useSafeArea: false,
      appBar: AppBar(
        title: const Text('Payoff Simulator'),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildControls(),
            const SizedBox(height: 24),
            if (_selectedLoan != null) _buildResults(),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final successTone = isDark
        ? AppTheme.success
        : AppTheme.success.withValues(alpha: 0.85);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SIMULATION SETTINGS',
            style: TextStyle(
              color: AppTheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          // Loan Selector
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Select Loan',
              prefixIcon: Icon(Icons.account_balance_wallet_rounded),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedLoan?.id,
                dropdownColor: AppTheme.cardBg,
                style: TextStyle(color: AppTheme.textPrimary),
                icon: const Icon(
                  Icons.arrow_drop_down_rounded,
                  color: AppTheme.primary,
                ),
                isExpanded: true,
                items: _loans.map((loan) {
                  return DropdownMenuItem(
                    value: loan.id,
                    child: Text(loan.name, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    if (value != null) {
                      _selectedLoan = _loans.firstWhere((l) => l.id == value);
                      _extraPayment = 0; // Reset slider on loan change
                    }
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Extra Payment Slider
          Text(
            'Extra Monthly Payment',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                formatCurrency(_extraPayment),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: successTone,
                ),
              ),
              const Spacer(),
              Text(
                'Max: ${formatCurrency(_selectedLoan?.monthlyRequired ?? 0)}',
                style: TextStyle(color: AppTheme.textLight, fontSize: 12),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: successTone,
              inactiveTrackColor: AppTheme.surfaceLight,
              thumbColor: Colors.white,
              overlayColor: successTone.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: _extraPayment,
              min: 0,
              max: (_selectedLoan?.monthlyRequired ?? 1000).toDouble(),
              divisions: 100, // Granularity
              label: _extraPayment.toStringAsFixed(0),
              onChanged: (value) => setState(() => _extraPayment = value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    final loan = _selectedLoan!;
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final successTone = isDark
        ? AppTheme.success
        : AppTheme.success.withValues(alpha: 0.85);

    // Calculate Original Schedule
    final originalSchedule = loan.getAmortizationSchedule(
      extraMonthlyPayment: 0,
    );
    final originalTotalInterest = originalSchedule.fold(
      0.0,
      (sum, e) => sum + e.interest,
    );
    final originalMonths = originalSchedule.length;
    final originalPayoffDate = originalSchedule.isNotEmpty
        ? originalSchedule.last.date
        : DateTime.now();

    // Calculate Simulated Schedule
    final simulatedSchedule = loan.getAmortizationSchedule(
      extraMonthlyPayment: _extraPayment,
    );
    final simulatedTotalInterest = simulatedSchedule.fold(
      0.0,
      (sum, e) => sum + e.interest,
    );
    final simulatedMonths = simulatedSchedule.length;
    final simulatedPayoffDate = simulatedSchedule.isNotEmpty
        ? simulatedSchedule.last.date
        : DateTime.now();

    // Deltas
    final interestSaved = originalTotalInterest - simulatedTotalInterest;
    final monthsSaved = originalMonths - simulatedMonths;

    return Column(
      children: [
        GlassCard(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildResultItem(
                    'Interest Saved',
                    formatCurrency(
                      interestSaved,
                      symbol: settings.currencySymbol,
                    ),
                    AppTheme.warning,
                  ),
                  Container(width: 1, height: 40, color: AppTheme.divider),
                  _buildResultItem(
                    'Time Saved',
                    '$monthsSaved months',
                    AppTheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Divider(color: AppTheme.divider),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('New Payoff Date'),
                  Text(
                    '${simulatedPayoffDate.month}/${simulatedPayoffDate.year}',
                    style: TextStyle(
                      color: successTone,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Original: ${originalPayoffDate.month}/${originalPayoffDate.year}',
                    style: TextStyle(color: AppTheme.textLight, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Comparison Chart
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceEvenly,
              maxY: (originalTotalInterest + loan.totalAmount) * 1.1,
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                show: true,
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      final label = value.toInt() == 0 ? 'Original' : 'New';
                      return SideTitleWidget(
                        meta: meta,
                        space: 6,
                        child: Text(
                          label,
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(show: false),
              barGroups: [
                BarChartGroupData(
                  x: 0,
                  barRods: [
                    BarChartRodData(
                      toY: originalTotalInterest + loan.totalAmount,
                      color: AppTheme.surfaceLight,
                      width: 40,
                      borderRadius: BorderRadius.circular(8),
                      backDrawRodData: BackgroundBarChartRodData(show: false),
                    ),
                  ],
                ),
                BarChartGroupData(
                  x: 1,
                  barRods: [
                    BarChartRodData(
                      toY: simulatedTotalInterest + loan.totalAmount,
                      color: successTone,
                      width: 40,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Total Cost Comparison',
          style: TextStyle(color: AppTheme.textLight, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildResultItem(String label, String value, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final valueColor = isDark ? color : color.withValues(alpha: 0.9);

    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}
