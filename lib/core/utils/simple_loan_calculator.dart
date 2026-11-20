import '../../models/amortization_entry.dart';
import '../../models/loan.dart';
import '../../screens/add_loan_screen.dart';

class SimpleLoanCalculatorValidation {
  final String? amountError;
  final String? rateError;
  final String? termError;

  const SimpleLoanCalculatorValidation({
    this.amountError,
    this.rateError,
    this.termError,
  });

  bool get isValid =>
      amountError == null && rateError == null && termError == null;
}

class SimpleLoanCalculatorResult {
  final double amount;
  final double annualRate;
  final int termMonths;
  final double monthlyPayment;
  final double totalInterest;
  final double totalRepaid;
  final double? lastPayment;
  final bool hasDifferentLastPayment;
  final double interestPercent;
  final List<AmortizationEntry> schedule;

  const SimpleLoanCalculatorResult({
    required this.amount,
    required this.annualRate,
    required this.termMonths,
    required this.monthlyPayment,
    required this.totalInterest,
    required this.totalRepaid,
    this.lastPayment,
    this.hasDifferentLastPayment = false,
    required this.interestPercent,
    required this.schedule,
  });

  String plainSentence(String Function(double) formatCurrency) {
    return 'You borrow ${formatCurrency(amount)} and repay ${formatCurrency(totalRepaid)}, which is ${formatCurrency(totalInterest)} more.';
  }

  String interestSummary() {
    final formatted = interestPercent % 1 == 0
        ? interestPercent.toStringAsFixed(0)
        : interestPercent.toStringAsFixed(1);
    return 'Interest is $formatted% of the amount borrowed';
  }
}

class SimpleLoanCalculator {
  static const double minAmount = 0.01;
  static const double maxAmount = 100000000.0;
  static const double minRate = 0.0;
  static const double maxRate = 100.0;
  static const int minTermMonths = 1;
  static const int maxTermMonths = 600; // 50 years

  /// Validates inputs and returns errors (if any)
  static SimpleLoanCalculatorValidation validate({
    required String amountText,
    required String rateText,
    required String termText,
    bool isYears = false,
  }) {
    String? amountError;
    String? rateError;
    String? termError;

    final trimmedAmount = amountText.trim();
    if (trimmedAmount.isEmpty) {
      amountError = 'Amount is required';
    } else {
      final parsedAmount = AddLoanScreen.parseAmount(trimmedAmount);
      if (parsedAmount == null) {
        amountError = 'Invalid amount';
      } else if (parsedAmount <= 0) {
        amountError = 'Must be greater than 0';
      } else if (parsedAmount > maxAmount) {
        amountError = 'Cannot exceed 100,000,000';
      }
    }

    final trimmedRate = rateText.trim();
    if (trimmedRate.isEmpty) {
      rateError = 'Rate is required';
    } else {
      final parsedRate = AddLoanScreen.parseAmount(trimmedRate);
      if (parsedRate == null) {
        rateError = 'Invalid rate';
      } else if (parsedRate < minRate || parsedRate > maxRate) {
        rateError = 'Rate must be 0 to 100';
      }
    }

    final trimmedTerm = termText.trim();
    if (trimmedTerm.isEmpty) {
      termError = 'Term is required';
    } else {
      final parsedTermRaw = int.tryParse(trimmedTerm);
      if (parsedTermRaw == null) {
        termError = 'Invalid term';
      } else {
        final totalMonths = isYears ? parsedTermRaw * 12 : parsedTermRaw;
        if (totalMonths < minTermMonths || totalMonths > maxTermMonths) {
          termError = isYears
              ? 'Term must be 1 to 50 years'
              : 'Term must be 1 to 600 months';
        }
      }
    }

    return SimpleLoanCalculatorValidation(
      amountError: amountError,
      rateError: rateError,
      termError: termError,
    );
  }

  /// Calculates loan results by building an in-memory, unsaved Loan and reusing
  /// the existing amortization engine. Never crashes; never returns NaN or Infinity.
  static SimpleLoanCalculatorResult? calculate({
    required double amount,
    required double annualRate,
    required int termMonths,
  }) {
    if (amount <= 0 || amount > maxAmount) return null;
    if (annualRate < 0 || annualRate > maxRate) return null;
    if (termMonths < minTermMonths || termMonths > maxTermMonths) return null;

    final inMemoryLoan = Loan(
      id: 'simple-calc-in-memory',
      name: 'Calculator Loan',
      totalAmount: amount,
      interestRate: annualRate,
      termMonths: termMonths,
      paymentDay: 1,
      createdAt: DateTime.now(),
    );

    final monthlyPayment = inMemoryLoan.monthlyRequired;
    if (monthlyPayment.isNaN || monthlyPayment.isInfinite) return null;

    final schedule = inMemoryLoan.getOriginalAmortizationSchedule();
    final totalInterest =
        schedule.fold<double>(0.0, (sum, e) => sum + e.interest);
    final totalRepaid =
        schedule.fold<double>(0.0, (sum, e) => sum + e.payment);

    double? lastPayment;
    bool hasDifferentLast = false;
    if (schedule.isNotEmpty) {
      lastPayment = schedule.last.payment;
      if ((lastPayment - monthlyPayment).abs() >= 0.005) {
        hasDifferentLast = true;
      }
    }

    final interestPercent =
        amount > 0 ? (totalInterest / amount * 100) : 0.0;

    return SimpleLoanCalculatorResult(
      amount: amount,
      annualRate: annualRate,
      termMonths: termMonths,
      monthlyPayment: (monthlyPayment * 100).round() / 100.0,
      totalInterest: (totalInterest * 100).round() / 100.0,
      totalRepaid: (totalRepaid * 100).round() / 100.0,
      lastPayment:
          lastPayment != null ? (lastPayment * 100).round() / 100.0 : null,
      hasDifferentLastPayment: hasDifferentLast,
      interestPercent: (interestPercent * 10).round() / 10.0,
      schedule: schedule,
    );
  }
}
