import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_theme.dart';

class PinEntryScreen extends StatefulWidget {
  final VoidCallback onSuccess;
  final String? storedPin;
  final bool isSetupMode;
  final Function(String)? onPinSet;

  const PinEntryScreen({
    super.key,
    required this.onSuccess,
    this.storedPin,
    this.isSetupMode = false,
    this.onPinSet,
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

  void _addDigit(String digit) {
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
      if (_pin == widget.storedPin) {
        HapticFeedback.mediumImpact();
        widget.onSuccess();
      } else {
        HapticFeedback.heavyImpact();
        setState(() {
          _pin = '';
          _errorMessage = 'Incorrect PIN. Try again.';
          _showError = true;
        });
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
        : 'Enter your 6-digit PIN';

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
                color: AppTheme.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.isSetupMode ? Icons.lock_outline_rounded : Icons.lock_rounded,
                size: 40,
                color: AppTheme.primary,
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
                  color: AppTheme.textLight,
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
              Text(
                _errorMessage!,
                style: TextStyle(
                  color: AppTheme.error,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
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
    return GestureDetector(
      onTap: () => _addDigit(digit),
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
    );
  }

  Widget _buildDeleteButton() {
    return GestureDetector(
      onTap: _removeDigit,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
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
    );
  }
}
