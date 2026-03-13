import 'payment.dart';
import 'amortization_entry.dart';
import 'dart:math' as math;

/// Represents a loan with various calculation methods
class Loan {
  final String id;
  final String name;
  final double totalAmount; // Principal amount
  final double interestRate; // Annual interest rate in percent
  final int termMonths;
  final String iconId; // New field for custom icon
  late final double monthlyRequired;
  final int paymentDay;
  final DateTime createdAt;
  final List<Payment> payments;

  Loan({
    required this.id,
    required this.name,
    required this.totalAmount,
    required this.interestRate,
    required this.termMonths,
    required this.paymentDay,
    required this.createdAt,
    this.iconId = 'default',
    List<Payment>? payments,
  }) : payments = payments ?? [] {
    // Calculate standard monthly payment
    if (interestRate <= 0) {
      monthlyRequired = totalAmount / termMonths;
    } else {
      final r = (interestRate / 100) / 12;
      final n = termMonths;
      final factor = math.pow(1 + r, n).toDouble();
      monthlyRequired = totalAmount * r * factor / (factor - 1);
    }
  }

  Loan copyWith({
    String? id,
    String? name,
    double? totalAmount,
    double? interestRate,
    int? termMonths,
    int? paymentDay,
    DateTime? createdAt,
    String? iconId,
    List<Payment>? payments,
  }) {
    return Loan(
      id: id ?? this.id,
      name: name ?? this.name,
      totalAmount: totalAmount ?? this.totalAmount,
      interestRate: interestRate ?? this.interestRate,
      termMonths: termMonths ?? this.termMonths,
      paymentDay: paymentDay ?? this.paymentDay,
      createdAt: createdAt ?? this.createdAt,
      iconId: iconId ?? this.iconId,
      payments: payments ?? List.from(this.payments),
    );
  }

  /// Total amount to be paid over the life of the loan (Principal + Interest)
  double get totalContractValue => monthlyRequired * termMonths;

  /// Remaining amount of the total contract value
  double get totalRemaining {
    final val = totalContractValue - totalPaid;
    return val < 0 ? 0 : val;
  }

  /// Current Principal Balance (approximate for typical scenarios)
  double get remainingDebt {
    double balance = totalAmount;
    final sortedPayments = List<Payment>.from(payments)
      ..sort((a, b) => a.date.compareTo(b.date));

    DateTime lastDate = createdAt;
    DateTime now = DateTime.now();

    for (var payment in sortedPayments) {
      if (balance <= 0) break;

      int days = payment.date.difference(lastDate).inDays;
      if (days < 0) days = 0;

      double dailyRate = (interestRate / 100) / 365;
      double interest = balance * dailyRate * days;

      balance += interest;
      balance -= payment.amount;

      lastDate = payment.date;
    }

    if (balance > 0) {
      int days = now.difference(lastDate).inDays;
      if (days > 0) {
        double dailyRate = (interestRate / 100) / 365;
        double interest = balance * dailyRate * days;
        balance += interest;
      }
    }

    return balance < 0 ? 0 : balance;
  }

  double get totalPaid => payments.fold(0.0, (sum, p) => sum + p.amount);

  /// Progress based on Total Repayment (Principal + Interest)
  double get progress {
    if (totalContractValue <= 0) return 0;
    return totalPaid / totalContractValue;
  }

