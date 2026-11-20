import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loan_calculator/core/database/database_helper.dart';
import 'package:loan_calculator/models/loan.dart';
import 'package:loan_calculator/models/payment.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_roundtrip_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(LoanAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(PaymentAdapter());
    }
  });

  tearDown(() async {
    await Hive.close();
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  group('Hive Database Roundtrip Tests', () {
    test('Save a Loan with payments and extraPaymentMode, close and reopen box, verify deserialization', () async {
      final loan = Loan(
        id: 'roundtrip-loan-1',
        name: 'Tesla Model Y Loan',
        totalAmount: 45000.0,
        interestRate: 4.99,
        termMonths: 60,
        paymentDay: 15,
        createdAt: DateTime(2024, 3, 1, 10, 0),
        iconId: 'car',
        extraPaymentMode: ExtraPaymentMode.reducePayment,
        payments: [
          Payment(
            id: 'pay-1',
            amount: 848.50,
            date: DateTime(2024, 4, 15),
            note: 'First installment',
          ),
          Payment(
            id: 'pay-2',
            amount: 1200.00,
            date: DateTime(2024, 5, 15),
            note: 'Second installment + extra principal',
          ),
        ],
      );

      // Open box and put loan
      var box = await Hive.openBox<Loan>('loans_roundtrip');
      await box.put(loan.id, loan);
      await box.close();

      // Reopen box and retrieve
      var reopenedBox = await Hive.openBox<Loan>('loans_roundtrip');
      final retrieved = reopenedBox.get(loan.id);

      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals('roundtrip-loan-1'));
      expect(retrieved.name, equals('Tesla Model Y Loan'));
      expect(retrieved.totalAmount, equals(45000.0));
      expect(retrieved.interestRate, equals(4.99));
      expect(retrieved.termMonths, equals(60));
      expect(retrieved.paymentDay, equals(15));
      expect(retrieved.createdAt, equals(DateTime(2024, 3, 1, 10, 0)));
      expect(retrieved.iconId, equals('car'));
      expect(retrieved.extraPaymentMode, equals(ExtraPaymentMode.reducePayment));
      expect(retrieved.payments.length, equals(2));
      expect(retrieved.payments[0].id, equals('pay-1'));
      expect(retrieved.payments[0].amount, equals(848.50));
      expect(retrieved.payments[0].note, equals('First installment'));
      expect(retrieved.payments[1].id, equals('pay-2'));
      expect(retrieved.payments[1].amount, equals(1200.00));
      await reopenedBox.close();
    });

    test('Corrupted box handling does NOT delete valid user data and creates a backup', () async {
      final boxFile = File('${tempDir.path}/loans.hive');
      await boxFile.writeAsString('corrupted header binary garbage');
      expect(boxFile.existsSync(), isTrue);

      await DatabaseHelper.backupDamagedBox('loans', directoryPath: tempDir.path);

      final backupFile = File('${tempDir.path}/loans.hive.bak');
      expect(backupFile.existsSync(), isTrue, reason: 'A backup copy of damaged database should be preserved');
      expect(await backupFile.readAsString(), equals('corrupted header binary garbage'));
    });

    test('QA-03: Closing DatabaseHelper twice does not leave singleton in a bad state and allows reopening', () async {
      final db = DatabaseHelper.instance;
      await db.init(customDirectory: tempDir.path);
      expect(db.isInitialized, isTrue);

      // Close once
      await db.close();
      expect(db.isInitialized, isFalse);

      // Close a second time (should not throw and should remain _initialized = false)
      await db.close();
      expect(db.isInitialized, isFalse);

      // Re-init works cleanly without error
      await db.init(customDirectory: tempDir.path);
      expect(db.isInitialized, isTrue);

      final testLoan = Loan(
        id: 'test-qa-03',
        name: 'Test QA-03',
        totalAmount: 1000,
        interestRate: 5,
        termMonths: 12,
        paymentDay: 1,
        createdAt: DateTime.now(),
      );
      await db.insertLoan(testLoan);
      final fetched = await db.getLoan('test-qa-03');
      expect(fetched, isNotNull);
      expect(fetched!.name, equals('Test QA-03'));

      // Clean up
      await db.close();
    });
  });
}
