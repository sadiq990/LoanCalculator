import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loan_calculator/core/database/database_helper.dart';
import 'package:loan_calculator/models/loan.dart';
import 'package:loan_calculator/models/payment.dart';
import 'package:loan_calculator/services/backup_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('persistence_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(LoanAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(PaymentAdapter());
    }
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    await Hive.close();
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  group('Persistence & Deserialization Field Equality', () {
    test('Save loan with payments and all fields, close and reopen, verify exact equality', () async {
      final originalLoan = Loan(
        id: 'persisted-uuid-12345',
        name: 'Executive Auto Loan',
        totalAmount: 62500.75,
        interestRate: 4.85,
        termMonths: 72,
        paymentDay: 18,
        createdAt: DateTime(2025, 6, 15, 14, 30),
        iconId: 'truck',
        extraPaymentMode: ExtraPaymentMode.reducePayment,
        payments: [
          Payment(
            id: 'pay-001',
            amount: 998.42,
            date: DateTime(2025, 7, 18, 9, 0),
            note: 'July payment',
          ),
          Payment(
            id: 'pay-002',
            amount: 1500.00,
            date: DateTime(2025, 8, 18, 11, 15),
            note: 'August payment + extra',
          ),
        ],
      );

      final box = await Hive.openBox<Loan>('field_equality_box');
      await box.put(originalLoan.id, originalLoan);
      await box.close();

      final reopened = await Hive.openBox<Loan>('field_equality_box');
      final fetched = reopened.get(originalLoan.id);

      expect(fetched, isNotNull);
      expect(fetched!.id, equals(originalLoan.id));
      expect(fetched.name, equals(originalLoan.name));
      expect(fetched.totalAmount, equals(originalLoan.totalAmount));
      expect(fetched.interestRate, equals(originalLoan.interestRate));
      expect(fetched.termMonths, equals(originalLoan.termMonths));
      expect(fetched.paymentDay, equals(originalLoan.paymentDay));
      expect(fetched.createdAt, equals(originalLoan.createdAt));
      expect(fetched.iconId, equals(originalLoan.iconId));
      expect(fetched.extraPaymentMode, equals(originalLoan.extraPaymentMode));
      expect(fetched.payments.length, equals(2));

      expect(fetched.payments[0].id, equals(originalLoan.payments[0].id));
      expect(fetched.payments[0].amount, equals(originalLoan.payments[0].amount));
      expect(fetched.payments[0].date, equals(originalLoan.payments[0].date));
      expect(fetched.payments[0].note, equals(originalLoan.payments[0].note));

      expect(fetched.payments[1].id, equals(originalLoan.payments[1].id));
      expect(fetched.payments[1].amount, equals(originalLoan.payments[1].amount));
      expect(fetched.payments[1].date, equals(originalLoan.payments[1].date));
      expect(fetched.payments[1].note, equals(originalLoan.payments[1].note));
      await reopened.close();
    });
  });

  group('Database Corruption & Backup Preservation', () {
    test('Damaged box file is backed up as loans.hive.bak, never wiped from disk', () async {
      final boxName = 'loans_damaged';
      final boxFile = File('${tempDir.path}/$boxName.hive');

      // Write corrupted binary data to simulate disk sector or serialization corruption
      await boxFile.writeAsString('CORRUPTED_DATABASE_CONTENTS_THAT_MUST_BE_SAVED');
      expect(boxFile.existsSync(), isTrue);

      // Perform damaged box backup
      await DatabaseHelper.backupDamagedBox(boxName, directoryPath: tempDir.path);

      // Verify original content was safely moved to .bak
      final backupFile = File('${tempDir.path}/$boxName.hive.bak');
      expect(backupFile.existsSync(), isTrue,
          reason: 'Damaged database must be backed up as loans.hive.bak, never deleted');
      expect(await backupFile.readAsString(), equals('CORRUPTED_DATABASE_CONTENTS_THAT_MUST_BE_SAVED'));
    });

    test('Fresh box can be opened after moving damaged box out of the way', () async {
      final boxName = 'loans_recovery';
      final boxFile = File('${tempDir.path}/$boxName.hive');
      await boxFile.writeAsString('BINARY_GARBAGE');

      await DatabaseHelper.backupDamagedBox(boxName, directoryPath: tempDir.path);

      // Open a new box cleanly without corruption crash
      final freshBox = await Hive.openBox<Loan>(boxName);
      final testLoan = Loan(
        id: 'fresh-1',
        name: 'Recovered Loan',
        totalAmount: 5000,
        interestRate: 3.0,
        termMonths: 12,
        paymentDay: 1,
        createdAt: DateTime.now(),
      );
      await freshBox.put(testLoan.id, testLoan);
      expect(freshBox.length, equals(1));
      expect(freshBox.get('fresh-1')!.name, equals('Recovered Loan'));
      await freshBox.close();
    });
  });

  group('Backup Round-Trip: Merge and Replace Logic', () {
    test('JSON export then import round-trip preserves all loans and settings', () async {
      final loanA = Loan(
        id: 'loan-a',
        name: 'Personal Loan A',
        totalAmount: 15000,
        interestRate: 6.5,
        termMonths: 36,
        paymentDay: 5,
        createdAt: DateTime(2025, 1, 1),
        payments: [
          Payment(id: 'p-a1', amount: 459.72, date: DateTime(2025, 2, 5), note: 'Installment 1'),
        ],
      );

      final backupJson = {
        'schemaVersion': 1,
        'appVersion': '1.0.0',
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
        'data': {
          'settings': {
            'currencySymbol': '€',
            'themeMode': 'dark',
          },
          'loans': [loanA.toJson()],
        },
      };

      final jsonStr = jsonEncode(backupJson);
      final preview = BackupService.parseBackupJson(jsonStr);

      expect(preview.schemaVersion, equals(1));
      expect(preview.loans.length, equals(1));
      expect(preview.loans.first.id, equals('loan-a'));
      expect(preview.loans.first.name, equals('Personal Loan A'));
      expect(preview.currencySymbol, equals('€'));
      expect(preview.themeMode, equals(ThemeMode.dark));

      // Test Merge and Replace semantics directly
      final existingLoanB = Loan(
        id: 'loan-b',
        name: 'Existing Loan B',
        totalAmount: 8000,
        interestRate: 4.0,
        termMonths: 24,
        paymentDay: 10,
        createdAt: DateTime(2025, 3, 1),
      );

      final box = await Hive.openBox<Loan>('merge_replace_box');
      await box.put(existingLoanB.id, existingLoanB);
      expect(box.length, equals(1));

      // Merge: imported loans added without deleting existing
      for (final loan in preview.loans) {
        await box.put(loan.id, loan);
      }
      expect(box.length, equals(2));
      expect(box.containsKey('loan-a'), isTrue);
      expect(box.containsKey('loan-b'), isTrue);

      // Replace: clear and insert only imported loans
      await box.clear();
      for (final loan in preview.loans) {
        await box.put(loan.id, loan);
      }
      expect(box.length, equals(1));
      expect(box.containsKey('loan-a'), isTrue);
      expect(box.containsKey('loan-b'), isFalse);

      await box.close();
    });
  });

  group('Backup Import Rejection & Safety Guards', () {
    test('Import of malformed JSON throws FormatException without modifying data', () {
      expect(
        () => BackupService.parseBackupJson('NOT VALID JSON {{{'),
        throwsA(isA<FormatException>()),
      );
    });

    test('Import of empty file/string throws FormatException', () {
      expect(
        () => BackupService.parseBackupJson(''),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => BackupService.parseBackupJson('   '),
        throwsA(isA<FormatException>()),
      );
    });

    test('Import of newer schemaVersion throws informative FormatException', () {
      final futureBackup = jsonEncode({
        'schemaVersion': 99,
        'appVersion': '10.0.0',
        'exportedAt': DateTime.now().toIso8601String(),
        'data': {
          'loans': [],
        },
      });

      expect(
        () => BackupService.parseBackupJson(futureBackup),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('newer version of Loan Tracker (schema version 99)'),
          ),
        ),
      );
    });

    test('Import of missing loans key throws FormatException', () {
      final missingLoans = jsonEncode({
        'schemaVersion': 1,
        'appVersion': '1.0.0',
        'data': {
          'settings': {},
        },
      });

      expect(
        () => BackupService.parseBackupJson(missingLoans),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('Missing "loans" list'),
          ),
        ),
      );
    });
  });
}
