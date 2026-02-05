import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/settings_provider.dart';
import 'screens/home_screen.dart';
import 'screens/lock_screen.dart';

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
    AppTheme.syncThemeMode(settings.themeMode);

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
    );
  }
}
