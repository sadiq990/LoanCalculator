import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/app_scaffold.dart';
import '../core/utils/currency_formatter.dart';
import '../models/loan.dart';
import '../models/amortization_entry.dart';
import '../providers/settings_provider.dart';

class AmortizationScreen extends StatefulWidget {
  final Loan loan;
  const AmortizationScreen({super.key, required this.loan});

  @override
  State<AmortizationScreen> createState() => _AmortizationScreenState();
}

class _AmortizationScreenState extends State<AmortizationScreen> {
  double _extraMonthly = 0;

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final symbol = settings.currencySymbol;
    
    final schedule = widget.loan.getOriginalAmortizationSchedule(extraMonthlyPayment: _extraMonthly);
    final original = widget.loan.getOriginalAmortizationSchedule(extraMonthlyPayment: 0);

    final originalInterest = original.fold(0.0, (s, e) => s + e.interest);
    final simulatedInterest = schedule.fold(0.0, (s, e) => s + e.interest);
    final interestSaved = originalInterest - simulatedInterest;
    final monthsSaved = original.length - schedule.length;

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Amortization Schedule'),
      ),
      body: Column(
        children: [
          // Simulation Header
          _buildSimulationHeader(symbol, interestSaved, monthsSaved),
          
          // Table
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: schedule.length,
              itemBuilder: (context, index) {
                final entry = schedule[index];
                return _buildAmortizationRow(entry, symbol, index == schedule.length - 1, entry.isPaid);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulationHeader(String symbol, double saved, int months) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Simulate Extra Payment', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
              Text(formatCurrency(_extraMonthly, symbol: symbol), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.primary)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppTheme.primary,
              inactiveTrackColor: AppTheme.surfaceLight,
              thumbColor: AppTheme.primary,
              trackHeight: 4,
            ),
            child: Slider(
              value: _extraMonthly,
              min: 0,
              max: (widget.loan.monthlyRequired).clamp(500, 5000).toDouble(),
              onChanged: (v) => setState(() => _extraMonthly = (v / 10).round() * 10),
            ),
          ),
          if (saved > 0 || months > 0)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppTheme.success.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: AppTheme.success, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Simulation Result', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.success)),
                        Text(
                          'Save ${formatCurrency(saved, symbol: symbol)} and $months months',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAmortizationRow(AmortizationEntry entry, String symbol, bool isLast, bool isPaid) {
    return AnimatedContainer(
      duration: AppTheme.animFast,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.divider.withValues(alpha: 0.5))),
      ),
      child: Opacity(
        opacity: isPaid ? 0.6 : 1.0,
        child: Row(
          children: [
            // Month bubble
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isPaid ? AppTheme.success.withValues(alpha: 0.15) : AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: isPaid ? Border.all(color: AppTheme.success.withValues(alpha: 0.3)) : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isPaid)
                    const Icon(Icons.check_rounded, color: AppTheme.success, size: 20)
                  else ...[
                    Text('${entry.monthIndex}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                    Text(_getMonthLabel(entry.date), style: TextStyle(fontSize: 9, color: AppTheme.textLight, fontWeight: FontWeight.w600)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
          // Principal / Interest
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Principal', style: TextStyle(fontSize: 12, color: AppTheme.textLight)),
                    Text(formatCurrency(entry.principal, symbol: symbol), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Interest', style: TextStyle(fontSize: 11, color: AppTheme.textLight)),
                    Text(formatCurrency(entry.interest, symbol: symbol), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Remaining balance
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Balance', style: TextStyle(fontSize: 11, color: AppTheme.textLight)),
              Text(formatCurrency(entry.remainingBalance, symbol: symbol), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.primary)),
            ],
          ),
        ],
      ),
      ),
    );
  }

  String _getMonthLabel(DateTime date) {
    const m = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return m[date.month - 1];
  }
}
