import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../models/loan.dart';
import '../../models/payment.dart';

export '../../models/loan.dart' show ExtraPaymentMode;

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  late Box<Loan> _loansBox;
  bool _initialized = false;

  DatabaseHelper._init();

  /// Initialize Hive database
  Future<void> init() async {
    try {
      if (_initialized) return;

      debugPrint('DatabaseHelper: Initializing Hive...');

      // Initialize Hive
      await Hive.initFlutter();

      // Register adapters BEFORE opening boxes
      debugPrint('DatabaseHelper: Registering adapters...');
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(LoanAdapter());
        debugPrint('DatabaseHelper: Registered LoanAdapter (typeId 0)');
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(PaymentAdapter());
        debugPrint('DatabaseHelper: Registered PaymentAdapter (typeId 1)');
      }

      debugPrint('DatabaseHelper: Opening Hive boxes...');

      // Try to open boxes, if they're corrupted, delete and recreate
      try {
        _loansBox = await Hive.openBox<Loan>('loans');
        debugPrint('DatabaseHelper: Loans box opened successfully');
      } catch (e) {
        debugPrint('WARNING: Failed to open loans box, clearing corrupted data: $e');
        
        // Delete corrupted boxes
        try {
          await Hive.deleteBoxFromDisk('loans');
          debugPrint('DatabaseHelper: Deleted corrupted loans box');
        } catch (deleteError) {
          debugPrint('Could not delete loans box: $deleteError');
        }

        // Try again
        _loansBox = await Hive.openBox<Loan>('loans');
        debugPrint('DatabaseHelper: Loans box recreated successfully');
      }

      _initialized = true;
      debugPrint('DatabaseHelper: Hive initialized successfully');
    } catch (e) {
      debugPrint('ERROR: DatabaseHelper init failed: $e');
      debugPrint('Stack: ${StackTrace.current}');
      rethrow;
    }
  }

  /// Get all loans
  Future<List<Loan>> getAllLoans() async {
    try {
      return _loansBox.values.toList();
    } catch (e) {
      debugPrint('Error getting all loans: $e');
      return [];
    }
  }

  /// Get a single loan by ID
  Future<Loan?> getLoan(String loanId) async {
    try {
      return _loansBox.get(loanId);
    } catch (e) {
      debugPrint('Error getting loan: $e');
      return null;
    }
  }

  /// Insert a new loan
  Future<void> insertLoan(Loan loan) async {
    try {
      await _loansBox.put(loan.id, loan);
      debugPrint('Loan saved: ${loan.id}');
    } catch (e) {
      debugPrint('Error inserting loan: $e');
      rethrow;
    }
  }

  /// Update an existing loan
  Future<void> updateLoan(Loan loan) async {
    try {
      await _loansBox.put(loan.id, loan);
      debugPrint('Loan updated: ${loan.id}');
    } catch (e) {
      debugPrint('Error updating loan: $e');
      rethrow;
    }
  }

  /// Delete a loan
  Future<void> deleteLoan(String loanId) async {
    try {
      await _loansBox.delete(loanId);
      debugPrint('Loan deleted: $loanId');
    } catch (e) {
      debugPrint('Error deleting loan: $e');
      rethrow;
    }
  }

  /// Insert a payment
  Future<void> insertPayment(String loanId, Payment payment) async {
    try {
      // Update loan with new payment
      final loan = _loansBox.get(loanId);
      if (loan != null) {
        final updatedPayments = [...loan.payments, payment];
        final updatedLoan = loan.copyWith(payments: updatedPayments);
        await _loansBox.put(loanId, updatedLoan);
        debugPrint('Payment saved for loan: $loanId');
      }
    } catch (e) {
      debugPrint('Error inserting payment: $e');
      rethrow;
    }
  }

  /// Clear all data
  Future<void> clearAll() async {
    try {
      await _loansBox.clear();
      debugPrint('All data cleared');
    } catch (e) {
      debugPrint('Error clearing data: $e');
      rethrow;
    }
  }

  /// Close database
  Future<void> close() async {
    try {
      await _loansBox.close();
      await Hive.close();
      _initialized = false;
      debugPrint('Database closed');
    } catch (e) {
      debugPrint('Error closing database: $e');
    }
  }
}

/// Hive Adapter for Loan model
class LoanAdapter extends TypeAdapter<Loan> {
  @override
  final typeId = 0;

  @override
  Loan read(BinaryReader reader) {
    final paymentsList = reader.readList();
    final extraPaymentModeStr = reader.readString();
    return Loan(
      id: reader.readString(),
      name: reader.readString(),
      totalAmount: reader.readDouble(),
      interestRate: reader.readDouble(),
      termMonths: reader.readInt(),
      paymentDay: reader.readInt(),
      createdAt: DateTime.parse(reader.readString()),
      payments: List<Payment>.from(paymentsList),
      iconId: reader.readString(),
      extraPaymentMode: extraPaymentModeStr == 'reducePayment'
          ? ExtraPaymentMode.reducePayment
          : ExtraPaymentMode.reduceTerm,
    );
  }

  @override
  void write(BinaryWriter writer, Loan obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeDouble(obj.totalAmount);
    writer.writeDouble(obj.interestRate);
    writer.writeInt(obj.termMonths);
    writer.writeInt(obj.paymentDay);
    writer.writeString(obj.createdAt.toIso8601String());
    writer.writeList(obj.payments);
    writer.writeString(obj.iconId);
    writer.writeString(obj.extraPaymentMode.name);
  }
}

/// Hive Adapter for Payment model
class PaymentAdapter extends TypeAdapter<Payment> {
  @override
  final typeId = 1;

  @override
  Payment read(BinaryReader reader) {
    return Payment(
      id: reader.readString(),
      amount: reader.readDouble(),
      date: DateTime.parse(reader.readString()),
      note: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, Payment obj) {
    writer.writeString(obj.id);
    writer.writeDouble(obj.amount);
    writer.writeString(obj.date.toIso8601String());
    writer.writeString(obj.note ?? '');
  }
}
