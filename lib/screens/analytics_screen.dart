import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/app_scaffold.dart';
import '../core/widgets/animated_card.dart';
import '../core/utils/currency_formatter.dart';
import '../models/loan.dart';
import '../services/storage_service.dart';
import '../providers/settings_provider.dart';

/// Analytics Dashboard Screen with financial insights and charts
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  List<Loan> _loans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final storage = Provider.of<StorageService>(context, listen: false);
    final loans = await storage.getLoans();
    if (mounted) {
      setState(() {
        _loans = loans;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AppScaffold(
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_loans.isEmpty) {
      return _buildEmptyState();
    }

    return AppScaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildOverviewCards(),
            const SizedBox(height: 20),
            _buildPrincipalVsInterestChart(),
            const SizedBox(height: 20),
            _buildLoansComparisonChart(),
            const SizedBox(height: 20),
            _buildMonthlyPaymentsChart(),
            const SizedBox(height: 20),
            _buildPayoffTimeline(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return AppScaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: 80, color: AppTheme.textLight),
            const SizedBox(height: 16),
            Text(
              'No Data Available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add a loan to see analytics',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analytics',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Financial insights & statistics',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textLight,
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewCards() {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final symbol = settings.currencySymbol;

    final totalPrincipal = _loans.fold<double>(0, (sum, l) => sum + l.totalAmount);
    final totalPaid = _loans.fold<double>(0, (sum, l) => sum + l.totalPaid);
    final totalRemaining = _loans.fold<double>(0, (sum, l) => sum + l.remainingDebt);
    final totalInterest = _loans.fold<double>(
      0,
      (sum, l) => sum + l.getOriginalAmortizationSchedule().fold<double>(0, (s, e) => s + e.interest),
    );

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Principal',
                formatCurrency(totalPrincipal, symbol: symbol),
                Icons.account_balance_wallet_outlined,
                AppTheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Total Paid',
                formatCurrency(totalPaid, symbol: symbol),
                Icons.check_circle_outline,
                AppTheme.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Remaining',
                formatCurrency(totalRemaining, symbol: symbol),
                Icons.pending_outlined,
                AppTheme.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Total Interest',
                formatCurrency(totalInterest, symbol: symbol),
                Icons.trending_up,
                AppTheme.error,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return AnimatedCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Text(
                  '${_loans.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrincipalVsInterestChart() {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final symbol = settings.currencySymbol;

    final totalPrincipal = _loans.fold<double>(0, (sum, l) => sum + l.totalAmount);
    final totalInterest = _loans.fold<double>(
      0,
      (sum, l) => sum + l.getOriginalAmortizationSchedule().fold<double>(0, (s, e) => s + e.interest),
    );
    final total = totalPrincipal + totalInterest;

    return AnimatedCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primary.withValues(alpha: 0.15),
                      AppTheme.primary.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: const Icon(Icons.pie_chart_outline, color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Principal vs Interest',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 50,
                      sections: [
                        PieChartSectionData(
                          value: totalPrincipal,
                          title: '${(totalPrincipal / total * 100).toStringAsFixed(1)}%',
                          color: AppTheme.primary,
                          radius: 60,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          value: totalInterest,
                          title: '${(totalInterest / total * 100).toStringAsFixed(1)}%',
                          color: AppTheme.error,
                          radius: 60,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegendItem('Principal', formatCurrency(totalPrincipal, symbol: symbol), AppTheme.primary),
                    const SizedBox(height: 12),
                    _buildLegendItem('Interest', formatCurrency(totalInterest, symbol: symbol), AppTheme.error),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: AppTheme.textLight)),
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          ],
        ),
      ],
    );
  }

  Widget _buildLoansComparisonChart() {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final symbol = settings.currencySymbol;

    final activeLoans = _loans.where((l) => !l.isPaidOff).toList();
    if (activeLoans.isEmpty) return const SizedBox.shrink();

    return AnimatedCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.accent.withValues(alpha: 0.15),
                      AppTheme.accent.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(Icons.bar_chart_rounded, color: AppTheme.accent, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Loans Comparison',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: activeLoans.map((l) => l.totalAmount).reduce((a, b) => a > b ? a : b) * 1.2,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final loan = activeLoans[group.x.toInt()];
                      return BarTooltipItem(
                        '${loan.name}\n${formatCurrency(rod.toY, symbol: symbol)}',
                        const TextStyle(color: Colors.white, fontSize: 12),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= activeLoans.length) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            activeLoans[value.toInt()].name.length > 8
                                ? '${activeLoans[value.toInt()].name.substring(0, 8)}...'
                                : activeLoans[value.toInt()].name,
                            style: TextStyle(fontSize: 10, color: AppTheme.textLight),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: activeLoans.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.totalAmount,
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primary,
                            AppTheme.primary.withValues(alpha: 0.7),
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 24,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyPaymentsChart() {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final symbol = settings.currencySymbol;

    final totalMonthly = _loans.fold<double>(0, (sum, l) => sum + l.monthlyRequired);

    return AnimatedCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.success.withValues(alpha: 0.15),
                      AppTheme.success.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: const Icon(Icons.calendar_month_rounded, color: AppTheme.success, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Monthly Obligations',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.success.withValues(alpha: 0.1),
                  AppTheme.success.withValues(alpha: 0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: AppTheme.success.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Text(
                      'Total Monthly Payment',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formatCurrency(totalMonthly, symbol: symbol),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.success,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_loans.where((l) => !l.isPaidOff).length} active loans',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayoffTimeline() {
    final activeLoans = _loans.where((l) => !l.isPaidOff).toList();
    if (activeLoans.isEmpty) return const SizedBox.shrink();

    // Calculate payoff dates
    final payoffData = activeLoans.map((loan) {
      final schedule = loan.getOriginalAmortizationSchedule();
      final payoffDate = schedule.isNotEmpty ? schedule.last.date : loan.createdAt;
      return {
        'loan': loan,
        'payoffDate': payoffDate,
      };
    }).toList();

    // Sort by payoff date
    payoffData.sort((a, b) => (a['payoffDate'] as DateTime).compareTo(b['payoffDate'] as DateTime));

    return AnimatedCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.warning.withValues(alpha: 0.15),
                      AppTheme.warning.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(Icons.timeline_rounded, color: AppTheme.warning, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Payoff Timeline',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...payoffData.asMap().entries.map((entry) {
            final index = entry.key;
            final data = entry.value;
            final loan = data['loan'] as Loan;
            final payoffDate = data['payoffDate'] as DateTime;
            final months = _monthsUntilPayoff(payoffDate);

            return Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: index == payoffData.length - 1 ? AppTheme.success : AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    if (index < payoffData.length - 1)
                      Container(
                        width: 2,
                        height: 40,
                        color: AppTheme.divider,
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    margin: EdgeInsets.only(bottom: index < payoffData.length - 1 ? 16 : 0),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loan.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDate(payoffDate),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: months <= 12 ? AppTheme.success.withValues(alpha: 0.1) : AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                          ),
                          child: Text(
                            months <= 12 ? '$months mo' : '${(months / 12).toStringAsFixed(1)} yr',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: months <= 12 ? AppTheme.success : AppTheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  int _monthsUntilPayoff(DateTime payoffDate) {
    final now = DateTime.now();
    return (payoffDate.year - now.year) * 12 + (payoffDate.month - now.month);
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.year}';
  }
}
