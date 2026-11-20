import 'package:flutter_test/flutter_test.dart';
import 'package:loan_calculator/models/loan.dart';
import 'package:loan_calculator/models/payment.dart';

void main() {
  group('Amortization Long Term & Edge Case Tests', () {
    test('30-year mortgage: \$300,000 at 6% over 360 months has valid payment, interest, no NaN/Infinity', () {
      final loan = Loan(
        id: 'mortgage-30yr',
        name: '30-Year Mortgage',
        totalAmount: 300000.0,
        interestRate: 6.0,
        termMonths: 360,
        paymentDay: 1,
        createdAt: DateTime(2024, 1, 1),
      );

      // 1. Monthly payment expected: 1798.65
      expect(loan.monthlyRequired, closeTo(1798.65, 0.02));

      final schedule = loan.getOriginalAmortizationSchedule();

      // Verify no NaN or Infinity anywhere in the 360 months
      for (int i = 0; i < schedule.length; i++) {
        final entry = schedule[i];
        expect(entry.payment.isNaN, isFalse, reason: 'Month ${i + 1} payment is NaN');
        expect(entry.payment.isInfinite, isFalse, reason: 'Month ${i + 1} payment is Infinite');
        expect(entry.interest.isNaN, isFalse, reason: 'Month ${i + 1} interest is NaN');
        expect(entry.interest.isInfinite, isFalse, reason: 'Month ${i + 1} interest is Infinite');
        expect(entry.principal.isNaN, isFalse, reason: 'Month ${i + 1} principal is NaN');
        expect(entry.principal.isInfinite, isFalse, reason: 'Month ${i + 1} principal is Infinite');
        expect(entry.remainingBalance.isNaN, isFalse, reason: 'Month ${i + 1} remainingBalance is NaN');
        expect(entry.remainingBalance.isInfinite, isFalse, reason: 'Month ${i + 1} remainingBalance is Infinite');
      }

      // Expected total interest approx 347,514.57
      final totalInterest = schedule.fold<double>(0, (sum, e) => sum + e.interest);
      expect(totalInterest, closeTo(347514.57, 50.0));

      // Final balance must be 0
      expect(schedule.last.remainingBalance, closeTo(0.0, 0.05));
    });

    test('40-year mortgage (480 months) should amortize all 480 months and reach 0 balance', () {
      final loan = Loan(
        id: 'mortgage-40yr',
        name: '40-Year Mortgage',
        totalAmount: 200000.0,
        interestRate: 5.5,
        termMonths: 480,
        paymentDay: 1,
        createdAt: DateTime(2024, 1, 1),
      );

      final schedule = loan.getOriginalAmortizationSchedule();
      expect(schedule.length, greaterThan(360), reason: 'Schedule should not be capped at 360 months for 40-year loan');
      expect(schedule.length, equals(480));
      expect(schedule.last.remainingBalance, equals(0.0));
    });

    test('QA-02 fix: 480 months at 12% for several principals must end at exactly 480 rows with 0.00 final balance and sum of payments = principal + interest within 1 cent', () {
      final principals = [10000.0, 50000.0, 100000.0, 250000.0, 500000.0, 1000000.0];
      for (final principal in principals) {
        final loan = Loan(
          id: 'test-480m-12p-$principal',
          name: '480 Months 12%',
          totalAmount: principal,
          interestRate: 12.0,
          termMonths: 480,
          paymentDay: 1,
          createdAt: DateTime(2024, 1, 1),
        );

        final schedule = loan.getOriginalAmortizationSchedule();
        expect(schedule.length, equals(480),
            reason: 'Principal $principal must have exactly 480 rows');
        expect(schedule.last.remainingBalance, equals(0.0),
            reason: 'Principal $principal final balance must be exactly 0.00');

        final totalPayments = schedule.fold<double>(0.0, (sum, e) => sum + e.payment);
        final totalPrincipal = schedule.fold<double>(0.0, (sum, e) => sum + e.principal);
        final totalInterest = schedule.fold<double>(0.0, (sum, e) => sum + e.interest);

        expect(totalPrincipal, closeTo(principal, 0.01),
            reason: 'Principal $principal: sum of principal paid must equal borrowed amount within 1 cent');
        expect(totalPayments, closeTo(totalPrincipal + totalInterest, 0.01),
            reason: 'Principal $principal: sum of payments must equal principal + interest within 1 cent');
      }
    });

    test('0% interest loan: \$1200 over 12 months', () {
      final loan = Loan(
        id: 'zero-int',
        name: 'Zero Interest',
        totalAmount: 1200.0,
        interestRate: 0.0,
        termMonths: 12,
        paymentDay: 1,
        createdAt: DateTime(2024, 1, 1),
      );

      expect(loan.monthlyRequired, equals(100.0));
      final schedule = loan.getOriginalAmortizationSchedule();
      expect(schedule.length, equals(12));
      for (final e in schedule) {
        expect(e.interest, equals(0.0));
        expect(e.principal, equals(100.0));
        expect(e.payment, equals(100.0));
      }
      expect(schedule.last.remainingBalance, equals(0.0));
    });

    test('1-month term loan: \$500 at 12%', () {
      final loan = Loan(
        id: 'one-month',
        name: 'One Month Loan',
        totalAmount: 500.0,
        interestRate: 12.0,
        termMonths: 1,
        paymentDay: 1,
        createdAt: DateTime(2024, 1, 1),
      );

      expect(loan.monthlyRequired, closeTo(505.0, 0.01));
      final schedule = loan.getOriginalAmortizationSchedule();
      expect(schedule.length, equals(1));
      expect(schedule.first.interest, closeTo(5.0, 0.01));
      expect(schedule.first.principal, closeTo(500.0, 0.01));
      expect(schedule.first.remainingBalance, closeTo(0.0, 0.01));
    });

    test('Standard auto loan: \$24,000 at 5% for 48 months expected payment 552.70', () {
      final loan = Loan(
        id: 'auto-loan',
        name: 'Auto Loan',
        totalAmount: 24000.0,
        interestRate: 5.0,
        termMonths: 48,
        paymentDay: 1,
        createdAt: DateTime(2024, 1, 1),
      );

      expect(loan.monthlyRequired, closeTo(552.70, 0.01));
      final schedule = loan.getOriginalAmortizationSchedule();
      expect(schedule.length, equals(48));
      expect(schedule.last.remainingBalance, closeTo(0.0, 0.05));
    });

    test('Extra payment larger than the remaining balance clears the loan in that month', () {
      final now = DateTime(2024, 1, 1);
      final loan = Loan(
        id: 'large-extra',
        name: 'Large Extra Payment Loan',
        totalAmount: 1000.0,
        interestRate: 5.0,
        termMonths: 12,
        paymentDay: 1,
        createdAt: now,
        payments: [
          Payment(id: 'p1', amount: 1500.0, date: DateTime(2024, 1, 15)),
        ],
      );

      final schedule = loan.getOriginalAmortizationSchedule();
      expect(schedule.length, equals(1));
      expect(schedule.first.remainingBalance, closeTo(0.0, 0.01));
    });

    test('Reduce Term vs Reduce Payment with \$500 extra on 30-year mortgage', () {
      final loanTerm = Loan(
        id: 'mortgage-term',
        name: 'Mortgage Reduce Term',
        totalAmount: 300000.0,
        interestRate: 6.0,
        termMonths: 360,
        paymentDay: 1,
        createdAt: DateTime(2024, 1, 1),
        extraPaymentMode: ExtraPaymentMode.reduceTerm,
      );

      final loanPmt = Loan(
        id: 'mortgage-pmt',
        name: 'Mortgage Reduce Payment',
        totalAmount: 300000.0,
        interestRate: 6.0,
        termMonths: 360,
        paymentDay: 1,
        createdAt: DateTime(2024, 1, 1),
        extraPaymentMode: ExtraPaymentMode.reducePayment,
      );

      // Reduce Term: expected payoff approx 212 months
      final schedTerm = loanTerm.getOriginalAmortizationSchedule(extraMonthlyPayment: 500.0);
      expect(schedTerm.length, closeTo(212, 3), reason: 'Reduce Term should pay off in approx 212 months');
      expect(schedTerm.last.remainingBalance, closeTo(0.0, 0.05));

      // Reduce Payment: should not throw FormatException: Infinity is not a valid format
      final schedPmt = loanPmt.getOriginalAmortizationSchedule(extraMonthlyPayment: 500.0);
      expect(schedPmt, isNotEmpty);
      expect(schedPmt.length, greaterThan(250));
      expect(schedPmt.last.remainingBalance, closeTo(0.0, 0.05));
    });
  });
}
