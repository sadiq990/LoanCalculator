import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App-wide design system with colors, typography, and animations
class AppTheme {
  /// Keep AppTheme semantic colors in sync with selected ThemeMode.
  static void syncThemeMode(ThemeMode mode) {
    if (mode == ThemeMode.dark) {
      _isDark = true;
      return;
    }
    if (mode == ThemeMode.light) {
      _isDark = false;
      return;
    }

    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    _isDark = brightness == Brightness.dark;
  }

  static bool _isDark = true;

  // Tailwind-Inspired Dark Mode Palette
  static const Color _darkBackground = Color(0xFF0F172A); // Slate 900
  static const Color _darkSurface = Color(0xFF1E293B); // Slate 800
  static const Color _darkSurfaceLight = Color(0xFF334155); // Slate 700
  static const Color _darkCardBg = Color(0xFF1E293B);
  static const Color _darkTextPrimary = Color(0xFFF8FAFC); // Slate 50
  static const Color _darkTextSecondary = Color(0xFFCBD5E1); // Slate 300
  static const Color _darkTextLight = Color(0xFF94A3B8); // Slate 400
  static const Color _darkDivider = Color(0xFF334155); // Slate 700
  static const Color _darkSuccessLight = Color(0xFF064E3B); // Green 900

  // Premium Light Mode Palette (Clean, Apple-like)
  static const Color _lightBackground = Color(0xFFF8FAFC); // Slate 50
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightSurfaceLight = Color(0xFFF1F5F9); // Slate 100
  static const Color _lightCardBg = Color(0xFFFFFFFF);
  static const Color _lightTextPrimary = Color(0xFF0F172A); // Slate 900
  static const Color _lightTextSecondary = Color(0xFF475569); // Slate 600
  static const Color _lightTextLight = Color(0xFF64748B); // Slate 500
  static const Color _lightDivider = Color(0xFFE2E8F0); // Slate 200
  static const Color _lightSuccessLight = Color(0xFFDCFCE7); // Green 100

  static Color get background => _isDark ? _darkBackground : _lightBackground;
  static Color get surface => _isDark ? _darkSurface : _lightSurface;
  static Color get surfaceLight =>
      _isDark ? _darkSurfaceLight : _lightSurfaceLight;
  static Color get cardBg => _isDark ? _darkCardBg : _lightCardBg;

  // Premium Financial Accent Colors (Matte, not Neon)
  static const primary = Color(0xFF3B82F6); // Tailwind Blue 500
  static const accent = Color(0xFF6366F1); // Tailwind Indigo 500
  static const secondary = Color(0xFF10B981); // Tailwind Green 500

  // Semantic Colors
  static const success = Color(0xFF22C55E); // Green 500
  static Color get successLight =>
      _isDark ? _darkSuccessLight : _lightSuccessLight;
  static const warning = Color(0xFFF59E0B); // Amber 500 (better contrast)
  static const error = Color(0xFFEF4444); // Red 500

  // Text Colors
  static Color get textPrimary =>
      _isDark ? _darkTextPrimary : _lightTextPrimary;
  static Color get textSecondary =>
      _isDark ? _darkTextSecondary : _lightTextSecondary;
  static Color get textLight => _isDark ? _darkTextLight : _lightTextLight;

  static Color get divider => _isDark ? _darkDivider : _lightDivider;

