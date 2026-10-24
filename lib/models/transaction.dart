// lib/models/transaction.dart
//
// Immutable data shape for one money movement.
// JSON round-trippable so a future persistence layer can serialize directly.

enum TransactionType { income, expense }

class MoneyTransaction {
  final String id;
  final TransactionType type;
  final double amount;
  final DateTime dateTime;
  final String? source;
  final String? categoryId; // preset category id from lib/models/category.dart

  const MoneyTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.dateTime,
    this.source,
    this.categoryId,
  });

  bool get isIncome => type == TransactionType.income;

  MoneyTransaction copyWith({
    String? id,
    TransactionType? type,
    double? amount,
    DateTime? dateTime,
    String? source,
    String? categoryId,
  }) {
    return MoneyTransaction(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      dateTime: dateTime ?? this.dateTime,
      source: source ?? this.source,
      categoryId: categoryId ?? this.categoryId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'amount': amount,
    'dateTime': dateTime.toIso8601String(),
    'source': source,
    'categoryId': categoryId,
  };

  factory MoneyTransaction.fromJson(Map<String, dynamic> json) {
    return MoneyTransaction(
      id: json['id'] as String,
      type: TransactionType.values.byName(json['type'] as String),
      amount: (json['amount'] as num).toDouble(),
      dateTime: DateTime.parse(json['dateTime'] as String),
      source: json['source'] as String?,
      categoryId: json['categoryId'] as String?,
    );
  }
}