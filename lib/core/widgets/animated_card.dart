import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/app_theme.dart';

/// An animated card widget with fade-in and slide-up animation
class AnimatedCard extends StatefulWidget {
  final Widget child;
  final int index;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final bool withShadow;

  const AnimatedCard({
    super.key,
    required this.child,
    this.index = 0,
    this.onTap,
    this.padding,
    this.withShadow = true,
  });

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppTheme.animMedium,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: AppTheme.curveDefault),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
          CurvedAnimation(parent: _controller, curve: AppTheme.curveDefault),
        );

    _scaleAnimation = Tween<double>(begin: 0.98, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: AppTheme.curveDefault),
    );

    // Stagger the animation based on index - faster iOS timing
    Future.delayed(Duration(milliseconds: widget.index * 40), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      setState(() => _isPressed = true);
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      setState(() => _isPressed = false);
    }
  }

  void _handleTapCancel() {
    if (widget.onTap != null) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(AppTheme.radiusLg);
    final lightBorder = const Color(0xFFE1EAF7);
    final lightShadow = const Color(0xFF1D4ED8).withValues(alpha: 0.08);

    final BoxDecoration decoration = BoxDecoration(
      color: isDark
          ? AppTheme.surfaceLight.withValues(alpha: 0.7)
          : Colors.white,
      borderRadius: radius,
      border: Border.all(
        color: isDark ? Colors.white.withValues(alpha: 0.08) : lightBorder,
        width: 0.5,
      ),
      boxShadow: widget.withShadow
          ? [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.15)
                    : lightShadow,
                blurRadius: isDark ? 10 : 16,
                offset: const Offset(0, 6),
              ),
            ]
          : null,
      gradient: isDark
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.08),
                Colors.white.withValues(alpha: 0.03),
              ],
            )
          : null,
    );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(scale: _scaleAnimation, child: child),
          ),
        );
      },
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isPressed ? 0.98 : 1.0, // Subtle iOS press
          duration: AppTheme.animFast,
          curve: AppTheme.curveDefault,
          child: ClipRRect(
            borderRadius: radius,
            child: Builder(
              builder: (context) {
                Widget content = Container(
                  padding: widget.padding ?? const EdgeInsets.all(16),
                  decoration: decoration,
                  child: widget.child,
                );

                if (isDark) {
                  content = BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: content,
                  );
                }

                return content;
              },
            ),
          ),
        ),
      ),
    );
  }
}
