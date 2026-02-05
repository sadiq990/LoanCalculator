import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../models/loan.dart';
import '../providers/settings_provider.dart';
import '../services/storage_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final StorageService _storage = StorageService();
  List<Loan> _loans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final loans = await _storage.getLoans();
    if (mounted) {
      setState(() {
        _loans = loans;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    // Calculate Stats
    double totalDebt = 0;
    double totalInterest = 0;

    for (var loan in _loans) {
      totalDebt += loan.remainingDebt;
      // Estimate total interest (simplified)
      final schedule = loan.getAmortizationSchedule(extraMonthlyPayment: 0);
      totalInterest += schedule.fold(0.0, (sum, entry) => sum + entry.interest);
    }

    double totalProjected = totalDebt + totalInterest;

    return Scaffold(
      appBar: AppBar(
        title: Text('Analytics'),
        backgroundColor: AppTheme.background,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loans.isEmpty
          ? const Center(child: Text('No loans to analyze'))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildSummaryCard(
                  totalDebt,
                  totalInterest,
                  totalProjected,
                  settings,
                ),
                const SizedBox(height: 24),
                Text(
                  'Cost Breakdown',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 250,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: [
                        PieChartSectionData(
                          color: AppTheme.primary,
                          value: totalDebt,
                          title:
                              '${((totalDebt / totalProjected) * 100).toStringAsFixed(0)}%',
                          radius: 50,
                          titleStyle: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        PieChartSectionData(
                          color: AppTheme.error,
                          value: totalInterest,
                          title:
                              '${((totalInterest / totalProjected) * 100).toStringAsFixed(0)}%',
                          radius: 60,
                          titleStyle: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _buildLegendItem('Principal', AppTheme.primary),
                _buildLegendItem('Future Interest', AppTheme.error),
                const SizedBox(height: 24),
                _buildDebtFreeEstimator(settings),
              ],
            ),
    );
  }

  Widget _buildSummaryCard(
    double debt,
    double interest,
    double total,
    SettingsProvider settings,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: AppTheme.shadowPrimary,
      ),
      child: Column(
        children: [
          Text(
            'PROJECTED TOTAL COST',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formatCurrency(total, symbol: settings.currencySymbol),
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Principal',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      formatCurrency(debt, symbol: settings.currencySymbol),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Interest',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      formatCurrency(interest, symbol: settings.currencySymbol),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildDebtFreeEstimator(SettingsProvider settings) {
    // Determine max payoff date
    DateTime maxDate = DateTime.now();
    for (var loan in _loans) {
      final schedule = loan.getAmortizationSchedule();
      if (schedule.isNotEmpty) {
        if (schedule.last.date.isAfter(maxDate)) {
          maxDate = schedule.last.date;
        }
      }
    }

    // Calculate duration
    final diff = maxDate.difference(DateTime.now());
    final years = (diff.inDays / 365).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          Icon(
            Icons.date_range_rounded,
            color: AppTheme.primary,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Debt Free Date',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
                Text(
                  '${maxDate.year}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'in approx $years years',
                  style: TextStyle(
                    color: AppTheme.textLight,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


