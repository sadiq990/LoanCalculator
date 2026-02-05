import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// An animated button with gradient background and press animation
class AnimatedButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool isOutlined;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const AnimatedButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.isOutlined = false,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() => _isPressed = true);
      HapticFeedback.lightImpact();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;
    final bgColor = widget.backgroundColor ?? AppTheme.primary;
    final fgColor = widget.foregroundColor ?? Colors.white;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: isEnabled ? widget.onPressed : null,
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: AppTheme.animFast,
        curve: AppTheme.curveDefault,
        child: AnimatedOpacity(
          opacity: isEnabled ? 1.0 : 0.6,
          duration: AppTheme.animFast,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: widget.isOutlined
                  ? null
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [bgColor, bgColor.withValues(alpha: 0.85)],
                    ),
              color: widget.isOutlined ? Colors.transparent : null,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: widget.isOutlined
                  ? Border.all(color: bgColor, width: 2)
                  : null,
              boxShadow: widget.isOutlined || !isEnabled
                  ? null
                  : [
                      BoxShadow(
                        color: bgColor.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Center(
              child: widget.isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          widget.isOutlined ? bgColor : fgColor,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(
                            widget.icon,
                            size: 20,
                            color: widget.isOutlined ? bgColor : fgColor,
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          widget.label,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: widget.isOutlined ? bgColor : fgColor,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A small icon button with animation
class AnimatedIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? backgroundColor;
  final double size;

  const AnimatedIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color,
    this.backgroundColor,
    this.size = 48,
  });

  @override
  State<AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<AnimatedIconButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onPressed?.call();
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.9 : 1.0,
        duration: AppTheme.animFast,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Icon(
            widget.icon,
            color: widget.color ?? AppTheme.textSecondary,
            size: widget.size * 0.5,
          ),
        ),
      ),
    );
  }
}
