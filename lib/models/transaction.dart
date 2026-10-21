// lib/models/transaction.dart
//
// Immutable data shape for one money movement. JSON round-trippable so
// LedgerState can persist it via shared_preferences.

enum TransactionType { income, expense }

class MoneyTransaction {
  final String id;
  final TransactionType type;
  final double amount;
  final DateTime dateTime;
  final String? source;

  const MoneyTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.dateTime,
    this.source,
  });

  bool get isIncome => type == TransactionType.income;

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,              // 'income' | 'expense'
    'amount': amount,
    'dateTime': dateTime.toIso8601String(),
    'source': source,
  };

  factory MoneyTransaction.fromJson(Map<String, dynamic> json) {
    return MoneyTransaction(
      id: json['id'] as String,
      type: TransactionType.values.byName(json['type'] as String),
      amount: (json['amount'] as num).toDouble(),
      dateTime: DateTime.parse(json['dateTime'] as String),
      source: json['source'] as String?,
    );
  }
}