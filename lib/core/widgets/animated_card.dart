import 'package:flutter/material.dart';
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
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _controller, curve: AppTheme.curveDefault),
        );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: AppTheme.curveDefault),
    );

    // Stagger the animation based on index
    Future.delayed(Duration(milliseconds: widget.index * 50), () {
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
          scale: _isPressed ? 0.97 : 1.0,
          duration: AppTheme.animFast,
          curve: AppTheme.curveDefault,
          child: Container(
            padding: widget.padding ?? const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              boxShadow: widget.withShadow ? AppTheme.shadowMd : null,
              border: Border.all(
                color: AppTheme.divider.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
