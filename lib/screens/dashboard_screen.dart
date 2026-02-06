import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/app_scaffold.dart';
import '../models/loan.dart';
import '../providers/settings_provider.dart';
import '../services/storage_service.dart';
import '../core/utils/currency_formatter.dart';

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

    return AppScaffold(
      useSafeArea: false,
      backgroundStyle: AppBackgroundStyle.solid,
      backgroundColor: AppTheme.primary,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Stack(
              children: [
                // 1. Top Header Background & Main Stats
                Container(
                  height: MediaQuery.of(context).size.height * 0.45,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back_ios_new_rounded),
                            color: Colors.white,
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.2,
                              ),
                              padding: const EdgeInsets.all(12),
                            ),
                          ),
                          const Text(
                            'Statistic',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 48), // Balance for back button
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Main Balance Display
                      Center(
                        child: Column(
                          children: [
                            Text(
                              formatCurrency(
                                totalProjected,
                                symbol: settings.currencySymbol,
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -1.0,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Total Income', // As per user image request
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Action Button
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusFull,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.ios_share_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Share Value',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
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

                // 2. Bottom Content Sheet
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.60,
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppTheme.radiusSheet),
                      ),
                    ),
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      physics: const BouncingScrollPhysics(),
                      children: [
                        // Toggle Tabs
                        Row(
                          children: [
                            Expanded(child: _buildToggleTab('Income', true)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildToggleTab('Expenses', false)),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Chart Section
                        SizedBox(
                          height: 200,
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 4,
                              centerSpaceRadius: 40,
                              sections: [
                                PieChartSectionData(
                                  color: AppTheme.primary,
                                  value: totalDebt,
                                  title:
                                      '${((totalDebt / totalProjected) * 100).toStringAsFixed(0)}%',
                                  radius: 60,
                                  titleStyle: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                PieChartSectionData(
                                  color: AppTheme.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                  value: totalInterest,
                                  title:
                                      '${((totalInterest / totalProjected) * 100).toStringAsFixed(0)}%',
                                  radius: 50,
                                  titleStyle: const TextStyle(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Legend
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildLegendItem('Principal', AppTheme.primary),
                            const SizedBox(width: 24),
                            _buildLegendItem(
                              'Interest',
                              AppTheme.primary.withValues(alpha: 0.3),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        _buildSimulatorButton(context),
                        const SizedBox(height: 16),
                        _buildDebtFreeEstimator(settings),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildToggleTab(String title, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        boxShadow: isSelected ? AppTheme.shadowSm : null,
      ),
      child: Center(
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppTheme.textPrimary : AppTheme.textLight,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildSimulatorButton(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/simulator'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          boxShadow: AppTheme.shadowSm,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.speed_rounded, color: AppTheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payoff Simulator',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Calculate savings with extra payments',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppTheme.textLight,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary,
            fontSize: 13,
          ),
        ),
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
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Row(
        children: [
          Icon(Icons.date_range_rounded, color: AppTheme.primary, size: 32),
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
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  'in approx $years years',
                  style: TextStyle(color: AppTheme.textLight, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