  /// Calculate amortization schedule
  /// [extraMonthlyPayment] is an optional extra amount paid EACH month
  List<AmortizationEntry> getAmortizationSchedule({
    double extraMonthlyPayment = 0,
  }) {
    final List<AmortizationEntry> schedule = [];
    double currentBalance = remainingDebt;
    // Start from next payment date (simplified: next month from now or last payment)
    DateTime currentDate = DateTime.now();

    // Safety check for invalid loans
    if (currentBalance <= 0 || monthlyRequired <= 0) return [];

    // Monthly interest rate
    final monthlyRate = interestRate / 100 / 12;

    int month = 1;

    // Limit to 30 years (360 months) to prevent infinite loops on bad data
    while (currentBalance > 0 && month <= 360) {
      // 1. Calculate Interest for this month
      double interestPayment = currentBalance * monthlyRate;

      // 2. Calculate Total Payment for this month
      double totalPayment = monthlyRequired + extraMonthlyPayment;

      // Cap payment at remaining balance + interest
      if (totalPayment > currentBalance + interestPayment) {
        totalPayment = currentBalance + interestPayment;
      }

      // 3. Calculate Principal
      double principalPayment = totalPayment - interestPayment;

      // 4. Update Balance
      currentBalance -= principalPayment;

      // Handle floating point precision
      if (currentBalance < 0.01) currentBalance = 0;

      schedule.add(
        AmortizationEntry(
          monthIndex: month,
          date: DateTime(currentDate.year, currentDate.month + month, currentDate.day),
          payment: totalPayment,
          principal: principalPayment,
          interest: interestPayment,
          remainingBalance: currentBalance,
        ),
      );

      month++;
    }

    return schedule;
  }

  bool get isPaidOff => remainingDebt <= 1.0;

  int get paymentCount => payments.length;

  DateTime get nextPaymentDate {
    final now = DateTime.now();
    // Clamp paymentDay to valid range for the month
    int clampedDay(int year, int month) {
      final lastDay = DateTime(year, month + 1, 0).day;
      return paymentDay > lastDay ? lastDay : paymentDay;
    }
    var nextDate = DateTime(now.year, now.month, clampedDay(now.year, now.month));
    if (now.day > paymentDay) {
      final nextMonth = now.month + 1;
      final nextYear = nextMonth > 12 ? now.year + 1 : now.year;
      final actualMonth = nextMonth > 12 ? nextMonth - 12 : nextMonth;
      nextDate = DateTime(nextYear, actualMonth, clampedDay(nextYear, actualMonth));
    }
    return nextDate;
  }

  int get daysUntilPayment {
    final now = DateTime.now();
    final next = nextPaymentDate;
    return next.difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  bool get isPaymentDueToday => daysUntilPayment == 0;
  bool get isPaymentDueSoon => daysUntilPayment <= 3 && daysUntilPayment >= 0;

  Loan addPayment(Payment payment) {
    return copyWith(payments: [...payments, payment]);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'totalAmount': totalAmount,
      'interestRate': interestRate,
      'termMonths': termMonths,
      'paymentDay': paymentDay,
      'createdAt': createdAt.toIso8601String(),
      'iconId': iconId,
      'payments': payments.map((p) => p.toJson()).toList(),
    };
  }

  factory Loan.fromJson(Map<String, dynamic> json) {
    return Loan(
      id: json['id'] as String,
      name: json['name'] as String,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      interestRate: (json['interestRate'] as num?)?.toDouble() ?? 0.0,
      termMonths: (json['termMonths'] as num?)?.toInt() ?? 12,
      paymentDay: json['paymentDay'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      iconId: json['iconId'] as String? ?? 'default',
      payments:
          (json['payments'] as List<dynamic>?)
              ?.map((p) => Payment.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Helper class for payoff simulations
class PayoffSimulation {
  final double totalInterest;
  final int monthsToPayoff;
  final double totalCost;

  PayoffSimulation({
    required this.totalInterest,
    required this.monthsToPayoff,
    required this.totalCost,
  });
}

extension LoanSimulation on Loan {
  PayoffSimulation simulatePayoff({double extraMonthlyPayment = 0}) {
    double currentBalance = remainingDebt;
    final r = interestRate / 100 / 12;
    double interestSum = 0;
    int months = 0;

    // Safety break at 600 months (50 years)
    while (currentBalance > 0.1 && months < 600) {
      final interestPayment = currentBalance * r;
      double totalMonthly = monthlyRequired + extraMonthlyPayment;
      
      if (totalMonthly > currentBalance + interestPayment) {
        totalMonthly = currentBalance + interestPayment;
      }

      final principalPayment = totalMonthly - interestPayment;
      
      interestSum += interestPayment;
      currentBalance -= principalPayment;
      months++;
    }

    return PayoffSimulation(
      totalInterest: interestSum,
      monthsToPayoff: months,
      totalCost: totalAmount + interestSum,
    );
  }
}
