import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/animated_button.dart';
import '../core/widgets/animated_card.dart';
import '../models/loan.dart';
import '../models/payment.dart';
import '../services/storage_service.dart';
import '../core/constants/loan_icons.dart';
import '../services/pdf_service.dart';
import 'amortization_screen.dart'; // Add import
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

/// Screen showing loan details with payment recording
class LoanDetailScreen extends StatefulWidget {
  final String loanId;

  const LoanDetailScreen({super.key, required this.loanId});

  @override
  State<LoanDetailScreen> createState() => _LoanDetailScreenState();
}

class _LoanDetailScreenState extends State<LoanDetailScreen>
    with SingleTickerProviderStateMixin {
  final StorageService _storage = StorageService();
  final TextEditingController _paymentController = TextEditingController();

  Loan? _loan;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _showPaymentSuccess = false;
  double _lastPaymentAmount = 0;

  late AnimationController _headerController;
  late Animation<double> _headerFade;
  late Animation<double> _headerSlide;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      vsync: this,
      duration: AppTheme.animSlow,
    );
    _headerFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _headerController, curve: AppTheme.curveDefault),
    );
    _headerSlide = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _headerController, curve: AppTheme.curveDefault),
    );
    _loadLoan();
  }

  @override
  void dispose() {
    _headerController.dispose();
    _paymentController.dispose();
    super.dispose();
  }

  Future<void> _loadLoan() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final loan = await _storage.getLoan(widget.loanId);
    if (!mounted) return;
    setState(() {
      _loan = loan;
      _isLoading = false;
    });
    _headerController.forward(from: 0);
  }

  Future<void> _recordPayment() async {
    final amount = double.tryParse(_paymentController.text.replaceAll(' ', ''));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final payment = Payment.create(amount: amount);
    final updatedLoan = await _storage.addPayment(widget.loanId, payment);

    if (updatedLoan != null) {
      setState(() {
        _loan = updatedLoan;
        _isSaving = false;
        _showPaymentSuccess = true;
        _lastPaymentAmount = amount;
      });
      _paymentController.clear();
      HapticFeedback.mediumImpact();

      // Hide success message after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() => _showPaymentSuccess = false);
        }
      });
    } else {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteLoan() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: Text('Delete Loan'),
        content: Text(
          'Are you sure you want to delete this loan? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _storage.deleteLoan(widget.loanId);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loan == null
          ? _buildNotFound()
          : _buildContent(),
    );
  }

  Widget _buildNotFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: AppTheme.textLight,
          ),
          const SizedBox(height: 16),
          Text(
            'Loan not found',
            style: TextStyle(fontSize: 18, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),
          AnimatedButton(
            label: 'Go Back',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final loan = _loan!;
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(loan),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (_showPaymentSuccess) _buildSuccessMessage(),
                _buildPaymentInput(loan),
                const SizedBox(height: 20),
                _buildLoanInfo(loan),
                const SizedBox(height: 20),
                _buildQuickStats(loan),
                const SizedBox(height: 20),
                _buildPaymentHistory(loan),
                const SizedBox(height: 20),
                _buildDeleteButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Loan loan) {
    return AnimatedBuilder(
      animation: _headerController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _headerSlide.value),
          child: Opacity(opacity: _headerFade.value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: loan.isPaidOff
              ? AppTheme.successGradient
              : AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          boxShadow: AppTheme.shadowPrimary,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(true),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Custom Icon Small
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    kLoanIcons[loan.iconId] ?? Icons.credit_card_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    loan.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (loan.isPaidOff)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    ),
                    child: Text(
                      '✓ Paid Off',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'REMAINING DEBT',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: loan.remainingDebt),
              duration: AppTheme.animSlow,
              curve: AppTheme.curveDefault,
              builder: (context, value, child) {
                return Text(
                  formatCurrency(value),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: loan.progress),
                duration: AppTheme.animSlow,
                curve: AppTheme.curveDefault,
                builder: (context, value, child) {
                  return LinearProgressIndicator(
                    value: value,
                    minHeight: 10,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(loan.progress * 100).toStringAsFixed(0)}% complete',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Day ${loan.paymentDay} • ${loan.daysUntilPayment} days left',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.table_chart_rounded,
                          color: Colors.white,
                        ),
                        tooltip: 'Amortization',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AmortizationScreen(loan: loan),
                            ),
                          );
                        },
                      ),
                      Container(width: 1, height: 24, color: Colors.white24),
                      IconButton(
                        icon: Icon(
                          Icons.picture_as_pdf_rounded,
                          color: Colors.white,
                        ),
                        tooltip: 'Export PDF',
                        onPressed: () {
                          final settings = Provider.of<SettingsProvider>(
                            context,
                            listen: false,
                          );
                          PdfService.generateLoanReport(
                            loan,
                            settings.currencySymbol,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessMessage() {
    final loan = _loan!;
    final isExtra = _lastPaymentAmount > loan.monthlyRequired;

    return AnimatedCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.successLight,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Icon(
              Icons.check_circle_rounded,
              color: AppTheme.success,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment Recorded!',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.success,
                  ),
                ),
                if (isExtra)
                  Text(
                    'You paid ${formatCurrency(_lastPaymentAmount - loan.monthlyRequired)} extra! Great job!',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInput(Loan loan) {
    if (loan.isPaidOff) {
      return AnimatedCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.successLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.celebration_rounded,
                size: 48,
                color: AppTheme.success,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Congratulations!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppTheme.success,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You have fully paid off this loan!',
              style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

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
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(
                  Icons.payments_rounded,
                  color: AppTheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Record Payment',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _paymentController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              hintText: loan.monthlyRequired.toStringAsFixed(0),
              hintStyle: TextStyle(
                color: AppTheme.textLight.withValues(alpha: 0.5),
              ),
              suffixText: '₼',
              suffixStyle: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Monthly required: ${formatCurrency(loan.monthlyRequired)}',
            style: TextStyle(fontSize: 13, color: AppTheme.textLight),
          ),
          const SizedBox(height: 16),
          AnimatedButton(
            label: 'Record Payment',
            icon: Icons.check_rounded,
            isLoading: _isSaving,
            onPressed: _recordPayment,
          ),
        ],
      ),
    );
  }

  Widget _buildLoanInfo(Loan loan) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    return AnimatedCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Loan Terms',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  'Interest Rate',
                  '${loan.interestRate.toStringAsFixed(1)}%',
                ),
              ),
              Expanded(
                child: _buildInfoItem('Term', '${loan.termMonths} Months'),
              ),
              Expanded(
                child: _buildInfoItem(
                  'Monthly',
                  formatCurrency(
                    loan.monthlyRequired,
                    symbol: settings.currencySymbol,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: AppTheme.textLight),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats(Loan loan) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.payments_outlined,
            label: 'Total Paid',
            value: formatCurrency(loan.totalPaid),
            color: AppTheme.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.receipt_long_outlined,
            label: 'Payments',
            value: loan.paymentCount.toString(),
            color: AppTheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return AnimatedCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: AppTheme.textLight),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistory(Loan loan) {
    if (loan.payments.isEmpty) {
      return AnimatedCard(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.history_rounded, size: 48, color: AppTheme.textLight),
              SizedBox(height: 12),
              Text(
                'No payments yet',
                style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
              ),
              SizedBox(height: 4),
              Text(
                'Your payment history will appear here',
                style: TextStyle(fontSize: 13, color: AppTheme.textLight),
              ),
            ],
          ),
        ),
      );
    }

    final payments = loan.payments.reversed.toList();

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
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(
                  Icons.history_rounded,
                  color: AppTheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Payment History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...payments.asMap().entries.map((entry) {
            final payment = entry.value;
            final isExtra = payment.amount > loan.monthlyRequired;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isExtra
                          ? AppTheme.successLight
                          : AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Icon(
                      isExtra ? Icons.trending_up_rounded : Icons.check_rounded,
                      color: isExtra ? AppTheme.success : AppTheme.textLight,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formatCurrency(payment.amount),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          _formatDate(payment.date),
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isExtra)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.successLight,
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusFull,
                        ),
                      ),
                      child: Text(
                        '+${formatCurrency(payment.amount - loan.monthlyRequired)}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.success,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Widget _buildDeleteButton() {
    return Center(
      child: TextButton.icon(
        onPressed: _deleteLoan,
        icon: Icon(Icons.delete_outline_rounded),
        label: Text('Delete Loan'),
        style: TextButton.styleFrom(foregroundColor: AppTheme.error),
      ),
    );
  }
}