  // Modern Gradients (Smooth, not harsh)
  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2563EB), Color(0xFF4F46E5)], // Blue 600 to Indigo 600
  );

  // Animation Durations (Standard, smooth)
  static const animFast = Duration(milliseconds: 200);
  static const animMedium = Duration(milliseconds: 300);
  static const animSlow = Duration(milliseconds: 500);
  static const animPageTransition = Duration(milliseconds: 300);
  static const animStaggerDelay = Duration(milliseconds: 50);

  // Curves
  static const curveDefault = Curves.easeOutCubic;

  // Radii
  static const radiusSm = 8.0;
  static const radiusMd = 12.0;
  static const radiusLg = 16.0;
  static const radiusXl = 24.0;
  static const radiusSheet = 32.0;
  static const radiusFull = 100.0;

  // Shadows (Soft, no neon glow)
  static List<BoxShadow> shadowSm = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> shadowMd = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> shadowPrimary = [
    BoxShadow(
      color: primary.withValues(alpha: 0.2),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [success, Color(0xFF28CD4F)],
  );

  /// Google Fonts text theme
  static TextTheme _buildTextTheme(bool isDark) {
    final base = GoogleFonts.interTextTheme();
    final textColor = isDark ? _darkTextPrimary : _lightTextPrimary;
    final secondaryColor = isDark ? _darkTextSecondary : _lightTextSecondary;

    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        color: textColor,
        letterSpacing: -0.5,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: -0.3,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textColor,
        letterSpacing: -0.2,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textColor,
        letterSpacing: -0.1,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: textColor,
        letterSpacing: -0.4,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        color: textColor,
        letterSpacing: -0.4,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: secondaryColor,
        letterSpacing: -0.2,
      ),
    );
  }

  static FilledButtonThemeData _buildFilledButtonTheme(bool isDark) {
    return FilledButtonThemeData(
      style: ButtonStyle(
        animationDuration: animFast,
        backgroundColor: const WidgetStatePropertyAll(primary),
        foregroundColor: const WidgetStatePropertyAll(Colors.white),
        shadowColor: WidgetStatePropertyAll(
          primary.withValues(alpha: isDark ? 0.35 : 0.26),
        ),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return Colors.white.withValues(alpha: 0.16);
          }
          if (states.contains(WidgetState.hovered)) {
            return Colors.white.withValues(alpha: 0.08);
          }
          return null;
        }),
        elevation: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) return 1;
          if (states.contains(WidgetState.hovered)) return 6;
          return 4;
        }),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        minimumSize: const WidgetStatePropertyAll(Size(0, 54)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
        ),
        textStyle: WidgetStatePropertyAll(
          GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme(bool isDark) {
    return ElevatedButtonThemeData(
      style: ButtonStyle(
        animationDuration: animFast,
        backgroundColor: WidgetStatePropertyAll(
          isDark ? _darkSurfaceLight : _lightSurfaceLight,
        ),
        foregroundColor: WidgetStatePropertyAll(
          isDark ? _darkTextPrimary : _lightTextPrimary,
        ),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return primary.withValues(alpha: 0.14);
          }
          if (states.contains(WidgetState.hovered)) {
            return primary.withValues(alpha: 0.08);
          }
          return null;
        }),
        elevation: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) return 0;
          return isDark ? 2 : 1;
        }),
        minimumSize: const WidgetStatePropertyAll(Size(0, 52)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
        ),
      ),
    );
  }

  static TextButtonThemeData _buildTextButtonTheme() {
    return TextButtonThemeData(
      style: ButtonStyle(
        animationDuration: animFast,
        foregroundColor: const WidgetStatePropertyAll(primary),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return primary.withValues(alpha: 0.14);
          }
          if (states.contains(WidgetState.hovered)) {
            return primary.withValues(alpha: 0.08);
          }
          return null;
        }),
        textStyle: WidgetStatePropertyAll(
          GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  static IconButtonThemeData _buildIconButtonTheme(bool isDark) {
    return IconButtonThemeData(
      style: ButtonStyle(
        animationDuration: animFast,
        backgroundColor: WidgetStatePropertyAll(
          isDark
              ? _darkSurfaceLight.withValues(alpha: 0.75)
              : _lightSurfaceLight,
        ),
        foregroundColor: WidgetStatePropertyAll(
          isDark ? _darkTextPrimary : _lightTextPrimary,
        ),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return primary.withValues(alpha: 0.15);
          }
          if (states.contains(WidgetState.hovered)) {
            return primary.withValues(alpha: 0.08);
          }
          return null;
        }),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
        ),
      ),
    );
  }

  /// Build the MaterialApp theme
  static ThemeData buildTheme({bool isDark = true}) {
    return isDark ? buildDarkTheme() : buildLightTheme();
  }

  /// Build Dark Theme (default)
  static ThemeData buildDarkTheme() {
    final scheme = ColorScheme.dark(
      primary: primary,
      secondary: accent,
      surface: _darkCardBg,
      error: error,
      onSurface: _darkTextPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      splashFactory: InkSparkle.splashFactory,
      colorScheme: scheme,
      scaffoldBackgroundColor: _darkBackground,
      cardColor: _darkCardBg,
      dividerColor: _darkDivider,
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme: _buildTextTheme(true),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: _darkTextPrimary,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.inter(
          color: _darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkSurfaceLight.withValues(alpha: 0.6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: _darkDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: TextStyle(color: _darkTextLight),
      ),
      filledButtonTheme: _buildFilledButtonTheme(true),
      elevatedButtonTheme: _buildElevatedButtonTheme(true),
      textButtonTheme: _buildTextButtonTheme(),
      iconButtonTheme: _buildIconButtonTheme(true),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 3,
        highlightElevation: 0,
        splashColor: Colors.white.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _darkCardBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radiusSheet),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: primary.withValues(alpha: 0.15),
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  /// Build Light Theme
  static ThemeData buildLightTheme() {
    final scheme = ColorScheme.light(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      secondary: secondary,
      onSecondary: Colors.white,
      surface: _lightSurface,
      onSurface: _lightTextPrimary,
      error: error,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      splashFactory: InkSparkle.splashFactory,
      colorScheme: scheme,
      scaffoldBackgroundColor: _lightBackground,
      cardColor: _lightCardBg,
      dividerColor: _lightDivider,
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme: _buildTextTheme(false),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: _lightTextPrimary,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.inter(
          color: _lightTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightSurfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: _lightDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: TextStyle(color: _lightTextLight),
      ),
      filledButtonTheme: _buildFilledButtonTheme(false),
      elevatedButtonTheme: _buildElevatedButtonTheme(false),
      textButtonTheme: _buildTextButtonTheme(),
      iconButtonTheme: _buildIconButtonTheme(false),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 3,
        highlightElevation: 0,
        splashColor: Colors.white.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _lightCardBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radiusSheet),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: primary.withValues(alpha: 0.1),
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
