import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Lightweight shimmer placeholder used while async data is loading.
class SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = AppTheme.surfaceLight;
    final glow = AppTheme.divider.withValues(alpha: 0.35);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius:
                widget.borderRadius ?? BorderRadius.circular(AppTheme.radiusSm),
            gradient: LinearGradient(
              begin: Alignment(-1 + (2 * t), -0.4),
              end: Alignment(1 + (2 * t), 0.4),
              colors: [base, glow, base],
              stops: const [0.25, 0.5, 0.75],
            ),
          ),
        );
      },
    );
  }
}
