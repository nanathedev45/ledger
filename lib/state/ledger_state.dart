// lib/state/ledger_state.dart
//
// Single source of truth for transactions + derived balance.

import 'package:flutter/foundation.dart';

import '../models/transaction.dart';
import '../storage/ledger_database.dart';

class LedgerState extends ChangeNotifier {
  LedgerState(this._database);

  final LedgerDatabase _database;
  final List<MoneyTransaction> _transactions = [];

  Future<void> load() async {
    _transactions
      ..clear()
      ..addAll(await _database.loadTransactions());
    notifyListeners();
  }

  List<MoneyTransaction> get transactions => List.unmodifiable(_transactions);

  double get balance => _transactions.fold(
        0.0,
        (sum, t) => sum + (t.isIncome ? t.amount : -t.amount),
      );

  Future<void> addTransaction(
    TransactionType type,
    double amount, {
    String? source,
    String? categoryId,
  }) async {
    final transaction = MoneyTransaction(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: type,
      amount: amount,
      dateTime: DateTime.now(),
      source: (source == null || source.trim().isEmpty) ? null : source.trim(),
      categoryId: categoryId,
    );
    await _database.saveTransaction(transaction);
    _transactions.add(transaction);
    notifyListeners();
  }

  Future<void> clearAll() async {
    await _database.clearTransactions();
    _transactions.clear();
    notifyListeners();
  }
}
