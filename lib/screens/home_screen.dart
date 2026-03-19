import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/app_scaffold.dart';
import '../core/widgets/glass_card.dart';
import '../core/constants/loan_icons.dart';
import '../core/utils/currency_formatter.dart';
import '../models/loan.dart';
import '../models/payment.dart';
import '../services/storage_service.dart';
import '../providers/settings_provider.dart';
import 'add_loan_screen.dart';
import 'loan_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  List<Loan> _loans = [];
  List<Loan> _cachedFilteredLoans = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _filter = 'all'; // all | active | paidOff
  String _sortBy = 'dueSoon'; // dueSoon | balance | newest | name
  final Set<String> _archivedLoanIds = {};

  // FAB animation
  late AnimationController _fabController;
  bool _fabExpanded = false;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(vsync: this, duration: AppTheme.animMedium);
    _loadLoans();
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  Future<void> _loadLoans() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final storage = Provider.of<StorageService>(context, listen: false);
      final loans = await storage.getLoans();
      if (mounted) {
        setState(() {
          _loans = loans;
          _isLoading = false;
          _updateFilteredLoans();
        });
      }
    } catch (e) {
      debugPrint('Error loading loans: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Cache filtered and sorted loans to avoid recomputing every build
  void _updateFilteredLoans() {
    _cachedFilteredLoans = _computeFilteredLoans();
  }

  List<Loan> _computeFilteredLoans() {
    var filtered = _loans.where((l) => !_archivedLoanIds.contains(l.id));

    if (_filter == 'active') filtered = filtered.where((l) => !l.isPaidOff);
    if (_filter == 'paidOff') filtered = filtered.where((l) => l.isPaidOff);

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((l) => l.name.toLowerCase().contains(q));
    }

    final list = filtered.toList();
    list.sort((a, b) {
      return switch (_sortBy) {
        'balance' => b.totalRemaining.compareTo(a.totalRemaining),
        'newest' => b.createdAt.compareTo(a.createdAt),
        'name' => a.name.compareTo(b.name),
        _ => a.daysUntilPayment.compareTo(b.daysUntilPayment),
      };
    });
    return list;
  }

  List<Loan> get _filteredLoans => _cachedFilteredLoans;

  double get _totalDebt =>
      _loans.where((l) => !l.isPaidOff).fold(0, (s, l) => s + l.totalRemaining);

  int get _activeCount => _loans.where((l) => !l.isPaidOff).length;

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  void _toggleFab() {
    setState(() {
      _fabExpanded = !_fabExpanded;
      _fabExpanded ? _fabController.forward() : _fabController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return AppScaffold(
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(settings),
              _buildSearchAndFilter(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredLoans.isEmpty
                        ? SingleChildScrollView(child: _buildEmptyState())
                        : _buildLoanList(settings),
              ),
            ],
          ),
          // Expanded FAB overlay
          if (_fabExpanded) _buildFabOverlay(),
          // FAB
          Positioned(
            right: 20,
            bottom: 90,
            child: _buildExpandableFab(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(SettingsProvider settings) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_getGreeting()} 👋',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textLight,
            ),
          ),
          const SizedBox(height: 4),
          if (_activeCount > 0) ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatCurrency(_totalDebt, symbol: settings.currencySymbol),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '$_activeCount active',
                            style: TextStyle(fontSize: 14, color: AppTheme.textLight),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.success.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_rounded, size: 12, color: AppTheme.success),
                                const SizedBox(width: 4),
                                Text(
                                  formatCurrency(_loans.fold(0.0, (s, l) => s + l.totalPaid), symbol: settings.currencySymbol),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.success,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'paid',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.success.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ] else
            Text(
              'No active loans',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        children: [
          // Search
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.divider.withValues(alpha: 0.5)),
            ),
            child: TextField(
              onChanged: (v) {
                setState(() {
                  _searchQuery = v;
                  _updateFilteredLoans();
                });
              },
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Search loans...',
                hintStyle: TextStyle(color: AppTheme.textLight, fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded, color: AppTheme.textLight, size: 20),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                filled: false,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Filter chips + Sort
          Row(
            children: [
              _buildFilterChip('All', 'all'),
              const SizedBox(width: 8),
              _buildFilterChip('Active', 'active'),
              const SizedBox(width: 8),
              _buildFilterChip('Paid Off', 'paidOff'),
              const Spacer(),
              PopupMenuButton<String>(
                icon: Icon(Icons.sort_rounded, color: AppTheme.textLight, size: 22),
                onSelected: (v) {
                  setState(() {
                    _sortBy = v;
                    _updateFilteredLoans();
                  });
                },
                itemBuilder: (_) => [
                  _buildSortItem('Due Soon', 'dueSoon'),
                  _buildSortItem('Balance', 'balance'),
                  _buildSortItem('Newest', 'newest'),
                  _buildSortItem('Name', 'name'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final selected = _filter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _filter = value;
          _updateFilteredLoans();
        });
      },
      child: AnimatedContainer(
        duration: AppTheme.animFast,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildSortItem(String label, String value) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          if (_sortBy == value)
            Icon(Icons.check_rounded, color: AppTheme.primary, size: 18),
          if (_sortBy == value) const SizedBox(width: 8),
          Text(label),
        ],
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
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.1),
                    AppTheme.accent.withValues(alpha: 0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_wallet_rounded,
                size: 56,
                color: AppTheme.primary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Start tracking your loans',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first loan to see your\nfinancial progress here',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppTheme.textLight,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _navigateToAddLoan,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add First Loan'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanList(SettingsProvider settings) {
    final loans = _filteredLoans;
    return RefreshIndicator(
      onRefresh: _loadLoans,
      color: AppTheme.primary,
      child: AnimationLimiter(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100), // Integrated bottom padding
          itemCount: loans.length,
          itemBuilder: (context, index) {
            final loan = loans[index];
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: AppTheme.animMedium,
              child: SlideAnimation(
                verticalOffset: 30,
                child: FadeInAnimation(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildLoanCard(loan, settings, index),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoanCard(Loan loan, SettingsProvider settings, int index) {
    final gradient = kLoanIconGradient(loan.iconId);
    final progress = loan.progress.clamp(0.0, 1.0);
    final isDueSoon = loan.daysUntilPayment <= 3 && !loan.isPaidOff;

    return Dismissible(
      key: Key(loan.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppTheme.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        child: Icon(Icons.delete_outline_rounded, color: AppTheme.error),
      ),
      confirmDismiss: (_) => _confirmDelete(loan),
      child: GlassCard(
        onTap: () => _navigateToDetail(loan),
        padding: EdgeInsets.zero,
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Left accent bar
              AnimatedContainer(
                duration: AppTheme.animMedium,
                width: 4,
                decoration: BoxDecoration(
                  gradient: gradient.gradient,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(AppTheme.radiusLg),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacing16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Gradient icon
                          buildGradientIcon(loan.iconId, size: 44),
                          const SizedBox(width: AppTheme.spacing12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  loan.name,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ) ?? TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: AppTheme.spacingXs),
                                Text(
                                  loan.isPaidOff
                                      ? '✅ Paid off'
                                      : isDueSoon
                                          ? '⚠️ Due in ${loan.daysUntilPayment} day${loan.daysUntilPayment != 1 ? 's' : ''}'
                                          : 'Day ${loan.paymentDay} • ${loan.daysUntilPayment}d left',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontWeight: isDueSoon ? FontWeight.w600 : FontWeight.w400,
                                    color: isDueSoon ? AppTheme.warning : AppTheme.textLight,
                                  ) ?? TextStyle(
                                    fontSize: 12,
                                    fontWeight: isDueSoon ? FontWeight.w600 : FontWeight.w400,
                                    color: isDueSoon ? AppTheme.warning : AppTheme.textLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                formatCurrency(loan.totalRemaining, symbol: settings.currencySymbol),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                '${(progress * 100).toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacing12),
                      // Gradient Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                        child: Stack(
                          children: [
                            Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceLight,
                                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: progress,
                              child: Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  gradient: gradient.gradient,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing8),
                      // Bottom stats
                      Row(
                        children: [
                          Text(
                            'Monthly: ${formatCurrency(loan.monthlyRequired, symbol: settings.currencySymbol)}',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppTheme.textLight,
                            ) ?? TextStyle(fontSize: 12, color: AppTheme.textLight),
                          ),
                          const Spacer(),
                          Text(
                            'Rate: ${loan.interestRate.toStringAsFixed(1)}%',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppTheme.textLight,
                            ) ?? TextStyle(fontSize: 12, color: AppTheme.textLight),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(Loan loan) async {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        elevation: AppTheme.shadowMd.first.blurRadius,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(
          'Delete Loan',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppTheme.textPrimary,
          ),
        ),
        content: Text(
          'Delete "${loan.name}"? This cannot be undone.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textLight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppTheme.primary,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              final storage = Provider.of<StorageService>(context, listen: false);
              await storage.deleteLoan(loan.id);
              if (mounted) Navigator.pop(context, true);
              _loadLoans();
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.error,
            ),
            child: Text(
              'Delete',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppTheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Expandable FAB
  Widget _buildExpandableFab() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Mini buttons
        ScaleTransition(
          scale: CurvedAnimation(parent: _fabController, curve: AppTheme.curveDefault),
          alignment: Alignment.bottomRight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildMiniFabItem(
                icon: Icons.payments_rounded,
                label: 'Quick Pay',
                color: AppTheme.success,
                onTap: () {
                  _toggleFab();
                  if (_loans.isNotEmpty) _showQuickPaySheet(_loans.first);
                },
              ),
              const SizedBox(height: 8),
              _buildMiniFabItem(
                icon: Icons.add_rounded,
                label: 'New Loan',
                color: AppTheme.primary,
                onTap: () {
                  _toggleFab();
                  _navigateToAddLoan();
                },
              ),
              const SizedBox(height: 14),
            ],
          ),
        ),
        // Main FAB
        GestureDetector(
          onTap: _loans.isEmpty ? _navigateToAddLoan : _toggleFab,
          child: AnimatedContainer(
            duration: AppTheme.animFast,
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: AnimatedRotation(
              turns: _fabExpanded ? 0.125 : 0,
              duration: AppTheme.animFast,
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniFabItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              boxShadow: AppTheme.shadowSm,
            ),
            child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildFabOverlay() {
    return GestureDetector(
      onTap: _toggleFab,
      child: AnimatedContainer(
        duration: AppTheme.animFast,
        color: Colors.black.withValues(alpha: 0.3),
      ),
    );
  }

  void _navigateToAddLoan() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddLoanScreen()),
    );
    if (result == true) _loadLoans();
  }

  void _navigateToDetail(Loan loan) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LoanDetailScreen(loanId: loan.id)),
    );
    if (result == true) _loadLoans();
  }

  void _showQuickPaySheet(Loan loan) {
    final controller = TextEditingController();
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Quick Payment — ${loan.name}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: loan.monthlyRequired.toStringAsFixed(0),
                  suffixText: settings.currencySymbol,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final amount = double.tryParse(controller.text);
                    if (amount != null && amount > 0) {
                      final storage = Provider.of<StorageService>(context, listen: false);
                      await storage.addPayment(loan.id, Payment.create(amount: amount));
                      if (context.mounted) Navigator.pop(context);
                      _loadLoans();
                      HapticFeedback.mediumImpact();
                    }
                  },
                  child: const Text('Record Payment'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
