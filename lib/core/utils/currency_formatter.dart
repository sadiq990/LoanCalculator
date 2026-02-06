import 'package:intl/intl.dart';

String formatCurrency(double amount, {String symbol = '₼'}) {
  return NumberFormat.currency(symbol: symbol, decimalDigits: 0).format(amount);
}
