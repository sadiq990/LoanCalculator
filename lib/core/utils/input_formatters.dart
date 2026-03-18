import 'package:flutter/services.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Allow digits and at most one decimal point
    String newText = newValue.text;
    
    // Check if more than one decimal point
    if ('.'.allMatches(newText).length > 1) {
      return oldValue;
    }

    // Only allow digits and decimal point
    final regExp = RegExp(r'^[0-9]*\.?[0-9]{0,2}$');
    if (!regExp.hasMatch(newText.replaceAll(',', ''))) {
      // If it doesn't match (e.g. more than 2 decimals), keep old
      if (newText.contains('.') && newText.split('.')[1].length > 2) {
         return oldValue;
      }
    }

    return newValue;
  }
}
