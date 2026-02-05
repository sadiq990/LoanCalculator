import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.decimalPattern('en_US');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Remove existing non-digit characters to get raw number
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // Prevent leading zeros unless it represents "0"
    if (newText.startsWith('0') && newText.length > 1) {
      newText = newText.substring(1);
    }

    if (newText.isEmpty) return newValue.copyWith(text: '');

    // Format the number
    final double value = double.parse(newText);
    final String formatted = _formatter.format(value);

    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
