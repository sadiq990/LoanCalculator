import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum AppBackgroundStyle { standard, solid, none }

class AppScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final bool useSafeArea;
  final bool extendBodyBehindAppBar;
  final AppBackgroundStyle backgroundStyle;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;

  const AppScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.useSafeArea = true,
    this.extendBodyBehindAppBar = false,
    this.backgroundStyle = AppBackgroundStyle.standard,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = body;
    if (useSafeArea) {
      content = SafeArea(child: content);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      body: Stack(
        children: [
          if (backgroundStyle != AppBackgroundStyle.none)
            Positioned.fill(
              child: AppBackground(
                style: backgroundStyle,
                color: backgroundColor,
              ),
            ),
          Positioned.fill(child: content),
        ],
      ),
    );
  }
}

class AppBackground extends StatelessWidget {
  final AppBackgroundStyle style;
  final Color? color;

  const AppBackground({
    super.key,
    this.style = AppBackgroundStyle.standard,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final base = color ?? AppTheme.background;
    if (style == AppBackgroundStyle.solid) {
      return Container(color: base);
    }

    if (style == AppBackgroundStyle.none) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryGlow = isDark
        ? AppTheme.primary.withValues(alpha: 0.22)
        : const Color(0xFFBBD7FF);
    final accentGlow = isDark
        ? AppTheme.accent.withValues(alpha: 0.16)
        : const Color(0xFFDCEBFF);

    final blobs = Stack(
      children: [
        Positioned(
          top: -140,
          right: -60,
          child: _BlurBlob(color: primaryGlow, size: 260),
        ),
        Positioned(
          bottom: -160,
          left: -90,
          child: _BlurBlob(color: accentGlow, size: 300),
        ),
        Positioned(
          top: 180,
          left: -120,
          child: _BlurBlob(
            color: primaryGlow.withValues(alpha: 0.6),
            size: 220,
          ),
        ),
      ],
    );

    return Container(
      color: base,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(
          sigmaX: isDark ? 60 : 50,
          sigmaY: isDark ? 60 : 50,
        ),
        child: blobs,
      ),
    );
  }
}

class _BlurBlob extends StatelessWidget {
  final Color color;
  final double size;

  const _BlurBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
