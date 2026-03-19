class AmortizationEntry {
  final int monthIndex;
  final DateTime date;
  final double payment;
  final double principal;
  final double interest;
  final double remainingBalance;
  final bool isPaid;

  const AmortizationEntry({
    required this.monthIndex,
    required this.date,
    required this.payment,
    required this.principal,
    required this.interest,
    required this.remainingBalance,
    this.isPaid = false,
  });
}
