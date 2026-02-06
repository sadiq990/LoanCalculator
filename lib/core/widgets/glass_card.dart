import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum GlassCardVariant { surface, accent }

class GlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final bool animate;
  final GlassCardVariant variant;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.onTap,
    this.animate = true,
    this.variant = GlassCardVariant.surface,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (!widget.animate || widget.onTap == null) return;
    if (_isPressed == value) return;
    setState(() => _isPressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(AppTheme.radiusLg);

    final BoxDecoration decoration = widget.variant == GlassCardVariant.accent
        ? BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.primary, AppTheme.accent],
            ),
            borderRadius: radius,
            border: Border.all(
              color: Colors.white.withValues(alpha: isDark ? 0.14 : 0.18),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: isDark ? 0.32 : 0.2),
                blurRadius: 20,
                spreadRadius: 1,
                offset: const Offset(0, 6),
              ),
            ],
          )
        : isDark
        ? BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.cardBg.withValues(alpha: 0.92),
                AppTheme.surfaceLight.withValues(alpha: 0.86),
              ],
            ),
            borderRadius: radius,
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          )
        : BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Color(0xFFF4F9FF)],
            ),
            borderRadius: radius,
            border: Border.all(color: const Color(0xFFE1EAF7)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1D4ED8).withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          );

    Widget surface = Material(
      type: MaterialType.transparency,
      child: Ink(
        decoration: decoration,
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: widget.onTap == null ? null : (_) => _setPressed(true),
          onTapUp: widget.onTap == null ? null : (_) => _setPressed(false),
          onTapCancel: widget.onTap == null ? null : () => _setPressed(false),
          splashColor: AppTheme.primary.withValues(alpha: 0.12),
          highlightColor: AppTheme.primary.withValues(alpha: 0.05),
          borderRadius: radius,
          child: Padding(
            padding: widget.padding ?? const EdgeInsets.all(20),
            child: widget.child,
          ),
        ),
      ),
    );

    if (isDark) {
      surface = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: surface,
      );
    }

    Widget content = Container(
      width: widget.width,
      height: widget.height,
      margin: widget.margin,
      child: ClipRRect(borderRadius: radius, child: surface),
    );

    if (widget.animate) {
      content = AnimatedScale(
        scale: _isPressed ? 0.986 : 1.0,
        duration: AppTheme.animFast,
        curve: AppTheme.curveDefault,
        child: content,
      );
    }

    return content;
  }
}
