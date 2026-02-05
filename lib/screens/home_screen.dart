import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/constants/loan_icons.dart';
import '../core/widgets/animated_card.dart';
import '../models/loan.dart';
import '../services/storage_service.dart';
import 'add_loan_screen.dart';
import 'loan_detail_screen.dart';
import 'settings_screen.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import 'dashboard_screen.dart';

/// Main screen showing list of all loans
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final StorageService _storage = StorageService();
  List<Loan> _loans = [];
  bool _isLoading = true;

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
    _loadLoans();
  }

  @override
  void dispose() {
    _headerController.dispose();
    super.dispose();
  }

  Future<void> _loadLoans() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final loans = await _storage.getLoans();
    if (!mounted) return;
    setState(() {
      _loans = loans;
      _isLoading = false;
    });
    _headerController.forward(from: 0);
  }

  double get _totalDebt =>
      _loans.fold(0.0, (sum, loan) => sum + loan.totalRemaining);

  int get _activeLoansCount => _loans.where((loan) => !loan.isPaidOff).length;

  void _navigateToAddLoan() async {
    final result = await Navigator.of(context).push<bool>(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const AddLoanScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: AppTheme.curveDefault,
                  ),
                ),
            child: child,
          );
        },
        transitionDuration: AppTheme.animPageTransition,
      ),
    );
    if (result == true) {
      _loadLoans();
    }
  }

  void _navigateToLoanDetail(Loan loan) async {
    final result = await Navigator.of(context).push<bool>(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            LoanDetailScreen(loanId: loan.id),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0.05, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: AppTheme.curveDefault,
                    ),
                  ),
              child: child,
            ),
          );
        },
        transitionDuration: AppTheme.animPageTransition,
      ),
    );
    if (result == true) {
      _loadLoans();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _loans.isEmpty
                  ? _buildEmptyState()
                  : _buildLoansList(),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildHeader() {
    final settings = Provider.of<SettingsProvider>(context);

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
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          boxShadow: AppTheme.shadowPrimary,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Loan Tracker',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.bar_chart_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DashboardScreen()),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.settings_rounded, color: Colors.white),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                ),
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
                    '$_activeLoansCount active',
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
              'TOTAL DEBT',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: _totalDebt),
              duration: AppTheme.animSlow,
              curve: AppTheme.curveDefault,
              builder: (context, value, child) {
                return Text(
                  formatCurrency(value, symbol: settings.currencySymbol),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_outlined,
                size: 56,
                color: AppTheme.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Loans Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Add your first loan to start\ntracking your payments',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: _navigateToAddLoan,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  boxShadow: AppTheme.shadowPrimary,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Add Loan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoansList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      itemCount: _loans.length,
      itemBuilder: (context, index) {
        final loan = _loans[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AnimatedCard(
            index: index,
            onTap: () => _navigateToLoanDetail(loan),
            child: _buildLoanCard(loan),
          ),
        );
      },
    );
  }

  Widget _buildLoanCard(Loan loan) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final progressColor = loan.isPaidOff
        ? AppTheme.success
        : loan.isPaymentDueSoon
        ? AppTheme.warning
        : AppTheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildIcon(loan),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loan.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    loan.isPaidOff
                        ? 'Paid off! 🎉'
                        : 'Due on day ${loan.paymentDay}',
                    style: TextStyle(
                      fontSize: 14,
                      color: loan.isPaidOff
                          ? AppTheme.success
                          : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (loan.isPaymentDueSoon && !loan.isPaidOff)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.warningLight,
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Text(
                  loan.isPaymentDueToday
                      ? 'Due Today!'
                      : '${loan.daysUntilPayment} days',
                  style: TextStyle(
                    color: AppTheme.warning,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Remaining (Total)',
                    style: TextStyle(fontSize: 12, color: AppTheme.textLight),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatCurrency(
                      loan.totalRemaining,
                      symbol: settings.currencySymbol,
                    ),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Monthly',
                  style: TextStyle(fontSize: 12, color: AppTheme.textLight),
                ),
                const SizedBox(height: 2),
                Text(
                  formatCurrency(
                    loan.monthlyRequired,
                    symbol: settings.currencySymbol,
                  ),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: loan.progress),
            duration: AppTheme.animSlow,
            curve: AppTheme.curveDefault,
            builder: (context, value, child) {
              return LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: AppTheme.surfaceLight,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${(loan.progress * 100).toStringAsFixed(0)}% paid',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: progressColor,
              ),
            ),
            Text(
              '${loan.paymentCount} payments',
              style: TextStyle(fontSize: 12, color: AppTheme.textLight),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIcon(Loan loan) {
    // Check if icon ID exists in map, otherwise default
    final iconData = kLoanIcons[loan.iconId] ?? Icons.credit_card_rounded;
    final color = kIconColors[loan.iconId] ?? AppTheme.primary;

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Icon(iconData, color: color, size: 24),
    );
  }

  Widget _buildFab() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: AppTheme.animSlow,
      curve: AppTheme.curveSpring,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: FloatingActionButton.extended(
        onPressed: _navigateToAddLoan,
        backgroundColor: AppTheme.primary,
        elevation: 4,
        icon: Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Add Loan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}


