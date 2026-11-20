import 'package:flutter_test/flutter_test.dart';
import 'package:loan_calculator/models/loan.dart';
import 'package:loan_calculator/models/payment.dart';
import 'package:loan_calculator/screens/add_loan_screen.dart';

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
      // Expect approx 552.70
      expect(loan.monthlyRequired, closeTo(552.70, 0.01));
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

    test('Locale-aware amount parsing accepts 15000.50, 15000,50, 15,000.50, and 15.000,50', () {
      expect(AddLoanScreen.parseAmount('15000.50'), equals(15000.50));
      expect(AddLoanScreen.parseAmount('15000,50'), equals(15000.50));
      expect(AddLoanScreen.parseAmount('15,000.50'), equals(15000.50));
      expect(AddLoanScreen.parseAmount('15.000,50'), equals(15000.50));
      expect(AddLoanScreen.parseAmount('15000'), equals(15000.0));
    });

    test('F-06: Loan with no payments for 45 days shows principal unchanged and accruedInterest > 0', () {
      final now = DateTime.now();
      final loan = Loan(
        id: 'f06-45d',
        name: 'F06 45-day Loan',
        totalAmount: 10000.0,
        interestRate: 6.0,
        termMonths: 12,
        paymentDay: 1,
        createdAt: now.subtract(const Duration(days: 45)),
      );

      // Principal balance unchanged
      expect(loan.remainingDebt, equals(10000.0));
      // Accrued simple interest > 0
      expect(loan.accruedInterest, greaterThan(0.0));
      // Expected simple interest: 10000 * 0.06 * (45/365) approx 73.97
      expect(loan.accruedInterest, closeTo(73.97, 2.0));
    });

    test('F-06: After a payment the accrued value resets according to allocation, and paid-off shows 0 for both', () {
      final now = DateTime.now();
      final loan = Loan(
        id: 'f06-payment',
        name: 'F06 Payment Loan',
        totalAmount: 10000.0,
        interestRate: 6.0,
        termMonths: 12,
        paymentDay: 1,
        createdAt: now.subtract(const Duration(days: 45)),
        payments: [
          Payment(
            id: 'p1',
            amount: 500.0,
            date: now, // paid today
          ),
        ],
      );

      // After payment made today, accruedInterest resets to 0
      expect(loan.accruedInterest, equals(0.0));
      // Principal balance reduced: 500 - ~73.97 interest = ~426.03 principal paid -> ~9573.97 remaining
      expect(loan.remainingDebt, lessThan(10000.0));
      expect(loan.remainingDebt, closeTo(9573.97, 2.0));

      // Paid-off loan shows 0 for both remainingDebt and accruedInterest
      final paidOffLoan = Loan(
        id: 'f06-paidoff',
        name: 'Paid-off Loan',
        totalAmount: 1000.0,
        interestRate: 5.0,
        termMonths: 12,
        paymentDay: 1,
        createdAt: now.subtract(const Duration(days: 90)),
        payments: [
          Payment(id: 'p-full', amount: 1500.0, date: now.subtract(const Duration(days: 10))),
        ],
      );

      expect(paidOffLoan.remainingDebt, equals(0.0));
      expect(paidOffLoan.accruedInterest, equals(0.0));
    });

    test('F-06: Amortization reference values remain identical (24,000 at 5% = 552.70; 300,000 at 6% = 1,798.65)', () {
      final loan1 = Loan(
        id: 'ref-1',
        name: 'Auto Loan',
        totalAmount: 24000.0,
        interestRate: 5.0,
        termMonths: 48,
        paymentDay: 1,
        createdAt: DateTime(2024, 1, 1),
      );
      expect(loan1.monthlyRequired, closeTo(552.70, 0.01));

      final loan2 = Loan(
        id: 'ref-2',
        name: 'Mortgage Loan',
        totalAmount: 300000.0,
        interestRate: 6.0,
        termMonths: 360,
        paymentDay: 1,
        createdAt: DateTime(2024, 1, 1),
      );
      expect(loan2.monthlyRequired, closeTo(1798.65, 0.01));
    });
  });
}
