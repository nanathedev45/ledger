enum TransactionType { income, expense }

class MoneyTransaction {
  final String id;
  final TransactionType type;
  final double amount;
  final DateTime dateTime;
  final String? note;

  MoneyTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.dateTime,
    this.note,
  });

  bool get isIncome => type == TransactionType.income;
}