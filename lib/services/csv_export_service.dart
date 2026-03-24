import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../models/loan.dart';

/// CSV Export Service for generating spreadsheet-compatible data
class CsvExportService {
  /// Generate CSV content for a loan's amortization schedule
  static String generateLoanCsv(Loan loan, String currencySymbol) {
    final buffer = StringBuffer();
    final dateFormat = DateFormat('yyyy-MM-dd');
    final currencyFormat = NumberFormat.currency(symbol: '', decimalDigits: 2);

    // Header row
    buffer.writeln('Loan Name,${_escapeCsv(loan.name)}');
    buffer.writeln('Principal Amount,${loan.totalAmount}');
    buffer.writeln('Interest Rate,${loan.interestRate}%');
    buffer.writeln('Term (Months),${loan.termMonths}');
    buffer.writeln('Monthly Payment,${loan.monthlyRequired}');
    buffer.writeln('Start Date,${dateFormat.format(loan.createdAt)}');
    buffer.writeln('');

    // Column headers
    buffer.writeln('#,Date,Payment ($currencySymbol),Principal ($currencySymbol),Interest ($currencySymbol),Remaining Balance ($currencySymbol),Status');

    // Schedule data
    final schedule = loan.getOriginalAmortizationSchedule();
    for (final entry in schedule) {
      final row = [
        entry.monthIndex.toString(),
        dateFormat.format(entry.date),
        currencyFormat.format(entry.payment),
        currencyFormat.format(entry.principal),
        currencyFormat.format(entry.interest),
        currencyFormat.format(entry.remainingBalance),
        entry.isPaid ? 'Paid' : 'Unpaid',
      ];
      buffer.writeln(row.join(','));
    }

    // Summary
    buffer.writeln('');
    buffer.writeln('Summary');
    buffer.writeln('Total Payments,${schedule.length}');
    buffer.writeln('Total Amount Paid,${schedule.fold<double>(0, (sum, e) => sum + e.payment)}');
    buffer.writeln('Total Interest Paid,${schedule.fold<double>(0, (sum, e) => sum + e.interest)}');
    buffer.writeln('Total Principal,${loan.totalAmount}');

    return buffer.toString();
  }

  /// Generate CSV for all loans
  static String generateAllLoansCsv(List<Loan> loans, String currencySymbol) {
    final buffer = StringBuffer();
    final dateFormat = DateFormat('yyyy-MM-dd');

    // Header
    buffer.writeln('All Loans Summary');
    buffer.writeln('');
    buffer.writeln('Loan Name,Principal ($currencySymbol),Interest Rate,Term (Months),Monthly Payment ($currencySymbol),Total Paid ($currencySymbol),Remaining ($currencySymbol),Payments Made,Status');

    for (final loan in loans) {
      final row = [
        _escapeCsv(loan.name),
        loan.totalAmount.toStringAsFixed(2),
        '${loan.interestRate}%',
        loan.termMonths.toString(),
        loan.monthlyRequired.toStringAsFixed(2),
        loan.totalPaid.toStringAsFixed(2),
        loan.remainingDebt.toStringAsFixed(2),
        loan.paymentCount.toString(),
        loan.isPaidOff ? 'Paid Off' : 'Active',
      ];
      buffer.writeln(row.join(','));
    }

    // Totals
    buffer.writeln('');
    buffer.writeln('Total Principal,${loans.fold<double>(0, (sum, l) => sum + l.totalAmount).toStringAsFixed(2)}');
    buffer.writeln('Total Paid,${loans.fold<double>(0, (sum, l) => sum + l.totalPaid).toStringAsFixed(2)}');
    buffer.writeln('Total Remaining,${loans.fold<double>(0, (sum, l) => sum + l.remainingDebt).toStringAsFixed(2)}');

    return buffer.toString();
  }

  /// Save CSV to file and return the file path
  static Future<String> saveCsvToFile(String csvContent, String fileName) async {
    if (kIsWeb) {
      // For web, we'd use a different approach
      throw UnsupportedError('Web CSV export not implemented');
    }

    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$fileName.csv';
    final file = File(filePath);
    await file.writeAsString(csvContent);
    return filePath;
  }

  /// Get temporary directory for CSV export
  static Future<String> saveToTemp(String csvContent, String fileName) async {
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/$fileName.csv';
    final file = File(filePath);
    await file.writeAsString(csvContent);
    return filePath;
  }

  static String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
