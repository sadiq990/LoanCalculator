import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../core/constants/loan_icons.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/app_scaffold.dart';
import '../core/widgets/glass_card.dart';
import '../models/loan.dart';
import '../models/payment.dart';
import '../providers/settings_provider.dart';
import '../services/storage_service.dart';
import 'add_loan_screen.dart';
import 'dashboard_screen.dart';
import 'loan_detail_screen.dart';
import 'settings_screen.dart';
import '../core/widgets/skeleton_loader.dart';
import '../core/utils/currency_formatter.dart';

enum _LoanViewFilter { all, active, paidOff }

enum _LoanSortOption { dueSoon, highestBalance, newest, name }

/// Main screen showing list of all loans
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final StorageService _storage = StorageService();
  final TextEditingController _searchController = TextEditingController();

  List<Loan> _loans = [];
  bool _isLoading = true;
  String _searchQuery = '';

  _LoanViewFilter _viewFilter = _LoanViewFilter.all;
  _LoanSortOption _sortOption = _LoanSortOption.dueSoon;

  bool _showArchived = false;
  final Set<String> _archivedLoanIds = <String>{};

  double _previousTotalDebt = 0;
  Map<String, double> _previousProgressByLoanId = <String, double>{};
  int _listAnimationEpoch = 0;

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

    _searchController.addListener(() {
      final normalized = _searchController.text.trim().toLowerCase();
      if (normalized == _searchQuery) return;
      setState(() => _searchQuery = normalized);
    });

    _loadLoans();
  }

  @override
  void dispose() {
    _headerController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLoans() async {
    if (!mounted) return;

    final previousLoans = _loans;
    final previousTotalDebt = _calculateTotalDebt(previousLoans);
    final previousProgress = <String, double>{
      for (final loan in previousLoans) loan.id: loan.progress.clamp(0.0, 1.0),
    };

    setState(() => _isLoading = true);
    final loans = await _storage.getLoans();

    if (!mounted) return;
    setState(() {
      _previousTotalDebt = previousTotalDebt;
      _previousProgressByLoanId = previousProgress;
      _loans = loans;
      _isLoading = false;
      _listAnimationEpoch++;
    });

    _headerController.forward(from: 0);
  }

  double _calculateTotalDebt(List<Loan> loans) {
    final source = _showArchived
        ? loans
        : loans.where((loan) => !_archivedLoanIds.contains(loan.id));
    return source.fold(0.0, (sum, loan) => sum + loan.totalRemaining);
  }

  Iterable<Loan> get _summaryLoans => _showArchived
      ? _loans
      : _loans.where((loan) => !_archivedLoanIds.contains(loan.id));

  double get _totalDebt =>
      _summaryLoans.fold(0.0, (sum, loan) => sum + loan.totalRemaining);

  int get _activeLoansCount =>
      _summaryLoans.where((loan) => !loan.isPaidOff).length;

  int get _paidLoansCount =>
      _summaryLoans.where((loan) => loan.isPaidOff).length;

  List<Loan> get _visibleLoans {
    Iterable<Loan> source = _summaryLoans;

    switch (_viewFilter) {
      case _LoanViewFilter.active:
        source = source.where((loan) => !loan.isPaidOff);
        break;
      case _LoanViewFilter.paidOff:
        source = source.where((loan) => loan.isPaidOff);
        break;
      case _LoanViewFilter.all:
        break;
    }

    if (_searchQuery.isNotEmpty) {
      source = source.where(
        (loan) => loan.name.toLowerCase().contains(_searchQuery),
      );
    }

    final loans = source.toList();

    switch (_sortOption) {
      case _LoanSortOption.dueSoon:
        loans.sort((a, b) {
          final aScore = a.isPaidOff ? 10000 : a.daysUntilPayment;
          final bScore = b.isPaidOff ? 10000 : b.daysUntilPayment;
          if (aScore != bScore) return aScore.compareTo(bScore);
          return b.totalRemaining.compareTo(a.totalRemaining);
        });
        break;
      case _LoanSortOption.highestBalance:
        loans.sort((a, b) => b.totalRemaining.compareTo(a.totalRemaining));
        break;
      case _LoanSortOption.newest:
        loans.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case _LoanSortOption.name:
        loans.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
    }

    return loans;
  }

  String get _sortLabel {
    switch (_sortOption) {
      case _LoanSortOption.dueSoon:
        return 'Due soon';
      case _LoanSortOption.highestBalance:
        return 'Balance';
      case _LoanSortOption.newest:
        return 'Newest';
      case _LoanSortOption.name:
        return 'Name';
    }
  }

  void _setShowArchived(bool value) {
    setState(() {
      _previousTotalDebt = _totalDebt;
      _showArchived = value;
    });
  }

  Future<void> _navigateToAddLoan() async {
    final result = await Navigator.of(context).push<bool>(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const AddLoanScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: AppTheme.curveDefault,
            reverseCurve: Curves.easeInCubic,
          );
          final scale = Tween<double>(begin: 0.92, end: 1.0).animate(curved);

          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: scale,
              alignment: Alignment.bottomRight,
              child: child,
            ),
          );
        },
        transitionDuration: AppTheme.animPageTransition,
      ),
    );

    if (result == true) {
      await _loadLoans();
    }
  }

  Future<void> _navigateToLoanDetail(Loan loan) async {
    final result = await Navigator.of(context).push<bool>(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            LoanDetailScreen(loanId: loan.id),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: AppTheme.curveDefault,
          );

          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.04, 0),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
        transitionDuration: AppTheme.animPageTransition,
      ),
    );

    if (result == true) {
      await _loadLoans();
    }
  }

  Future<void> _toggleArchive(Loan loan) async {
    setState(() {
      _previousTotalDebt = _totalDebt;
      if (_archivedLoanIds.contains(loan.id)) {
        _archivedLoanIds.remove(loan.id);
      } else {
        _archivedLoanIds.add(loan.id);
      }
    });
  }

  Future<void> _showQuickPaymentSheet(Loan loan) async {
    if (loan.isPaidOff) return;

    final amountController = TextEditingController(
      text: loan.monthlyRequired.toStringAsFixed(0),
    );
    String? errorText;

    final amount = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardBg,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusSheet),
        ),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick payment',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    loan.name,
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Payment amount',
                      hintText: loan.monthlyRequired.toStringAsFixed(0),
                      errorText: errorText,
                      suffixText: 'Amount',
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        final parsed = double.tryParse(
                          amountController.text.replaceAll(
                            RegExp(r'[^0-9.]'),
                            '',
                          ),
                        );
                        if (parsed == null || parsed <= 0) {
                          setModalState(
                            () => errorText = 'Enter a valid amount',
                          );
                          return;
                        }
                        Navigator.of(context).pop(parsed);
                      },
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Record payment'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    amountController.dispose();
    if (amount == null) return;

    await _storage.addPayment(loan.id, Payment.create(amount: amount));
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment recorded for ${loan.name}'),
        backgroundColor: AppTheme.success,
      ),
    );
    await _loadLoans();
  }

  Future<void> _deleteLoan(Loan loan) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: Text(
          'Delete loan?',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Text(
          'Delete ${loan.name}? This cannot be undone.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await _storage.deleteLoan(loan.id);
    if (!mounted) return;
    _archivedLoanIds.remove(loan.id);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${loan.name} deleted'),
        backgroundColor: AppTheme.error,
      ),
    );
    await _loadLoans();
  }

  Future<void> _showQuickActionsSheet(Loan loan) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.cardBg,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusSheet),
        ),
      ),
      builder: (sheetContext) {
        final isArchived = _archivedLoanIds.contains(loan.id);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(
                    Icons.payments_rounded,
                    color: loan.isPaidOff
                        ? AppTheme.textLight
                        : AppTheme.primary,
                  ),
                  title: Text(
                    'Record payment',
                    style: TextStyle(color: AppTheme.textPrimary),
                  ),
                  subtitle: Text(
                    loan.isPaidOff
                        ? 'Loan already paid off'
                        : 'Add payment without opening details',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  enabled: !loan.isPaidOff,
                  onTap: loan.isPaidOff
                      ? null
                      : () {
                          Navigator.of(sheetContext).pop();
                          _showQuickPaymentSheet(loan);
                        },
                ),
                ListTile(
                  leading: Icon(
                    isArchived
                        ? Icons.unarchive_rounded
                        : Icons.archive_rounded,
                    color: AppTheme.warning,
                  ),
                  title: Text(
                    isArchived ? 'Unarchive loan' : 'Archive loan',
                    style: TextStyle(color: AppTheme.textPrimary),
                  ),
                  subtitle: const Text('Hides loan from default list view'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _toggleArchive(loan);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppTheme.error,
                  ),
                  title: Text(
                    'Delete loan',
                    style: TextStyle(color: AppTheme.textPrimary),
                  ),
                  subtitle: const Text('Permanent action'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _deleteLoan(loan);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool?> _onSwipeAction(DismissDirection direction, Loan loan) async {
    if (direction == DismissDirection.startToEnd) {
      await _showQuickActionsSheet(loan);
      return false;
    }

    await _deleteLoan(loan);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      floatingActionButton: _buildFab(),
      body: Column(
        children: [
          _buildTopBar(),
          _buildHeader(),
          _buildControls(),
          Expanded(
            child: AnimatedSwitcher(
              duration: AppTheme.animMedium,
              switchInCurve: AppTheme.curveDefault,
              switchOutCurve: Curves.easeIn,
              child: KeyedSubtree(
                key: ValueKey(
                  'content-$_listAnimationEpoch-${_isLoading ? 1 : 0}',
                ),
                child: _buildListContent(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          Text(
            'Loan Tracker',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              shadows: [
                Shadow(
                  color: AppTheme.primary.withValues(alpha: 0.5),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
          const Spacer(),
          IconButton.filledTonal(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DashboardScreen()),
            ),
            icon: const Icon(Icons.bar_chart_rounded),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.surfaceLight,
              foregroundColor: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            icon: const Icon(Icons.settings_rounded),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.surfaceLight,
              foregroundColor: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
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
      child: GlassCard(
        variant: GlassCardVariant.accent,
        margin: const EdgeInsets.fromLTRB(20, 4, 20, 8),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildSummaryPill(
                  label: '$_activeLoansCount active',
                  color: AppTheme.primary,
                ),
                const SizedBox(width: 8),
                _buildSummaryPill(
                  label: '$_paidLoansCount paid',
                  color: AppTheme.success,
                ),
                const Spacer(),
                Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'TOTAL DEBT',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: _previousTotalDebt, end: _totalDebt),
              duration: AppTheme.animSlow,
              curve: AppTheme.curveDefault,
              builder: (context, value, child) {
                return Text(
                  formatCurrency(value, symbol: settings.currencySymbol),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                    shadows: [
                      Shadow(
                        color: AppTheme.primary,
                        blurRadius: 15,
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Total repayment remaining (Principal + Interest)',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryPill({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          shadows: [Shadow(color: color.withValues(alpha: 0.5), blurRadius: 5)],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            style: TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search loans',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchQuery.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () => _searchController.clear(),
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SegmentedButton<_LoanViewFilter>(
                  showSelectedIcon: false,
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return AppTheme.primary.withValues(alpha: 0.2);
                      }
                      return Colors.transparent;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return AppTheme.primary;
                      }
                      return AppTheme.textSecondary;
                    }),
                    side: WidgetStateProperty.all(
                      BorderSide(color: AppTheme.divider),
                    ),
                  ),
                  segments: const [
                    ButtonSegment<_LoanViewFilter>(
                      value: _LoanViewFilter.all,
                      label: Text('All'),
                    ),
                    ButtonSegment<_LoanViewFilter>(
                      value: _LoanViewFilter.active,
                      label: Text('Active'),
                    ),
                    ButtonSegment<_LoanViewFilter>(
                      value: _LoanViewFilter.paidOff,
                      label: Text('Paid'),
                    ),
                  ],
                  selected: {_viewFilter},
                  onSelectionChanged: (selection) {
                    setState(() => _viewFilter = selection.first);
                  },
                ),
              ),
              const SizedBox(width: 10),
              PopupMenuButton<_LoanSortOption>(
                initialValue: _sortOption,
                onSelected: (value) => setState(() => _sortOption = value),
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _LoanSortOption.dueSoon,
                    child: Text('Sort: Due soon'),
                  ),
                  PopupMenuItem(
                    value: _LoanSortOption.highestBalance,
                    child: Text('Sort: Highest balance'),
                  ),
                  PopupMenuItem(
                    value: _LoanSortOption.newest,
                    child: Text('Sort: Newest'),
                  ),
                  PopupMenuItem(
                    value: _LoanSortOption.name,
                    child: Text('Sort: Name'),
                  ),
                ],
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.swap_vert_rounded,
                        size: 18,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _sortLabel,
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              FilterChip(
                selected: _showArchived,
                onSelected: _setShowArchived,
                label: const Text('Show archived'),
                selectedColor: AppTheme.primary.withValues(alpha: 0.2),
                checkmarkColor: AppTheme.primary,
                labelStyle: TextStyle(
                  color: _showArchived
                      ? AppTheme.primary
                      : AppTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_visibleLoans.length} shown',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    final visibleLoans = _visibleLoans;
    if (visibleLoans.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadLoans,
        child: _buildEmptyScrollable(),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLoans,
      child: AnimationLimiter(child: _buildLoansList(visibleLoans)),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppTheme.divider.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              SkeletonBox(width: 150, height: 16),
              SizedBox(height: 10),
              SkeletonBox(width: 220, height: 24),
              SizedBox(height: 16),
              SkeletonBox(width: double.infinity, height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyScrollable() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long_rounded,
                  size: 64,
                  color: AppTheme.textLight.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty
                      ? 'No loans match your search'
                      : 'No active loans',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_searchQuery.isEmpty) ...[
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _navigateToAddLoan,
                    icon: const Icon(Icons.add),
                    label: const Text('Add your first loan'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoansList(List<Loan> loans) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      itemCount: loans.length,
      itemBuilder: (context, index) {
        final loan = loans[index];
        return AnimationConfiguration.staggeredList(
          position: index,
          duration: const Duration(milliseconds: 375),
          child: SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(
              child: _LoanCard(
                loan: loan,
                onTap: () => _navigateToLoanDetail(loan),
                onSwipe: (dir) => _onSwipeAction(dir, loan),
                previousProgress: _previousProgressByLoanId[loan.id] ?? 0,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFab() {
    return FloatingActionButton.extended(
      onPressed: _navigateToAddLoan,
      label: const Text(
        'Add Loan',
        style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
      icon: const Icon(Icons.add_rounded),
    );
  }
}

class _LoanCard extends StatelessWidget {
  final Loan loan;
  final VoidCallback onTap;
  final Future<bool?> Function(DismissDirection) onSwipe;
  final double previousProgress;

  const _LoanCard({
    required this.loan,
    required this.onTap,
    required this.onSwipe,
    required this.previousProgress,
  });

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    // Dynamic color based on loan status
    Color statusColor = AppTheme.primary;
    if (loan.isPaidOff) {
      statusColor = AppTheme.success;
    } else if (loan.isPaymentDueSoon) {
      statusColor = AppTheme.warning;
    } else if (loan.daysUntilPayment < 0) {
      // Overdue
      statusColor = AppTheme.error;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Dismissible(
        key: Key('loan-${loan.id}'),
        background: _buildDismissBackground(
          color: AppTheme.primary,
          icon: Icons.flash_on_rounded, // Quick actio
          alignment: Alignment.centerLeft,
        ),
        secondaryBackground: _buildDismissBackground(
          color: AppTheme.error,
          icon: Icons.delete_outline_rounded,
          alignment: Alignment.centerRight,
        ),
        confirmDismiss: onSwipe,
        child: GlassCard(
          onTap: onTap,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withValues(alpha: 0.2),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Icon(
                      getIconData(loan.iconId),
                      color: statusColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loan.name,
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          loan.isPaidOff
                              ? 'Fully Repaid'
                              : 'Due in ${loan.daysUntilPayment} days',
                          style: TextStyle(
                            color: loan.isPaidOff
                                ? AppTheme.success
                                : (loan.isPaymentDueSoon
                                      ? AppTheme.warning
                                      : AppTheme.textSecondary),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatCurrency(
                          loan.totalRemaining,
                          symbol: settings.currencySymbol,
                        ),
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${(loan.progress * 100).toInt()}% Paid',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(
                    begin: previousProgress,
                    end: loan.progress,
                  ),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => LinearProgressIndicator(
                    value: value,
                    backgroundColor: AppTheme.surfaceLight,
                    color: statusColor,
                    minHeight: 6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDismissBackground({
    required Color color,
    required IconData icon,
    required Alignment alignment,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Icon(icon, color: color, size: 28),
    );
  }

  IconData getIconData(String iconId) {
    return kLoanIcons[iconId] ?? Icons.credit_card_rounded;
  }
}
