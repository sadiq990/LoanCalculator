import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/app_scaffold.dart';
import '../core/widgets/glass_card.dart';
import '../core/utils/currency_formatter.dart';
import '../models/loan.dart';
import '../services/storage_service.dart';
import '../providers/settings_provider.dart';

class PayoffSimulatorScreen extends StatefulWidget {
  const PayoffSimulatorScreen({super.key});

  @override
  State<PayoffSimulatorScreen> createState() => _PayoffSimulatorScreenState();
}

class _PayoffSimulatorScreenState extends State<PayoffSimulatorScreen> {
  final StorageService _storage = StorageService();
  List<Loan> _loans = [];
  Loan? _selectedLoan;
  double _extraPayment = 100;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLoans();
  }

  Future<void> _loadLoans() async {
    final loans = await _storage.getLoans();
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
    final settings = Provider.of<SettingsProvider>(context);
    final symbol = settings.currencySymbol;

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Payoff Simulator'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loans.isEmpty
              ? _buildEmptyState()
              : _buildContent(symbol),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.speed_rounded, size: 64, color: AppTheme.textLight),
          const SizedBox(height: 16),
          Text('No active loans to simulate',
              style: TextStyle(fontSize: 18, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildContent(String symbol) {
    if (_selectedLoan == null) return const SizedBox();

    final simulation = _selectedLoan!.simulatePayoff(extraMonthlyPayment: _extraPayment);
    final original = _selectedLoan!.simulatePayoff(extraMonthlyPayment: 0);

    final interestSaved = original.totalInterest - simulation.totalInterest;
    final monthsSaved = original.monthsToPayoff - simulation.monthsToPayoff;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Select Loan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textLight)),
        const SizedBox(height: 10),
        _buildLoanSelector(),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _buildResultCard(
                'Interest Saved',
                formatCurrency(interestSaved, symbol: symbol),
                Icons.savings_rounded,
                AppTheme.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildResultCard(
                'Time Saved',
                '$monthsSaved Months',
                Icons.timer_rounded,
                AppTheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Extra Monthly Payment',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                  Text(formatCurrency(_extraPayment, symbol: symbol),
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.primary)),
                ],
              ),
              const SizedBox(height: 12),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppTheme.primary,
                  inactiveTrackColor: AppTheme.surfaceLight,
                  thumbColor: AppTheme.primary,
                  trackHeight: 6,
                ),
                child: Slider(
                  value: _extraPayment,
                  min: 0,
                  max: (_selectedLoan!.monthlyRequired * 2).clamp(500, 5000).toDouble(),
                  onChanged: (v) => setState(() => _extraPayment = (v / 10).round() * 10),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Cost Comparison', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        const SizedBox(height: 16),
        _buildComparisonChart(original, simulation, symbol),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildLoanSelector() {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: DropdownButtonHideUnderline(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButton<Loan>(
            value: _selectedLoan,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            items: _loans.map((l) {
              return DropdownMenuItem(
                value: l,
                child: Text(l.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              );
            }).toList(),
            onChanged: (l) {
              if (l != null) setState(() => _selectedLoan = l);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(String label, String value, IconData icon, Color color) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(label, style: TextStyle(fontSize: 12, color: AppTheme.textLight)),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildComparisonChart(PayoffSimulation original, PayoffSimulation simulated, String symbol) {
    return AspectRatio(
      aspectRatio: 1.5,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: original.totalInterest * 1.2,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final titles = ['Current', 'With Extra'];
                  final index = value.toInt();
                  if (index < 0 || index >= titles.length) return const SizedBox();
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(titles[index], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: [
            BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: original.totalInterest, color: Colors.grey, width: 40)]),
            BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: simulated.totalInterest, color: AppTheme.primary, width: 40)]),
          ],
        ),
      ),
    );
  }
}
