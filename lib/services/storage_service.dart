import '../models/loan.dart';
import '../models/payment.dart';
import 'package:flutter/foundation.dart';
import '../core/database/database_helper.dart';

/// Service for persisting loan data using SQLite
class StorageService {
  final _db = DatabaseHelper.instance;
  bool _initialized = false;

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
    } catch (e) {
      debugPrint('Error clearing data: $e');
      rethrow;
    }
  }
}
