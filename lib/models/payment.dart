/// Represents a single payment made towards a loan
class Payment {
  final String id;
  final double amount;
  final DateTime date;
  final String? note;

  Payment({
    required this.id,
    required this.amount,
    required this.date,
    this.note,
  });

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  /// Create from JSON map
  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String?,
    );
  }

  /// Create a new payment with current timestamp
  factory Payment.create({required double amount, String? note}) {
    return Payment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: amount,
      date: DateTime.now(),
      note: note,
    );
  }
}
