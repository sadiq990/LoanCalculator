import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:loan_calculator/services/backup_service.dart';

void main() {
  group('BackupService Validation & Serialization Tests', () {
    test('Valid backup JSON parses correctly', () {
      final validJson = jsonEncode({
        'schemaVersion': 1,
        'appVersion': '1.0.0',
        'exportedAt': '2026-11-19T12:00:00.000Z',
        'data': {
          'settings': {
            'currencySymbol': '\$',
            'themeMode': 'dark',
          },
          'loans': [
            {
              'id': 'loan-1',
              'name': 'Student Loan',
              'totalAmount': 15000.0,
              'interestRate': 4.5,
              'termMonths': 60,
              'paymentDay': 15,
              'createdAt': '2025-01-01T00:00:00.000',
              'iconId': 'student',
              'extraPaymentMode': 'reduceTerm',
              'payments': [
                {
                  'id': 'pmt-1',
                  'amount': 280.0,
                  'date': '2025-02-15T00:00:00.000',
                }
              ],
            }
          ],
        },
      });

      final preview = BackupService.parseBackupJson(validJson);
      expect(preview.schemaVersion, equals(1));
      expect(preview.appVersion, equals('1.0.0'));
      expect(preview.loans.length, equals(1));
      expect(preview.loans.first.id, equals('loan-1'));
      expect(preview.loans.first.name, equals('Student Loan'));
      expect(preview.loans.first.payments.length, equals(1));
      expect(preview.currencySymbol, equals('\$'));
    });

    test('Rejects newer schemaVersion (> 1) with informative error', () {
      final futureJson = jsonEncode({
        'schemaVersion': 2,
        'appVersion': '2.0.0',
        'exportedAt': '2027-01-01T00:00:00.000Z',
        'data': {
          'loans': [],
        },
      });

      expect(
        () => BackupService.parseBackupJson(futureJson),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('newer version of Loan Tracker'),
        )),
      );
    });

    test('Rejects invalid JSON or corrupted structure without throwing untyped crash', () {
      expect(
        () => BackupService.parseBackupJson('{ not json }'),
        throwsA(isA<FormatException>()),
      );

      final missingLoansJson = jsonEncode({
        'schemaVersion': 1,
        'appVersion': '1.0.0',
        'exportedAt': '2026-11-19T12:00:00.000Z',
        'data': {
          'settings': {},
        },
      });

      expect(
        () => BackupService.parseBackupJson(missingLoansJson),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('Missing "loans" list'),
        )),
      );
    });
  });
}
