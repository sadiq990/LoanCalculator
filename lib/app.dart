import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_theme.dart';
import 'providers/settings_provider.dart';
import 'screens/home_screen.dart';
import 'screens/lock_screen.dart';
import 'screens/payoff_simulator_screen.dart';

class LoanApp extends StatefulWidget {
  const LoanApp({super.key});

  @override
  State<LoanApp> createState() => _LoanAppState();
}

class _LoanAppState extends State<LoanApp> {
  bool _isLocked = true;

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    final isDark =
        settings.themeMode == ThemeMode.system
            ? platformBrightness == Brightness.dark
            : settings.themeMode == ThemeMode.dark;
    final effectiveMode = isDark ? ThemeMode.dark : ThemeMode.light;

    AppTheme.syncThemeMode(effectiveMode);

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor:
            isDark ? const Color(0xFF000000) : Colors.white,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
    );

    // Determine if we should show lock screen
    final shouldLock = settings.biometricEnabled && _isLocked;

    return MaterialApp(
      title: 'Loan Tracker',
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode,
      theme: AppTheme.buildTheme(isDark: false),
      darkTheme: AppTheme.buildTheme(isDark: true),
      home: shouldLock
          ? LockScreen(onUnlock: () => setState(() => _isLocked = false))
          : const HomeScreen(),
      routes: {'/simulator': (context) => const PayoffSimulatorScreen()},
    );
  }
}
