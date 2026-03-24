import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../services/auth_service.dart';
import '../providers/settings_provider.dart';
import 'pin_entry_screen.dart';

class LockScreen extends StatefulWidget {
  final VoidCallback onUnlock;
  const LockScreen({super.key, required this.onUnlock});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> with SingleTickerProviderStateMixin {
  final AuthService _auth = AuthService();
  late AnimationController _pulseController;
  late Animation<double> _pulseScale;
  bool _showPinEntry = false;
  bool _biometricFailed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _pulseScale = Tween<double>(begin: 1.0, end: 1.1).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    // Auto-authenticate on load
    WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _authenticate() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final success = await _auth.authenticate();
    if (success) {
      HapticFeedback.mediumImpact();
      widget.onUnlock();
    } else {
      // Biometric failed - show PIN option
      if (settings.pin != null) {
        setState(() {
          _biometricFailed = true;
          _showPinEntry = true;
        });
      }
    }
  }

  void _onPinSuccess() {
    HapticFeedback.mediumImpact();
    widget.onUnlock();
  }

  @override
  Widget build(BuildContext context) {
    if (_showPinEntry) {
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      return PinEntryScreen(
        onSuccess: _onPinSuccess,
        storedPin: settings.pin,
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primary.withValues(alpha: 0.1),
              AppTheme.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Icon with pulse
              ScaleTransition(
                scale: _pulseScale,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_person_rounded,
                    size: 48,
                    color: AppTheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Wallet Locked',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  _biometricFailed
                      ? 'Biometric authentication failed. Please use your PIN or try again.'
                      : 'Verify your identity to access your loan statistics and payment history.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppTheme.textLight,
                    height: 1.5,
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    // Biometric button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton.icon(
                        onPressed: _authenticate,
                        icon: const Icon(Icons.fingerprint_rounded),
                        label: Text(_biometricFailed ? 'Try Again' : 'Unlock with Biometrics'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // PIN fallback button
                    Consumer<SettingsProvider>(
                      builder: (context, settings, _) {
                        if (settings.pin == null) return const SizedBox.shrink();
                        return Column(
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                setState(() => _showPinEntry = true);
                              },
                              icon: const Icon(Icons.pin_rounded, size: 20),
                              label: const Text('Use PIN Instead'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Protected by system biometrics',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textLight.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
