import '../models/loan.dart';
import '../models/payment.dart';
import 'package:flutter/foundation.dart';
import '../core/database/database_helper.dart';

/// Service for persisting loan data using SQLite
class StorageService {
  final _db = DatabaseHelper.instance;
  bool _initialized = false;

  /// Global revision counter that increments on any loan data mutation
  final ValueNotifier<int> revision = ValueNotifier<int>(0);

  void notifyLoanChange() {
    revision.value++;
  }

  Future<void> init() async {
    try {
      debugPrint('StorageService: Starting initialization...');
      
      // Initialize database
      await _db.init();
      debugPrint('StorageService: Database initialized successfully');
      
      _initialized = true;
    } catch (e) {
      debugPrint('ERROR: StorageService init failed: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  /// Ensure service is initialized before operations
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await init();
    }
  }

  /// Get all saved loans
  Future<List<Loan>> getLoans() async {
    try {
      await _ensureInitialized();
      return await _db.getAllLoans();
    } catch (e) {
      debugPrint('Error getting loans: $e');
      return [];
    }
  }

  /// Add a new loan
  Future<void> addLoan(Loan loan) async {
    try {
      await _ensureInitialized();
      await _db.insertLoan(loan);
      notifyLoanChange();
    } catch (e) {
      debugPrint('Error adding loan: $e');
      rethrow;
    }
  }

  /// Update an existing loan
  Future<void> updateLoan(Loan updatedLoan) async {
    try {
      await _ensureInitialized();
      await _db.updateLoan(updatedLoan);
      notifyLoanChange();
    } catch (e) {
      debugPrint('Error updating loan: $e');
      rethrow;
    }
  }

  /// Delete a loan by ID
  Future<void> deleteLoan(String loanId) async {
    try {
      await _ensureInitialized();
      await _db.deleteLoan(loanId);
      notifyLoanChange();
    } catch (e) {
      debugPrint('Error deleting loan: $e');
      rethrow;
    }
  }

  /// Add a payment to a loan
  Future<Loan?> addPayment(String loanId, Payment payment) async {
    try {
      await _ensureInitialized();
      await _db.insertPayment(loanId, payment);
      notifyLoanChange();
      return await getLoan(loanId);
    } catch (e) {
      debugPrint('Error adding payment: $e');
      rethrow;
    }
  }

  /// Get a single loan by ID
  Future<Loan?> getLoan(String loanId) async {
    try {
      await _ensureInitialized();
      return await _db.getLoan(loanId);
    } catch (e) {
      debugPrint('Error getting loan: $e');
      return null;
    }
  }

  /// Clear all data
  Future<void> clearAll() async {
    try {
      await _ensureInitialized();
      await _db.clearAll();
      notifyLoanChange();
    } catch (e) {
      debugPrint('Error clearing data: $e');
      rethrow;
    }
  }

  /// Replaces all loans atomically with the provided list
  Future<void> replaceAllLoans(List<Loan> newLoans) async {
    await _ensureInitialized();
    await _db.clearAll();
    for (final loan in newLoans) {
      await _db.insertLoan(loan);
    }
    notifyLoanChange();
  }

  /// Merges imported loans: updates existing loans and adds new ones
  Future<void> mergeLoans(List<Loan> importedLoans) async {
    await _ensureInitialized();
    for (final loan in importedLoans) {
      final existing = await _db.getLoan(loan.id);
      if (existing != null) {
        await _db.updateLoan(loan);
      } else {
        await _db.insertLoan(loan);
      }
    }
    notifyLoanChange();
  }
}
