import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/settings_provider.dart';
import 'services/storage_service.dart';
import 'screens/calculator_screen.dart';
import 'screens/home_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/lock_screen.dart';
import 'screens/onboarding_screen.dart';

class LoanApp extends StatefulWidget {
  const LoanApp({super.key});

  @override
  State<LoanApp> createState() => _LoanAppState();
}

class _LoanAppState extends State<LoanApp> with WidgetsBindingObserver {
  bool _showPrivacyVeil = false;
  bool _isLocked = true;
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    switch (state) {
      case AppLifecycleState.inactive:
        // Always show veil on inactive to hide content in iOS App Switcher (only on mobile, not web)
        if (!kIsWeb) {
          setState(() {
            _showPrivacyVeil = true;
          });
        }
        break;

      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        _pausedAt = DateTime.now();
        if (settings.biometricEnabled && !settings.isBiometricPromptActive) {
          if (settings.autoLockTimeout == AutoLockTimeout.immediately) {
            setState(() {
              _isLocked = true;
            });
          }
        }
        break;

      case AppLifecycleState.resumed:
        if (settings.biometricEnabled && !settings.isBiometricPromptActive) {
          if (_pausedAt != null) {
            final elapsed = DateTime.now().difference(_pausedAt!);
            if (elapsed >= settings.autoLockTimeout.duration) {
              setState(() {
                _isLocked = true;
              });
            }
          }
        }
        _pausedAt = null;
        setState(() {
          _showPrivacyVeil = false;
        });
        break;

      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        AppTheme.syncThemeMode(settings.themeMode);

        final isDark = switch (settings.themeMode) {
          ThemeMode.dark => true,
          ThemeMode.light => false,
          ThemeMode.system =>
            MediaQuery.of(context).platformBrightness == Brightness.dark,
        };

        SystemChrome.setSystemUIOverlayStyle(
          isDark
              ? SystemUiOverlayStyle.light.copyWith(
                  statusBarColor: Colors.transparent,
                  systemNavigationBarColor: const Color(0xFF0F172A),
                  systemNavigationBarIconBrightness: Brightness.light,
                )
              : SystemUiOverlayStyle.dark.copyWith(
                  statusBarColor: Colors.transparent,
                  systemNavigationBarColor: const Color(0xFFF8FAFC),
                  systemNavigationBarIconBrightness: Brightness.dark,
                ),
        );

        Widget homeWidget;
        if (!settings.isLoaded) {
          homeWidget = const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (!settings.isOnboarded && !kIsWeb) {
          homeWidget = const OnboardingScreen();
        } else if (settings.biometricEnabled && _isLocked) {
          homeWidget = LockScreen(
            onUnlock: () {
              setState(() {
                _isLocked = false;
              });
            },
          );
        } else {
          homeWidget = const MainShell();
        }

        return MaterialApp(
          title: 'Loan Tracker',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.buildLightTheme(),
          darkTheme: AppTheme.buildDarkTheme(),
          themeMode: settings.themeMode,
          builder: (context, child) {
            return Stack(
              children: [
                child ?? const SizedBox.shrink(),
                if (_showPrivacyVeil)
                  Positioned.fill(
                    child: _buildPrivacyOverlay(context),
                  ),
              ],
            );
          },
          home: homeWidget,
        );
      },
    );
  }

  Widget _buildPrivacyOverlay(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        color: AppTheme.primary,
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 48,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Loan Tracker',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 4-tab bottom navigation shell: Home, Calculator, Statistics, Settings
/// Uses IndexedStack so each tab keeps its state.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  /// Allow any child (e.g. CalculatorScreen) to switch tabs programmatically.
  static void switchToTab(BuildContext context, int tabIndex) {
    final state = context.findAncestorStateOfType<MainShellState>();
    state?.switchTab(tabIndex);
  }

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  bool _initializedTab = false;

  static const int tabHome = 0;
  static const int tabCalculator = 1;
  static const int tabStatistics = 2;
  static const int tabSettings = 3;

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    if (settings.openAppOn == OpenAppOn.calculator) {
      _currentIndex = tabCalculator;
      _initializedTab = true;
    } else if (settings.openAppOn == OpenAppOn.myLoans) {
      _currentIndex = tabHome;
      _initializedTab = true;
    } else if (settings.openAppOn == OpenAppOn.lastUsed &&
        settings.lastUsedTab >= 0 &&
        settings.lastUsedTab < 4) {
      _currentIndex = settings.lastUsedTab;
      _initializedTab = true;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _initInitialTab());
  }

  Future<void> _initInitialTab() async {
    if (!mounted || _initializedTab) return;
    try {
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      final storage = Provider.of<StorageService>(context, listen: false);
      final loans = await storage.getLoans();
      final tab = settings.determineInitialTab(hasLoans: loans.isNotEmpty);
      if (mounted) {
        setState(() {
          _currentIndex = tab;
          _initializedTab = true;
        });
      }
    } catch (_) {}
  }

  void switchTab(int index) {
    if (index < 0 || index >= 4) return;
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    settings.setLastUsedTab(index);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBarBg = isDark
        ? AppTheme.cardBg.withValues(alpha: 0.85)
        : Colors.white.withValues(alpha: 0.9);

    final screens = <Widget>[
      HomeScreen(isActive: _currentIndex == tabHome),
      CalculatorScreen(isActive: _currentIndex == tabCalculator),
      AnalyticsScreen(isActive: _currentIndex == tabStatistics),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              color: navBarBg,
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.06),
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavItem(
                      key: const Key('tab_home'),
                      icon: Icons.home_rounded,
                      label: 'Home',
                      isSelected: _currentIndex == tabHome,
                      onTap: () => switchTab(tabHome),
                    ),
                    _NavItem(
                      key: const Key('tab_calculator'),
                      icon: Icons.calculate_rounded,
                      label: 'Calculator',
                      isSelected: _currentIndex == tabCalculator,
                      onTap: () => switchTab(tabCalculator),
                    ),
                    _NavItem(
                      key: const Key('tab_statistics'),
                      icon: Icons.bar_chart_rounded,
                      label: 'Statistics',
                      isSelected: _currentIndex == tabStatistics,
                      onTap: () => switchTab(tabStatistics),
                    ),
                    _NavItem(
                      key: const Key('tab_settings'),
                      icon: Icons.settings_rounded,
                      label: 'Settings',
                      isSelected: _currentIndex == tabSettings,
                      onTap: () => switchTab(tabSettings),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: '$label tab',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: AppTheme.animFast,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.1 : 1.0,
                duration: AppTheme.animFast,
                child: Icon(
                  icon,
                  size: 24,
                  color: isSelected ? AppTheme.primary : AppTheme.textLight,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: AppTheme.animFast,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppTheme.primary : AppTheme.textLight,
                ),
                child: Text(label),
              ),
              // Active indicator dot
              AnimatedContainer(
                duration: AppTheme.animFast,
                margin: const EdgeInsets.only(top: 3),
                width: isSelected ? 5 : 0,
                height: isSelected ? 5 : 0,
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Keep backward compat for imports
typedef RootShell = MainShell;
typedef RootShellState = MainShellState;
