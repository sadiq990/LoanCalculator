import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/loan.dart';
import '../models/payment.dart';

/// Service for persisting loan data using SharedPreferences
class StorageService {
  static const _loansKey = 'loans_data';

  SharedPreferences? _prefs;

  /// Initialize shared preferences
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get all saved loans
  Future<List<Loan>> getLoans() async {
    _prefs ??= await SharedPreferences.getInstance();

    final jsonString = _prefs!.getString(_loansKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => Loan.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // If parsing fails, return empty list
      return [];
    }
  }

  /// Save all loans
  Future<void> saveLoans(List<Loan> loans) async {
    _prefs ??= await SharedPreferences.getInstance();

    final jsonList = loans.map((loan) => loan.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    await _prefs!.setString(_loansKey, jsonString);
  }

  /// Add a new loan
  Future<void> addLoan(Loan loan) async {
    final loans = await getLoans();
    loans.add(loan);
    await saveLoans(loans);
  }

  /// Update an existing loan
  Future<void> updateLoan(Loan updatedLoan) async {
    final loans = await getLoans();
    final index = loans.indexWhere((l) => l.id == updatedLoan.id);
    if (index != -1) {
      loans[index] = updatedLoan;
      await saveLoans(loans);
    }
  }

  /// Delete a loan by ID
  Future<void> deleteLoan(String loanId) async {
    final loans = await getLoans();
    loans.removeWhere((l) => l.id == loanId);
    await saveLoans(loans);
  }

  /// Add a payment to a loan
  Future<Loan?> addPayment(String loanId, Payment payment) async {
    final loans = await getLoans();
    final index = loans.indexWhere((l) => l.id == loanId);
    if (index != -1) {
      final updatedLoan = loans[index].addPayment(payment);
      loans[index] = updatedLoan;
      await saveLoans(loans);
      return updatedLoan;
    }
    return null;
  }

  /// Get a single loan by ID
  Future<Loan?> getLoan(String loanId) async {
    final loans = await getLoans();
    try {
      return loans.firstWhere((l) => l.id == loanId);
    } catch (e) {
      return null;
    }
  }

  /// Clear all data
  Future<void> clearAll() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.remove(_loansKey);
  }
}
