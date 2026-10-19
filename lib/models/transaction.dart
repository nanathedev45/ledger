// lib/models/transaction.dart
//
// Immutable data shape for one money movement.

enum TransactionType { income, expense }

class MoneyTransaction {
  final String id;           // ms-timestamp string
  final TransactionType type;
  final double amount;
  final DateTime dateTime;
  final String? source;      // "where from" (income) or "why" (expense)

  const MoneyTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.dateTime,
    this.source,
  });

  bool get isIncome => type == TransactionType.income;
}