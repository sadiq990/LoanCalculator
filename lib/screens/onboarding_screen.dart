import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../providers/settings_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: 'Welcome to Loan Tracker',
      description: 'The most elegant way to manage your debts and financial progress.',
      icon: Icons.account_balance_rounded,
      color: AppTheme.primary,
    ),
    OnboardingData(
      title: 'Track Every Payment',
      description: 'Record your steady progress and see exactly how much you save with extra payments.',
      icon: Icons.payments_rounded,
      color: AppTheme.success,
    ),
    OnboardingData(
      title: 'Smart Insights',
      description: 'Interactive charts and simulations help you plan your path to being debt-free.',
      icon: Icons.analytics_rounded,
      color: AppTheme.accent,
    ),
    OnboardingData(
      title: 'Secure & Private',
      description: 'Your financial data stays on your device. Secure it with FaceID or Fingerprint.',
      icon: Icons.security_rounded,
      color: AppTheme.warning,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _finishOnboarding() {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    settings.completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient Orbs
          Positioned(
            top: -100,
            right: -50,
            child: _BlurCircle(color: _pages[_currentPage].color.withOpacity(0.12), size: 300),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: _BlurCircle(color: AppTheme.primary.withOpacity(0.08), size: 250),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Logo & App Name
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.account_balance_rounded, color: AppTheme.primary, size: 24),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Loan Tracker',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: -0.5),
                    ),
                  ],
                ),

                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) => setState(() => _currentPage = index),
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      final page = _pages[index];
                      return Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 800),
                              curve: Curves.easeOutBack,
                              key: ValueKey(index),
                              builder: (context, val, child) {
                                return Transform.scale(
                                  scale: val,
                                  child: Opacity(
                                    opacity: val,
                                    child: _AnimatedPulseIcon(
                                      icon: page.icon,
                                      color: page.color,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 48),
                            Text(
                              page.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              page.description,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16, color: AppTheme.textLight, height: 1.5),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Footer
                Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Indicators
                      Row(
                        children: List.generate(
                          _pages.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(right: 6),
                            width: _currentPage == index ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentPage == index ? AppTheme.primary : AppTheme.divider,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),

                      // Next / Start Button
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          if (_currentPage < _pages.length - 1) {
                            _pageController.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOutCubic);
                          } else {
                            _finishOnboarding();
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              )
                            ],
                          ),
                          child: Row(
                            children: [
                              Text(
                                _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingData({required this.title, required this.description, required this.icon, required this.color});
}

class _BlurCircle extends StatelessWidget {
  final Color color;
  final double size;
  const _BlurCircle({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: BackdropFilter(filter: ColorFilter.mode(Colors.white.withOpacity(0.1), BlendMode.softLight)),
    );
  }
}

class _AnimatedPulseIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  const _AnimatedPulseIcon({required this.icon, required this.color});

  @override
  State<_AnimatedPulseIcon> createState() => _AnimatedPulseIconState();
}

class _AnimatedPulseIconState extends State<_AnimatedPulseIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.15).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _opacity = Tween<double>(begin: 0.1, end: 0.25).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: widget.color.withOpacity(_opacity.value),
              shape: BoxShape.circle,
            ),
            child: Transform.scale(scale: _scale.value, child: child),
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: widget.color.withOpacity(0.2), width: 2),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.15),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: -5,
              )
            ],
          ),
          child: Icon(widget.icon, size: 80, color: widget.color),
        ),
      ],
    );
  }
}
