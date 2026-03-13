import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/app_scaffold.dart';
import '../core/widgets/animated_card.dart';
import '../core/widgets/animated_button.dart';
import '../core/constants/loan_icons.dart';
import '../core/utils/currency_formatter.dart';
import '../models/loan.dart';
import '../models/payment.dart';
import '../services/storage_service.dart';
import '../services/pdf_service.dart';
import '../providers/settings_provider.dart';
import 'amortization_screen.dart';

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
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(vsync: this, duration: AppTheme.animSlow);
    _headerFade = CurvedAnimation(parent: _headerController, curve: AppTheme.curveDefault);
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _loadLoan();
  }

  @override
  void dispose() {
    _headerController.dispose();
    _paymentController.dispose();
    _confettiController.dispose();
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
    if (loan?.isPaidOff == true) _confettiController.play();
  }

  Future<void> _recordPayment() async {
    final amount = double.tryParse(_paymentController.text.replaceAll(' ', ''));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount'), backgroundColor: AppTheme.error),
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
      if (updatedLoan.isPaidOff) _confettiController.play();
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showPaymentSuccess = false);
      });
    } else {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteLoan() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
        title: Text(
          'Delete Loan',
          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure? This action cannot be undone.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: AppTheme.textLight)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _storage.deleteLoan(widget.loanId);
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _loan == null
                  ? _buildNotFound()
                  : _buildContent(),
          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 25,
              maxBlastForce: 15,
              minBlastForce: 5,
              gravity: 0.2,
              colors: const [AppTheme.primary, AppTheme.accent, AppTheme.success,
                Color(0xFFFBBF24), Color(0xFFF43F5E)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 64, color: AppTheme.textLight),
          const SizedBox(height: 16),
          Text('Loan not found', style: TextStyle(fontSize: 18, color: AppTheme.textSecondary)),
          const SizedBox(height: 24),
          AnimatedButton(label: 'Go Back', onPressed: () => Navigator.pop(context)),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final loan = _loan!;
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    return Column(
      children: [
        _buildHeader(loan, settings),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (_showPaymentSuccess) _buildSuccessMessage(loan, settings),
              if (!loan.isPaidOff) _buildPaymentInput(loan, settings),
              if (loan.isPaidOff) _buildCelebration(),
              const SizedBox(height: 16),
              _buildLoanInfo(loan, settings),
              const SizedBox(height: 16),
              _buildQuickStats(loan, settings),
              const SizedBox(height: 16),
              _buildPaymentTimeline(loan, settings),
              const SizedBox(height: 16),
              _buildDeleteButton(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(Loan loan, SettingsProvider settings) {
    final progress = loan.progress.clamp(0.0, 1.0);
    final gradient = kLoanIconGradient(loan.iconId);

    return FadeTransition(
      opacity: _headerFade,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: loan.isPaidOff
              ? AppTheme.successGradient
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [gradient.start, gradient.end],
                ),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: [
            BoxShadow(
              color: (loan.isPaidOff ? AppTheme.success : gradient.start)
                  .withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top row
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context, true),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    loan.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _buildHeaderActions(loan, settings),
              ],
            ),
            const SizedBox(height: 20),
            // Progress Ring
            _buildProgressRing(loan, progress, settings),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderActions(Loan loan, SettingsProvider settings) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeaderButton(
          icon: Icons.table_chart_rounded,
          tooltip: 'Amortization',
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => AmortizationScreen(loan: loan)));
          },
        ),
        const SizedBox(width: 8),
        _buildHeaderButton(
          icon: Icons.picture_as_pdf_rounded,
          tooltip: 'Export PDF',
          onTap: () => PdfService.generateLoanReport(loan, settings.currencySymbol),
        ),
      ],
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildProgressRing(Loan loan, double progress, SettingsProvider settings) {
    return SizedBox(
      width: 140,
      height: 140,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: progress),
        duration: const Duration(milliseconds: 1200),
        curve: AppTheme.curveDefault,
        builder: (context, value, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(140, 140),
                painter: _ProgressRingPainter(
                  progress: value,
                  strokeWidth: 10,
                  bgColor: Colors.white.withValues(alpha: 0.2),
                  fgColor: Colors.white,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(value * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    formatCurrency(loan.totalRemaining, symbol: settings.currencySymbol),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'remaining',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSuccessMessage(Loan loan, SettingsProvider settings) {
    final isExtra = _lastPaymentAmount > loan.monthlyRequired;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.successLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppTheme.success),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Payment Recorded!',
                      style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.success)),
                  if (isExtra)
                    Text(
                      'You paid ${formatCurrency(_lastPaymentAmount - loan.monthlyRequired, symbol: settings.currencySymbol)} extra!',
                      style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCelebration() {
    return AnimatedCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.successLight, shape: BoxShape.circle),
            child: const Icon(Icons.celebration_rounded, size: 48, color: AppTheme.success),
          ),
          const SizedBox(height: 16),
          Text('🎉 Congratulations!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppTheme.success)),
          const SizedBox(height: 8),
          Text('You have fully paid off this loan!',
              style: TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildPaymentInput(Loan loan, SettingsProvider settings) {
    return AnimatedCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  AppTheme.primary.withValues(alpha: 0.15),
                  AppTheme.primary.withValues(alpha: 0.05),
                ]),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: const Icon(Icons.payments_rounded, color: AppTheme.primary, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Record Payment',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 16),
          TextFormField(
            controller: _paymentController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              hintText: loan.monthlyRequired.toStringAsFixed(0),
              hintStyle: TextStyle(color: AppTheme.textLight.withValues(alpha: 0.5)),
              suffixText: settings.currencySymbol,
              suffixStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary),
            ),
          ),
          const SizedBox(height: 8),
          Text('Monthly: ${formatCurrency(loan.monthlyRequired, symbol: settings.currencySymbol)}',
              style: TextStyle(fontSize: 13, color: AppTheme.textLight)),
          const SizedBox(height: 16),
          AnimatedButton(label: 'Record Payment', icon: Icons.check_rounded,
              isLoading: _isSaving, onPressed: _recordPayment),
        ],
      ),
    );
  }

  Widget _buildLoanInfo(Loan loan, SettingsProvider settings) {
    return AnimatedCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Loan Terms', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _infoItem('Interest Rate', '${loan.interestRate.toStringAsFixed(1)}%')),
            Expanded(child: _infoItem('Term', '${loan.termMonths} Months')),
            Expanded(child: _infoItem('Monthly',
                formatCurrency(loan.monthlyRequired, symbol: settings.currencySymbol))),
          ]),
        ],
      ),
    );
  }

  Widget _infoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: AppTheme.textLight)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary)),
      ],
    );
  }

  Widget _buildQuickStats(Loan loan, SettingsProvider settings) {
    return Row(
      children: [
        Expanded(child: _statCard(Icons.payments_outlined, 'Total Paid',
            formatCurrency(loan.totalPaid, symbol: settings.currencySymbol), AppTheme.success)),
        const SizedBox(width: 12),
        Expanded(child: _statCard(Icons.receipt_long_outlined, 'Payments',
            loan.paymentCount.toString(), AppTheme.primary)),
      ],
    );
  }

  Widget _statCard(IconData icon, String label, String value, Color color) {
    return AnimatedCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(label, style: TextStyle(fontSize: 12, color: AppTheme.textLight)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  // Payment Timeline
  Widget _buildPaymentTimeline(Loan loan, SettingsProvider settings) {
    if (loan.payments.isEmpty) {
      return AnimatedCard(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.history_rounded, size: 48, color: AppTheme.textLight),
              const SizedBox(height: 12),
              Text('No payments yet',
                  style: TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
              const SizedBox(height: 4),
              Text('Your payment history will appear here',
                  style: TextStyle(fontSize: 13, color: AppTheme.textLight)),
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
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  AppTheme.primary.withValues(alpha: 0.15),
                  AppTheme.primary.withValues(alpha: 0.05),
                ]),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: const Icon(Icons.history_rounded, color: AppTheme.primary, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Payment History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 16),
          ...payments.asMap().entries.map((entry) {
            final i = entry.key;
            final payment = entry.value;
            final isExtra = payment.amount > loan.monthlyRequired;
            final isLast = i == payments.length - 1;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline column
                  SizedBox(
                    width: 24,
                    child: Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: isExtra ? AppTheme.success : AppTheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: (isExtra ? AppTheme.success : AppTheme.primary)
                                  .withValues(alpha: 0.3),
                              width: 3,
                            ),
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              color: AppTheme.divider,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  formatCurrency(payment.amount, symbol: settings.currencySymbol),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  _formatDate(payment.date),
                                  style: TextStyle(fontSize: 12, color: AppTheme.textLight),
                                ),
                              ],
                            ),
                          ),
                          if (isExtra)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.successLight,
                                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                              ),
                              child: Text(
                                '+${formatCurrency(payment.amount - loan.monthlyRequired, symbol: settings.currencySymbol)}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                                    color: AppTheme.success),
                              ),
                            ),
                        ],
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
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Widget _buildDeleteButton() {
    return Center(
      child: TextButton.icon(
        onPressed: _deleteLoan,
        icon: const Icon(Icons.delete_outline_rounded),
        label: const Text('Delete Loan'),
        style: TextButton.styleFrom(foregroundColor: AppTheme.error),
      ),
    );
  }
}

/// Custom painter for circular progress ring with gradient
class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color bgColor;
  final Color fgColor;

  _ProgressRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.bgColor,
    required this.fgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Background arc
    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Foreground arc
    if (progress > 0) {
      final fgPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: -pi / 2,
          endAngle: 3 * pi / 2,
          colors: [fgColor.withValues(alpha: 0.6), fgColor],
        ).createShader(rect);

      canvas.drawArc(
        rect,
        -pi / 2,
        2 * pi * progress,
        false,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter old) =>
      old.progress != progress;
}
