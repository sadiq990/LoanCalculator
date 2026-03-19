import 'package:decimal/decimal.dart';
import 'package:rational/rational.dart';
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
  final String iconId;
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
    // Calculate standard monthly payment using Decimal for precision
    final dAmount = Decimal.parse(totalAmount.toString());
    final dRate = Decimal.parse(interestRate.toString());
    final dTerm = Decimal.fromInt(termMonths);

    if (interestRate <= 0) {
      // Branch for zero interest
      monthlyRequired = (dAmount / dTerm).toDouble();
    } else {
      final r = (dRate / (Decimal.fromInt(100) * Decimal.fromInt(12))).toDouble();
      final n = termMonths;
      final factor = math.pow(1 + r, n).toDouble();
      monthlyRequired = (totalAmount * r * factor / (factor - 1));
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
    final dTotalValue = Decimal.parse(totalContractValue.toStringAsFixed(10));
    final dTotalPaid = Decimal.parse(totalPaid.toStringAsFixed(10));
    final val = (dTotalValue - dTotalPaid).toDouble();
    return val < 0 ? 0 : val;
  }

  /// Current Principal Balance (approximate for typical scenarios)
  double get remainingDebt {
    Decimal balance = Decimal.parse(totalAmount.toString());
    final sortedPayments = List<Payment>.from(payments)
      ..sort((a, b) => a.date.compareTo(b.date));

    DateTime lastDate = createdAt;
    DateTime now = DateTime.now();

    final dRate = Decimal.parse(interestRate.toString());
    final d365 = Decimal.fromInt(365);
    final d100 = Decimal.fromInt(100);

    for (var payment in sortedPayments) {
      if (balance <= Decimal.zero) break;

      int days = payment.date.difference(lastDate).inDays;
      if (days < 0) days = 0;

      if (interestRate > 0) {
        final dailyRate = dRate / (d100 * d365);
        final interest = (dailyRate * balance.toRational() * Rational.fromInt(days)).toDecimal(scaleOnInfinitePrecision: 10);
        balance += interest;
      }
      
      balance -= Decimal.parse(payment.amount.toString());
      lastDate = payment.date;
    }

    if (balance > Decimal.zero && interestRate > 0) {
      int days = now.difference(lastDate).inDays;
      if (days > 0) {
        final dailyRate = dRate / (d100 * d365);
        final interest = (dailyRate * balance.toRational() * Rational.fromInt(days)).toDecimal(scaleOnInfinitePrecision: 10);
        balance += interest;
      }
    }

    final result = balance.toDouble();
    return result < 0 ? 0 : result;
  }

  double get totalPaid => payments.fold(0.0, (sum, p) => sum + p.amount);

  /// Progress based on Total Repayment (Principal + Interest)
  double get progress {
    if (totalContractValue <= 0) return 0;
    return (Decimal.parse(totalPaid.toStringAsFixed(10)) / Decimal.parse(totalContractValue.toStringAsFixed(10))).toDouble();
  }

  /// Calculate original amortization schedule (combining history + future)
  List<AmortizationEntry> getOriginalAmortizationSchedule({
    double extraMonthlyPayment = 0,
  }) {
    final List<AmortizationEntry> schedule = [];
    Decimal currentBalance = Decimal.parse(totalAmount.toString());
    DateTime currentDate = createdAt;

    if (currentBalance <= Decimal.zero || monthlyRequired <= 0) return [];

    final Rational dMonthlyRate = interestRate <= 0 
      ? Rational.zero 
      : Decimal.parse(interestRate.toString()) / (Decimal.fromInt(100) * Decimal.fromInt(12));
    final dExtra = Decimal.parse(extraMonthlyPayment.toString());

    // Sort actual payments chronologically to map them to specific months.
    final sortedPayments = List<Payment>.from(payments)
      ..sort((a, b) => a.date.compareTo(b.date));

    int month = 1;

    while (currentBalance > Decimal.zero && month <= 360) {
      bool hasActualPayment = (month - 1) < sortedPayments.length;
      Decimal totalPayment;
      Decimal interestPayment;
      bool isMonthPaid = false;

      // Calculate pure interest up to this month
      if (interestRate > 0) {
        interestPayment = (currentBalance.toRational() * dMonthlyRate).toDecimal(scaleOnInfinitePrecision: 10);
      } else {
        interestPayment = Decimal.zero;
      }

      if (hasActualPayment) {
        // Historical Actual Payment
        final actualPmt = sortedPayments[month - 1];
        totalPayment = Decimal.parse(actualPmt.amount.toString());
        isMonthPaid = true;

        if (totalPayment > currentBalance + interestPayment) {
          totalPayment = currentBalance + interestPayment;
        }
      } else {
        // Future Projected Payment
        Decimal requiredPayment = Decimal.parse(monthlyRequired.toString());

        totalPayment = requiredPayment + dExtra;
        if (totalPayment > currentBalance + interestPayment) {
          totalPayment = currentBalance + interestPayment;
        }
      }

      Decimal principalPayment = totalPayment - interestPayment;
      currentBalance -= principalPayment;

      if (currentBalance < Decimal.parse('0.01')) currentBalance = Decimal.zero;

      final nextDate = DateTime(currentDate.year, currentDate.month + month, 1);
      final lastDay = DateTime(nextDate.year, nextDate.month + 1, 0).day;
      final actualDay = paymentDay > lastDay ? lastDay : paymentDay;

      schedule.add(
        AmortizationEntry(
          monthIndex: month,
          date: hasActualPayment ? sortedPayments[month - 1].date : DateTime(nextDate.year, nextDate.month, actualDay),
          payment: totalPayment.toDouble(),
          principal: principalPayment.toDouble(),
          interest: interestPayment.toDouble(),
          remainingBalance: currentBalance.toDouble(),
          isPaid: isMonthPaid,
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
      'payments': payments.map((e) => e.toJson()).toList(),
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
      payments: (json['payments'] as List<dynamic>?)
          ?.map((e) => Payment.fromJson(e as Map<String, dynamic>))
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
