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
  static const primaryDark = Color(0xFF1E40AF); // Blue 800
  static const primaryLight = Color(0xFFDEF7FF); // Blue 100
  
  static const accent = Color(0xFF6366F1); // Tailwind Indigo 500
  static const accentLight = Color(0xFFFCF8FF); // Indigo tint
  
  static const secondary = Color(0xFF10B981); // Tailwind Green 500

  // Semantic Colors
  static const success = Color(0xFF22C55E); // Green 500
  static const successDark = Color(0xFF15803D); // Green 700
  static Color get successLight =>
      _isDark ? _darkSuccessLight : _lightSuccessLight;
  
  static const warning = Color(0xFFF59E0B); // Amber 500
  static const warningLight = Color(0xFFFEF3C7); // Amber 100
  
  static const error = Color(0xFFEF4444); // Red 500
  static const errorLight = Color(0xFFFEE2E2); // Red 100

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
    colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
  );

  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
  );

  static const successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF22C55E), Color(0xFF28CD4F)],
  );

  static const warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
  );

  static const errorGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEF4444), Color(0xFFF87171)],
  );

  // Spacing System (iOS-standard 8-point grid)
  static const spacingXs = 4.0;
  static const spacing8 = 8.0;
  static const spacing10 = 10.0;
  static const spacing12 = 12.0;
  static const spacing14 = 14.0;
  static const spacing16 = 16.0;
  static const spacing20 = 20.0;
  static const spacing24 = 24.0;
  static const spacing32 = 32.0;
  static const spacing40 = 40.0;
  static const spacingMax = 64.0;

  // Animation Durations (Standard, smooth)
  static const animFast = Duration(milliseconds: 200);
  static const animMedium = Duration(milliseconds: 300);
  static const animSlow = Duration(milliseconds: 500);
  static const animPageTransition = Duration(milliseconds: 300);
  static const animStaggerDelay = Duration(milliseconds: 50);

  // iOS-style Curves
  static const curveDefault = Curves.easeOutCubic;
  static const curveSwift = Curves.easeInOut;
  static const curveSnappy = Curves.easeOutBack;

  // Radii
  static const radiusSm = 8.0;
  static const radiusMd = 12.0;
  static const radiusLg = 16.0;
  static const radiusXl = 24.0;
  static const radiusSheet = 32.0;
  static const radiusFull = 100.0;

  // Premium iOS-style Shadows (Depth layers)
  static List<BoxShadow> shadowXs = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.02),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> shadowSm = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> shadowMd = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> shadowLg = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> shadowPrimary = [
    BoxShadow(
      color: primary.withValues(alpha: 0.15),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> shadowSuccess = [
    BoxShadow(
      color: success.withValues(alpha: 0.12),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  // Glass Morphism - iOS frost effect
  static const glassBackdropFilter = 10.0;
  static const glassOpacity = 0.25;

  /// iOS SF Typography - Professional & Accessible
  static TextTheme _buildTextTheme(bool isDark) {
    final base = GoogleFonts.interTextTheme();
    final textColor = isDark ? _darkTextPrimary : _lightTextPrimary;
    final secondaryColor = isDark ? _darkTextSecondary : _lightTextSecondary;
    final lightColor = isDark ? _darkTextLight : _lightTextLight;

    return base.copyWith(
      // Extra large display
      displayLarge: base.displayLarge?.copyWith(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        color: textColor,
        letterSpacing: -0.7,
        height: 1.1,
      ),
      // Large display
      displayMedium: base.displayMedium?.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: -0.5,
        height: 1.15,
      ),
      // Extra large headline
      headlineLarge: base.headlineLarge?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: -0.3,
        height: 1.2,
      ),
      // Large headline
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: 0,
        height: 1.25,
      ),
      // Title 1 iOS
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: -0.2,
        height: 1.3,
      ),
      // Title 2 iOS
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: -0.1,
        height: 1.3,
      ),
      // Title 3 iOS
      titleSmall: base.titleSmall?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textColor,
        letterSpacing: 0,
        height: 1.3,
      ),
      // Body
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        color: textColor,
        letterSpacing: -0.4,
        height: 1.4,
      ),
      // Body 2
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: secondaryColor,
        letterSpacing: -0.2,
        height: 1.4,
      ),
      // Small text
      bodySmall: base.bodySmall?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: lightColor,
        letterSpacing: 0,
        height: 1.4,
      ),
      // Label Large
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textColor,
        letterSpacing: -0.1,
        height: 1.3,
      ),
      // Label Medium
      labelMedium: base.labelMedium?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: secondaryColor,
        letterSpacing: 0,
        height: 1.3,
      ),
      // Label Small
      labelSmall: base.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: lightColor,
        letterSpacing: 0.5,
        height: 1.4,
      ),
    );
  }

  static FilledButtonThemeData _buildFilledButtonTheme(bool isDark) {
    return FilledButtonThemeData(
      style: ButtonStyle(
        animationDuration: animMedium,
        backgroundColor: const WidgetStatePropertyAll(primary),
        foregroundColor: const WidgetStatePropertyAll(Colors.white),
        shadowColor: WidgetStatePropertyAll(
          primary.withValues(alpha: isDark ? 0.3 : 0.2),
        ),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return Colors.black.withValues(alpha: 0.2);
          }
          if (states.contains(WidgetState.hovered)) {
            return Colors.white.withValues(alpha: 0.1);
          }
          if (states.contains(WidgetState.focused)) {
            return Colors.white.withValues(alpha: 0.08);
          }
          return null;
        }),
        elevation: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) return 2;
          if (states.contains(WidgetState.hovered)) return 8;
          if (states.contains(WidgetState.focused)) return 6;
          return 4;
        }),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        minimumSize: const WidgetStatePropertyAll(Size(double.infinity, 52)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: spacing24, vertical: spacing12),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
        ),
        textStyle: WidgetStatePropertyAll(
          GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
          ),
        ),
      ),
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme(bool isDark) {
    return ElevatedButtonThemeData(
      style: ButtonStyle(
        animationDuration: animMedium,
        backgroundColor: WidgetStatePropertyAll(
          isDark ? _darkSurfaceLight.withValues(alpha: 0.8) : _lightSurfaceLight,
        ),
        foregroundColor: WidgetStatePropertyAll(
          isDark ? _darkTextPrimary : _lightTextPrimary,
        ),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return primary.withValues(alpha: 0.12);
          }
          if (states.contains(WidgetState.hovered)) {
            return primary.withValues(alpha: 0.06);
          }
          if (states.contains(WidgetState.focused)) {
            return primary.withValues(alpha: 0.08);
          }
          return null;
        }),
        elevation: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) return 1;
          if (states.contains(WidgetState.focused)) return 2;
          return isDark ? 0 : 0;
        }),
        minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: spacing16, vertical: spacing10),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
        ),
        textStyle: WidgetStatePropertyAll(
          GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  static TextButtonThemeData _buildTextButtonTheme() {
    return TextButtonThemeData(
      style: ButtonStyle(
        animationDuration: animMedium,
        foregroundColor: const WidgetStatePropertyAll(primary),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return primary.withValues(alpha: 0.12);
          }
          if (states.contains(WidgetState.hovered)) {
            return primary.withValues(alpha: 0.06);
          }
          if (states.contains(WidgetState.focused)) {
            return primary.withValues(alpha: 0.08);
          }
          return null;
        }),
        textStyle: WidgetStatePropertyAll(
          GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: -0.2),
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
        fillColor: _darkSurfaceLight.withValues(alpha: 0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: _darkDivider, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: _darkDivider.withValues(alpha: 0.6), width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: primary, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: spacing16, vertical: spacing16),
        hintStyle: TextStyle(color: _darkTextLight.withValues(alpha: 0.6)),
        labelStyle: TextStyle(color: _darkTextSecondary),
        errorStyle: const TextStyle(color: error, fontSize: 12, fontWeight: FontWeight.w500),
        helperStyle: TextStyle(color: _darkTextLight.withValues(alpha: 0.7), fontSize: 12),
        counterStyle: TextStyle(color: _darkTextLight.withValues(alpha: 0.7), fontSize: 12),
        prefixIconColor: _darkTextSecondary,
        suffixIconColor: _darkTextSecondary,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
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
      dialogTheme: DialogThemeData(
        backgroundColor: _darkCardBg,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
          color: _darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: GoogleFonts.inter(
          color: _darkTextSecondary,
          fontSize: 15,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
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
        fillColor: _lightSurfaceLight.withValues(alpha: 0.6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: _lightDivider, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: _lightDivider.withValues(alpha: 0.8), width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: primary, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: spacing16, vertical: spacing16),
        hintStyle: TextStyle(color: _lightTextLight.withValues(alpha: 0.6)),
        labelStyle: TextStyle(color: _lightTextSecondary),
        errorStyle: const TextStyle(color: error, fontSize: 12, fontWeight: FontWeight.w500),
        helperStyle: TextStyle(color: _lightTextLight.withValues(alpha: 0.7), fontSize: 12),
        counterStyle: TextStyle(color: _lightTextLight.withValues(alpha: 0.7), fontSize: 12),
        prefixIconColor: _lightTextSecondary,
        suffixIconColor: _lightTextSecondary,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
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
      dialogTheme: DialogThemeData(
        backgroundColor: _lightSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
          color: _lightTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: GoogleFonts.inter(
          color: _lightTextSecondary,
          fontSize: 15,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
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
