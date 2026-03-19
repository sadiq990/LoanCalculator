import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Allow digits and comma (for decimals)
    String cleanText = newValue.text.replaceAll(RegExp(r'[^0-9,]'), '');
    
    // Check if more than one comma limit
    if (','.allMatches(cleanText).length > 1) {
      return oldValue;
    }

    List<String> parts = cleanText.split(',');
    String intPart = parts[0];
    String decimalPart = parts.length > 1 ? parts[1] : '';

    if (decimalPart.length > 2) {
       decimalPart = decimalPart.substring(0, 2);
    }

    String formattedInt = '';
    if (intPart.isNotEmpty) {
      final number = int.tryParse(intPart);
      if (number != null) {
        // use standard en_US but replace commas with dots
        formattedInt = NumberFormat('#,###', 'en_US').format(number).replaceAll(',', '.');
      }
    }

    String newString = formattedInt;
    if (parts.length > 1 || cleanText.endsWith(',')) {
      newString += ',$decimalPart';
    }

    return TextEditingValue(
      text: newString,
      selection: TextSelection.collapsed(offset: newString.length),
    );
  }
}
