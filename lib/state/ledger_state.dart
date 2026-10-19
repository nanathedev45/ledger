// lib/state/ledger_state.dart
//
// Single source of truth for the app's transaction list and derived balance.

import 'package:flutter/foundation.dart';

import '../models/transaction.dart';

class LedgerState extends ChangeNotifier {
  final List<MoneyTransaction> _transactions = [];

  List<MoneyTransaction> get transactions =>
      List.unmodifiable(_transactions);

  double get balance =>
      _transactions.fold(0.0, (sum, t) => sum + (t.isIncome ? t.amount : -t.amount));

  void addTransaction(
      TransactionType type,
      double amount, {
        String? source,
      }) {
    _transactions.add(
      MoneyTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: type,
        amount: amount,
        dateTime: DateTime.now(),
        source: (source == null || source.trim().isEmpty)
            ? null
            : source.trim(),
      ),
    );
    notifyListeners();
  }

  void clearAll() {
    if (_transactions.isEmpty) return;
    _transactions.clear();
    notifyListeners();
  }
}