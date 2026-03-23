import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/app_scaffold.dart';
import '../core/widgets/glass_card.dart';
import '../core/utils/currency_formatter.dart';
import '../models/loan.dart';
import '../services/storage_service.dart';
import '../providers/settings_provider.dart';
import 'payoff_simulator_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  List<Loan> _loans = [];
  bool _isLoading = true;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _loadLoans();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadLoans() async {
    final storage = Provider.of<StorageService>(context, listen: false);
    final loans = await storage.getLoans();
    if (mounted) {
      setState(() {
        _loans = loans;
        _isLoading = false;
      });
      _animController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final symbol = settings.currencySymbol;

    if (_isLoading) {
      return const AppScaffold(body: Center(child: CircularProgressIndicator()));
    }

    final activeLoans = _loans.where((l) => !l.isPaidOff).toList();
    final totalDebt = activeLoans.fold(0.0, (s, l) => s + l.totalRemaining);
    final totalPaid = _loans.fold(0.0, (s, l) => s + l.totalPaid);
    final totalInterest = activeLoans.fold(0.0, (s, l) =>
        s + (l.totalContractValue - l.totalAmount));
    final totalPrincipal = activeLoans.fold(0.0, (s, l) => s + l.totalAmount);
    final totalProjected = totalPrincipal + totalInterest;

    // Debt free estimate
    String debtFreeText = 'No active loans';
    if (activeLoans.isNotEmpty) {
      final totalMonthlyPayment = activeLoans.fold(0.0, (s, l) => s + l.monthlyRequired);
      if (totalMonthlyPayment > 0) {
        final monthsLeft = (totalDebt / totalMonthlyPayment).ceil();
        final debtFreeDate = DateTime.now().add(Duration(days: monthsLeft * 30));
        final years = monthsLeft ~/ 12;
        final months = monthsLeft % 12;
        debtFreeText = years > 0
            ? '${debtFreeDate.month}/${debtFreeDate.year} (~${years}y ${months}m)'
            : '${debtFreeDate.month}/${debtFreeDate.year} (~${months}m)';
      }
    }

    final listItems = [
      // Title
      Text(
        'Statistics',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: AppTheme.textPrimary,
        ),
      ),
      const SizedBox(height: 20),

      // Summary header card
      _buildSummaryCard(totalDebt, totalPaid, symbol),
      const SizedBox(height: 16),

      // 3 stat cards row
      _buildStatCards(totalPrincipal, totalInterest, activeLoans.length, symbol),
      const SizedBox(height: 24),

      // Donut chart section
      if (totalProjected > 0) ...[
        Text(
          'Debt Breakdown',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        _buildDonutChart(totalPrincipal, totalInterest, symbol),
        const SizedBox(height: 24),
      ],

      // Per-loan breakdown
      if (activeLoans.isNotEmpty) ...[
        Text(
          'By Loan',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...activeLoans.map((l) => _buildLoanBar(l, totalDebt, symbol)),
        const SizedBox(height: 24),
      ],

      // Debt Free date
      GlassCard(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Icon(Icons.event_available_rounded, color: AppTheme.success),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Estimated Debt Free',
                      style: TextStyle(fontSize: 13, color: AppTheme.textLight)),
                  const SizedBox(height: 2),
                  Text(
                    debtFreeText,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),

      // Payoff Simulator
      GlassCard(
        variant: GlassCardVariant.accent,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PayoffSimulatorScreen()),
          );
        },
        child: Row(
          children: [
            const Icon(Icons.speed_rounded, color: Colors.white, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Payoff Simulator',
                      style: TextStyle(
                          color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                  Text('See how extra payments save you money',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
          ],
        ),
      ),
    ];

    return AppScaffold(
      body: AnimationLimiter(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          itemCount: listItems.length,
          itemBuilder: (context, index) {
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: listItems[index],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard(double totalDebt, double totalPaid, String symbol) {
    return GlassCard(
      variant: GlassCardVariant.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TOTAL REMAINING',
              style: TextStyle(color: Colors.white60, fontSize: 12,
                  fontWeight: FontWeight.w600, letterSpacing: 1.1)),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: totalDebt),
            duration: AppTheme.animSlow,
            curve: AppTheme.curveDefault,
            builder: (_, v, __) => Text(
              formatCurrency(v, symbol: symbol),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.trending_up_rounded, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Paid: ${formatCurrency(totalPaid, symbol: symbol)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
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

  Widget _buildStatCards(double principal, double interest, int count, String symbol) {
    return Row(
      children: [
        Expanded(child: _buildMiniStat('Principal', formatCurrency(principal, symbol: symbol),
            Icons.account_balance_rounded, AppTheme.primary)),
        const SizedBox(width: AppTheme.spacing10),
        Expanded(child: _buildMiniStat('Interest', formatCurrency(interest, symbol: symbol),
            Icons.percent_rounded, AppTheme.warning)),
        const SizedBox(width: AppTheme.spacing10),
        Expanded(child: _buildMiniStat('Active', count.toString(),
            Icons.receipt_long_rounded, AppTheme.accent)),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(AppTheme.spacing14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.05)],
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: AppTheme.spacing10),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonutChart(double principal, double interest, String symbol) {
    final total = principal + interest;
    return GlassCard(
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 4,
                    centerSpaceRadius: 55,
                    startDegreeOffset: -90,
                    sections: [
                      PieChartSectionData(
                        color: AppTheme.primary,
                        value: principal,
                        title: '${(principal / total * 100).toStringAsFixed(0)}%',
                        radius: 45,
                        titleStyle: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      PieChartSectionData(
                        color: AppTheme.warning,
                        value: interest,
                        title: '${(interest / total * 100).toStringAsFixed(0)}%',
                        radius: 38,
                        titleStyle: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // Center label
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Total', style: TextStyle(fontSize: 12, color: AppTheme.textLight)),
                    Text(formatCurrency(total, symbol: symbol),
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend('Principal', AppTheme.primary),
              const SizedBox(width: 24),
              _buildLegend('Interest', AppTheme.warning),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
      ],
    );
  }

  Widget _buildLoanBar(Loan loan, double totalDebt, String symbol) {
    final fraction = totalDebt > 0 ? loan.totalRemaining / totalDebt : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(loan.name, style: TextStyle(fontWeight: FontWeight.w600,
                    fontSize: 14, color: AppTheme.textPrimary)),
                const Spacer(),
                Text(formatCurrency(loan.totalRemaining, symbol: symbol),
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14,
                        color: AppTheme.textPrimary)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: fraction),
                duration: AppTheme.animSlow,
                curve: AppTheme.curveDefault,
                builder: (_, v, __) => LinearProgressIndicator(
                  value: v,
                  minHeight: 6,
                  backgroundColor: AppTheme.surfaceLight,
                  valueColor: AlwaysStoppedAnimation(AppTheme.primary),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text('${(fraction * 100).toStringAsFixed(0)}% of total debt',
                style: TextStyle(fontSize: 11, color: AppTheme.textLight)),
          ],
        ),
      ),
    );
  }
}
