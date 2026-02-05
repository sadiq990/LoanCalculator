import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_theme.dart';
import '../services/auth_service.dart';

class LockScreen extends StatefulWidget {
  final VoidCallback onUnlock;

  const LockScreen({super.key, required this.onUnlock});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final AuthService _auth = AuthService();
  bool _isAuthenticating = false;
  String _message = 'Tap to unlock';

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    if (!mounted) return;
    setState(() {
      _isAuthenticating = true;
      _message = 'Scanning...';
    });

    try {
      final canUseBiometric = await _auth.isAvailable;
      if (!canUseBiometric) {
        if (mounted) {
          setState(() => _message = 'Biometric unavailable. Opening app...');
        }
        widget.onUnlock();
        return;
      }

      final authenticated = await _auth.authenticate();
      if (authenticated) {
        widget.onUnlock();
      } else {
        if (mounted) {
          setState(
            () => _message = 'Authentication failed. Tap to try again.',
          );
        }
      }
    } on PlatformException catch (e) {
      if (mounted) {
        setState(() => _message = 'Error: ${e.message}');
      }
    } on MissingPluginException {
      if (mounted) {
        setState(() => _message = 'Biometric unavailable. Opening app...');
      }
      widget.onUnlock();
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'Could not authenticate. Opening app...');
      }
      widget.onUnlock();
    } finally {
      if (mounted) setState(() => _isAuthenticating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 80,
                color: Colors.white,
              ),
              const SizedBox(height: 32),
              Text(
                'Loan Tracker Locked',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _message,
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              if (!_isAuthenticating)
                FilledButton.icon(
                  onPressed: _authenticate,
                  icon: Icon(Icons.fingerprint),
                  label: Text('Unlock'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}


