import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum ScaffoldBgType { standard, solid, none }

class AppScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? fabLocation;
  final Widget? bottomNavigationBar;
  final ScaffoldBgType bgType;
  final bool resizeToAvoidBottomInset;
  final bool useSafeArea;

  const AppScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.fabLocation,
    this.bottomNavigationBar,
    this.bgType = ScaffoldBgType.standard,
    this.resizeToAvoidBottomInset = true,
    this.useSafeArea = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: appBar,
      body: Stack(
        children: [
          _buildBackground(),
          if (useSafeArea) SafeArea(child: body) else body,
        ],
      ),
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: fabLocation,
      bottomNavigationBar: bottomNavigationBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBody: true,
    );
  }

  Widget _buildBackground() {
    if (bgType == ScaffoldBgType.none) return const SizedBox.shrink();
    if (bgType == ScaffoldBgType.solid) {
      return Container(color: AppTheme.background);
    }

    return Stack(
      children: [
        Container(color: AppTheme.background),
        Positioned(
          top: -100,
          right: -50,
          child: _Blob(color: AppTheme.primary.withValues(alpha: 0.12), size: 300),
        ),
        Positioned(
          bottom: 100,
          left: -80,
          child: _Blob(color: AppTheme.accent.withValues(alpha: 0.08), size: 250),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
            child: Container(color: Colors.transparent),
          ),
        ),
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  final Color color;
  final double size;
  const _Blob({required this.color, required this.size});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
