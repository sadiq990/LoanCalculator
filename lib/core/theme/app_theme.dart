import 'package:flutter/material.dart';

/// App-wide design system with colors, typography, and animations
class AppTheme {
  static ThemeMode _activeThemeMode = ThemeMode.system;

  /// Keep AppTheme semantic colors in sync with selected ThemeMode.
  static void syncThemeMode(ThemeMode mode) {
    _activeThemeMode = mode;
  }

  static bool get _isDarkMode {
    if (_activeThemeMode == ThemeMode.dark) return true;
    if (_activeThemeMode == ThemeMode.light) return false;
    return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
  }

  // Primary Colors - Deep Blue
  static const primary = Color(0xFF1B63ED);
  static const primaryLight = Color(0xFF3B82F6);
  static const primaryDark = Color(0xFF1E40AF);

  // Semantic Colors
  static const success = Color(0xFF10B981);
  static const successLight = Color(0xFFD1FAE5);
  static const warning = Color(0xFFF59E0B);
  static const warningLight = Color(0xFFFEF3C7);
  static const error = Color(0xFFEF4444);
  static const errorLight = Color(0xFFFEE2E2);

  // Light Palette
  static const _textPrimaryLight = Color(0xFF1F2937);
  static const _textSecondaryLight = Color(0xFF6B7280);
  static const _textLightLight = Color(0xFF9CA3AF);
  static const _dividerLight = Color(0xFFE5E7EB);
  static const _backgroundLight = Color(0xFFF8FAFD);
  static const _cardBgLight = Color(0xFFFFFFFF);
  static const _surfaceLightValue = Color(0xFFF3F4F6);

  // Gradients
  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );

  static const successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF059669), success],
  );

  // Animation Durations
  static const animFast = Duration(milliseconds: 150);
  static const animMedium = Duration(milliseconds: 300);
  static const animSlow = Duration(milliseconds: 500);
  static const animPageTransition = Duration(milliseconds: 350);
  static const animStaggerDelay = Duration(milliseconds: 50);

  // Animation Curves
  static const curveDefault = Curves.easeOutCubic;
  static const curveSpring = Curves.elasticOut;
  static const curveSmooth = Curves.easeInOutCubic;

  // Border Radius
  static const radiusSm = 8.0;
  static const radiusMd = 12.0;
  static const radiusLg = 16.0;
  static const radiusXl = 24.0;
  static const radiusFull = 100.0;

  // Shadows
  static List<BoxShadow> shadowSm = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> shadowMd = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> shadowLg = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> shadowPrimary = [
    BoxShadow(
      color: primary.withValues(alpha: 0.3),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  // Dark Palette
  static const _backgroundDark = Color(0xFF111827);
  static const _cardBgDark = Color(0xFF1F2937);
  static const _surfaceDark = Color(0xFF374151);
  static const _textPrimaryDark = Color(0xFFF9FAFB);
  static const _textSecondaryDark = Color(0xFFD1D5DB);
  static const _textLightDark = Color(0xFF9CA3AF);
  static const _dividerDark = Color(0xFF374151);

  // Semantic adaptive tokens (used throughout screens)
  static Color get background => _isDarkMode ? _backgroundDark : _backgroundLight;
  static Color get cardBg => _isDarkMode ? _cardBgDark : _cardBgLight;
  static Color get surfaceLight => _isDarkMode ? _surfaceDark : _surfaceLightValue;
  static Color get textPrimary => _isDarkMode ? _textPrimaryDark : _textPrimaryLight;
  static Color get textSecondary =>
      _isDarkMode ? _textSecondaryDark : _textSecondaryLight;
  static Color get textLight => _isDarkMode ? _textLightDark : _textLightLight;
  static Color get divider => _isDarkMode ? _dividerDark : _dividerLight;

  /// Build the MaterialApp theme
  static ThemeData buildTheme({bool isDark = false}) {
    final bg = isDark ? _backgroundDark : _backgroundLight;
    final card = isDark ? _cardBgDark : _cardBgLight;
    final surface = isDark ? _surfaceDark : _surfaceLightValue;
    final txtPrimary = isDark ? _textPrimaryDark : _textPrimaryLight;
    final txtSecondary = isDark ? _textSecondaryDark : _textSecondaryLight;
    final txtLight = isDark ? _textLightDark : _textLightLight;
    final div = isDark ? _dividerDark : _dividerLight;
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: isDark ? Brightness.dark : Brightness.light,
    ).copyWith(
      surface: card,
      onSurface: txtPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      fontFamily: 'SF Pro Display',
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: txtPrimary,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: txtPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: txtPrimary),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.w800,
          color: txtPrimary,
          letterSpacing: -1,
        ),
        displayMedium: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          color: txtPrimary,
          letterSpacing: -0.5,
        ),
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: txtPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: txtPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: txtPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: txtPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: txtPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: txtSecondary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: txtLight,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: txtPrimary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: TextStyle(color: txtLight),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
      ),
      dividerTheme: DividerThemeData(color: div, thickness: 1, space: 24),
      // Card color uses surface color in M3 defaults
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}

/// Format currency with manat symbol
String formatCurrency(double amount, {String symbol = '₼'}) {
  final formatted = amount.toStringAsFixed(0);
  final buffer = StringBuffer();
  int count = 0;
  for (int i = formatted.length - 1; i >= 0; i--) {
    buffer.write(formatted[i]);
    count++;
    if (count == 3 && i > 0) {
      buffer.write(' ');
      count = 0;
    }
  }
  return '${buffer.toString().split('').reversed.join()} $symbol';
}

