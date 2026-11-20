import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../providers/settings_provider.dart';
import '../services/secure_pin_service.dart';

class PinEntryScreen extends StatefulWidget {
  final VoidCallback onSuccess;
  final bool isSetupMode;
  final Function(String)? onPinSet;
  final Future<PinVerifyResult> Function(String)? onVerifyPin;

  // Kept for backward compatibility if callers pass storedPin
  final String? storedPin;

  const PinEntryScreen({
    super.key,
    required this.onSuccess,
    this.isSetupMode = false,
    this.onPinSet,
    this.onVerifyPin,
    this.storedPin,
  });

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen> {
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  String? _errorMessage;
  bool _showError = false;
  bool _isVerifying = false;

  int _remainingLockoutSeconds = 0;
  Timer? _lockoutTimer;

  bool get _isLockedOut => _remainingLockoutSeconds > 0;

  @override
  void initState() {
    super.initState();
    if (!widget.isSetupMode) {
      _checkInitialLockout();
    }
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkInitialLockout() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final remaining = await settings.getRemainingLockoutSeconds();
    if (remaining > 0 && mounted) {
      _startLockoutTimer(remaining);
    }
  }

  void _startLockoutTimer(int seconds) {
    _lockoutTimer?.cancel();
    setState(() {
      _remainingLockoutSeconds = seconds;
      _showError = true;
      _errorMessage = 'Too many failed attempts. Locked for ${_remainingLockoutSeconds}s.';
    });

    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingLockoutSeconds <= 1) {
        timer.cancel();
        setState(() {
          _remainingLockoutSeconds = 0;
          _showError = false;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _remainingLockoutSeconds--;
          _errorMessage = 'Too many failed attempts. Locked for ${_remainingLockoutSeconds}s.';
        });
      }
    });
  }

  void _addDigit(String digit) {
    if (_isLockedOut || _isVerifying) return;
    HapticFeedback.lightImpact();
    if (_pin.length < 6) {
      setState(() {
        _pin += digit;
        _errorMessage = null;
        _showError = false;
      });
      if (_pin.length == 6) {
        _handlePinComplete();
      }
    }
  }

  void _removeDigit() {
    if (_isLockedOut || _isVerifying) return;
    HapticFeedback.lightImpact();
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _errorMessage = null;
        _showError = false;
      });
    }
  }

  Future<void> _handlePinComplete() async {
    if (widget.isSetupMode) {
      if (!_isConfirming) {
        // First entry - move to confirm
        setState(() {
          _confirmPin = _pin;
          _pin = '';
          _isConfirming = true;
        });
      } else {
        // Confirming - check match
        if (_pin == _confirmPin) {
          widget.onPinSet?.call(_pin);
          widget.onSuccess();
        } else {
          HapticFeedback.heavyImpact();
          setState(() {
            _pin = '';
            _confirmPin = '';
            _isConfirming = false;
            _errorMessage = 'PINs do not match. Try again.';
            _showError = true;
          });
        }
      }
    } else {
      // Verification mode
      setState(() => _isVerifying = true);
      try {
        final settings = Provider.of<SettingsProvider>(context, listen: false);
        final result = widget.onVerifyPin != null
            ? await widget.onVerifyPin!(_pin)
            : await settings.verifyPin(_pin);

        if (!mounted) return;

        if (result.success) {
          HapticFeedback.mediumImpact();
          widget.onSuccess();
        } else {
          HapticFeedback.heavyImpact();
          setState(() {
            _pin = '';
            _showError = true;
            _errorMessage = result.errorMessage ?? 'Incorrect PIN. Try again.';
          });

          if (result.isLockedOut && result.remainingLockoutSeconds > 0) {
            _startLockoutTimer(result.remainingLockoutSeconds);
          }
        }
      } finally {
        if (mounted) {
          setState(() => _isVerifying = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isSetupMode
        ? (_isConfirming ? 'Confirm Your PIN' : 'Create a PIN')
        : 'Enter Your PIN';

    final subtitle = widget.isSetupMode
        ? (_isConfirming
            ? 'Re-enter your 6-digit PIN'
            : 'Create a 6-digit PIN to secure your data')
        : (_isLockedOut
            ? 'Account temporarily locked. Please wait.'
            : 'Enter your 6-digit PIN');

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            // Lock icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: (_isLockedOut ? AppTheme.error : AppTheme.primary).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isLockedOut
                    ? Icons.lock_clock_rounded
                    : (widget.isSetupMode ? Icons.lock_outline_rounded : Icons.lock_rounded),
                size: 40,
                color: _isLockedOut ? AppTheme.error : AppTheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: _isLockedOut ? AppTheme.error : AppTheme.textLight,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 40),
            // PIN dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) {
                final isFilled = index < _pin.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: isFilled ? 16 : 14,
                  height: isFilled ? 16 : 14,
                  decoration: BoxDecoration(
                    color: isFilled
                        ? (_showError ? AppTheme.error : AppTheme.primary)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _showError
                          ? AppTheme.error
                          : (isFilled ? AppTheme.primary : AppTheme.textLight),
                      width: 2,
                    ),
                  ),
                );
              }),
            ),
            // Error message
            if (_showError && _errorMessage != null) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.error,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const Spacer(),
            // Number pad
            _buildNumberPad(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberPad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 60),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNumberButton('1'),
              _buildNumberButton('2'),
              _buildNumberButton('3'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNumberButton('4'),
              _buildNumberButton('5'),
              _buildNumberButton('6'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNumberButton('7'),
              _buildNumberButton('8'),
              _buildNumberButton('9'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 72, height: 72), // Empty space
              _buildNumberButton('0'),
              _buildDeleteButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNumberButton(String digit) {
    final disabled = _isLockedOut || _isVerifying;
    return GestureDetector(
      onTap: disabled ? null : () => _addDigit(digit),
      child: Opacity(
        opacity: disabled ? 0.35 : 1.0,
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              digit,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    final disabled = _isLockedOut || _isVerifying;
    return GestureDetector(
      onTap: disabled ? null : _removeDigit,
      child: Opacity(
        opacity: disabled ? 0.35 : 1.0,
        child: Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              Icons.backspace_outlined,
              size: 28,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
