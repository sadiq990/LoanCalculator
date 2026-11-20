import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// Single source of truth for resolving device locale currency symbol
String getDefaultLocaleCurrencySymbol() {
  if (kIsWeb) return '\$';
  try {
    final locale = Platform.localeName;
    final format = NumberFormat.simpleCurrency(locale: locale);
    if (format.currencySymbol.isNotEmpty) {
      return format.currencySymbol;
    }
  } catch (_) {}
  return '\$'; // fallback to USD if undetectable
}

class CurrencyFormatter {
  static String format(double amount, {String? symbol, String? locale}) {
    final effectiveSymbol = symbol ?? getDefaultLocaleCurrencySymbol();
    String effectiveLocale = 'en_US';
    if (locale != null) {
      effectiveLocale = locale;
    } else if (!kIsWeb) {
      try {
        if (Platform.localeName.isNotEmpty) {
          effectiveLocale = Platform.localeName;
        }
      } catch (_) {
        effectiveLocale = 'en_US';
      }
    }

    try {
      return NumberFormat.currency(
        locale: effectiveLocale,
        symbol: effectiveSymbol,
        decimalDigits: 2,
      ).format(amount);
    } catch (_) {
      return NumberFormat.currency(
        symbol: effectiveSymbol,
        decimalDigits: 2,
      ).format(amount);
    }
  }
}

String formatCurrency(double amount, {String? symbol}) {
  return CurrencyFormatter.format(amount, symbol: symbol);
}
