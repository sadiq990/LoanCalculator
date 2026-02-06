import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NeonButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool animate;

  const NeonButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.animate = true,
  });

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(
      begin: 2,
      end: 15,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            boxShadow: widget.onPressed == null
                ? []
                : [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.6),
                      blurRadius: widget.animate ? _glowAnimation.value : 5,
                      spreadRadius: 0,
                    ),
                  ],
          ),
          child: FilledButton(onPressed: widget.onPressed, child: widget.child),
        );
      },
    );
  }
}
