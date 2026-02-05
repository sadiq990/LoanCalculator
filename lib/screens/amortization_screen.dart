import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
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
  double _extraPayment = 0;
  late double _maxExtra;

  @override
  void initState() {
    super.initState();
    // Allow simulating up to 100% extra or at least 100 currency units
    _maxExtra = (widget.loan.monthlyRequired * 1.5).clamp(100.0, 5000.0);
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final schedule = widget.loan.getAmortizationSchedule(
      extraMonthlyPayment: _extraPayment,
    );

    // Calculate stats
    double totalInterest = schedule.fold(0, (sum, item) => sum + item.interest);
    int totalMonths = schedule.isNotEmpty ? schedule.last.monthIndex : 0;

    // Original (approximate)
    final originalSchedule = widget.loan.getAmortizationSchedule(
      extraMonthlyPayment: 0,
    );
    double originalInterest = originalSchedule.fold(
      0,
      (sum, item) => sum + item.interest,
    );
    int originalMonths = originalSchedule.isNotEmpty
        ? originalSchedule.last.monthIndex
        : 0;

    double savedInterest = originalInterest - totalInterest;
    int savedMonths = originalMonths - totalMonths;

    return Scaffold(
      appBar: AppBar(
        title: Text('Amortization Schedule'),
        backgroundColor: AppTheme.background,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.textPrimary),
      ),
      body: Column(
        children: [
          _buildSimulationCard(settings, savedInterest, savedMonths),
          Expanded(child: _buildScheduleList(schedule, settings)),
        ],
      ),
    );
  }

  Widget _buildSimulationCard(
    SettingsProvider settings,
    double savedInterest,
    int savedMonths,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.shadowPrimary,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Simulator',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Extra Monthly:',
                style: TextStyle(color: Colors.white70),
              ),
              Text(
                formatCurrency(_extraPayment, symbol: settings.currencySymbol),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          Slider(
            value: _extraPayment,
            min: 0,
            max: _maxExtra,
            activeColor: Colors.white,
            inactiveColor: Colors.white24,
            onChanged: (value) {
              setState(() => _extraPayment = value);
            },
          ),
          const Divider(color: Colors.white24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Interest',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      savedInterest > 0
                          ? 'Save ${formatCurrency(savedInterest, symbol: settings.currencySymbol)}'
                          : 'Standard',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Term Reduced',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      savedMonths > 0 ? '$savedMonths months' : 'Standard',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
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

  Widget _buildScheduleList(
    List<AmortizationEntry> schedule,
    SettingsProvider settings,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: schedule.length + 1, // Header + items
      itemBuilder: (context, index) {
        if (index == 0) return _buildListHeader();
        final entry = schedule[index - 1];
        return _buildListItem(entry, settings);
      },
    );
  }

  Widget _buildListHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.divider)),
      ),
      child: Row(
        children: [
          SizedBox(width: 40, child: Text('Mo', style: _headerStyle)),
          Expanded(
            child: Text(
              'Payment',
              style: _headerStyle,
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            child: Text(
              'Principal',
              style: _headerStyle,
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            child: Text(
              'Interest',
              style: _headerStyle,
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            child: Text(
              'Balance',
              style: _headerStyle,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(AmortizationEntry entry, SettingsProvider settings) {
    final dateFormat = DateFormat.MMMd();
    final isLast = entry.remainingBalance <= 0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: indexIsEven(entry.monthIndex)
            ? Colors.transparent
            : AppTheme.surfaceLight.withValues(alpha: 0.3),
        border: Border(
          bottom: BorderSide(color: AppTheme.divider, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.monthIndex}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  dateFormat.format(entry.date),
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.textLight,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              formatCurrency(entry.payment, symbol: ''),
              textAlign: TextAlign.right,
              style: _valStyle,
            ),
          ),
          Expanded(
            child: Text(
              formatCurrency(entry.principal, symbol: ''),
              textAlign: TextAlign.right,
              style: _valStyle,
            ),
          ),
          Expanded(
            child: Text(
              formatCurrency(entry.interest, symbol: ''),
              textAlign: TextAlign.right,
              style: _valStyle,
            ),
          ),
          Expanded(
            child: Text(
              isLast ? '0' : formatCurrency(entry.remainingBalance, symbol: ''),
              textAlign: TextAlign.right,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  bool indexIsEven(int index) => index % 2 == 0;

  static final _headerStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: AppTheme.textSecondary,
  );
  static final _valStyle = TextStyle(fontSize: 13, color: AppTheme.textPrimary);
}


