import 'package:flutter_test/flutter_test.dart';
import 'package:loan_calculator/models/loan.dart';
import 'package:loan_calculator/models/payment.dart';

void main() {
  group('Loan Model Unit Tests', () {
    test('Monthly payment calculation for standard loan', () {
      final loan = Loan(
        id: 'test-1',
        name: 'Car Loan',
        totalAmount: 24000,
        interestRate: 5,
        termMonths: 48,
        paymentDay: 15,
        createdAt: DateTime(2024, 1, 1),
      );

      // Formula: P * r * (1 + r)^n / ((1 + r)^n - 1)
      // Expect approx 552.73
      expect(loan.monthlyRequired, closeTo(552.73, 0.01));
    });

    test('Monthly payment for zero-interest loan', () {
      final loan = Loan(
        id: 'test-2',
        name: 'Interest-Free',
        totalAmount: 1200,
        interestRate: 0,
        termMonths: 12,
        paymentDay: 1,
        createdAt: DateTime(2024, 1, 1),
      );

      expect(loan.monthlyRequired, 100.0);
    });

    test('Total paid and progress tracking', () {
      final now = DateTime.now();
      final loan = Loan(
        id: 'test-3',
        name: 'Progress Test',
        totalAmount: 1000,
        interestRate: 0,
        termMonths: 10,
        paymentDay: 1,
        createdAt: now.subtract(const Duration(days: 60)),
        payments: [
          Payment(id: 'p1', amount: 100, date: now.subtract(const Duration(days: 30))),
          Payment(id: 'p2', amount: 150, date: now.subtract(const Duration(days: 5))),
        ],
      );

      expect(loan.totalPaid, 250.0);
      expect(loan.progress, 0.25); // 250 / 1000
    });

    test('Amortization schedule generation length', () {
      final loan = Loan(
        id: 'test-4',
        name: 'Schedule Test',
        totalAmount: 5000,
        interestRate: 10,
        termMonths: 12,
        paymentDay: 1,
        createdAt: DateTime.now(),
      );

      final schedule = loan.getOriginalAmortizationSchedule();
      // Should result in ~12 months
      expect(schedule.length, 12);
      expect(schedule.last.remainingBalance, closeTo(0, 0.05));
    });
  });
}
