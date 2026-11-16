// lib/state/budget_state.dart
//
// Per-category monthly budget limits backed by local SQLite storage.

import 'package:flutter/foundation.dart';
import '../storage/ledger_database.dart';

class BudgetState extends ChangeNotifier {
  BudgetState(this._database);

  final LedgerDatabase _database;
  // categoryId -> monthly limit
  final Map<String, double> _limits = {};

  Future<void> load() async {
    _limits
      ..clear()
      ..addAll(await _database.loadBudgets());
    notifyListeners();
  }

  Map<String, double> get limits => Map.unmodifiable(_limits);

  double? limitFor(String categoryId) => _limits[categoryId];

  Future<void> setLimit(String categoryId, double amount) async {
    await _database.saveBudget(categoryId, amount);
    if (amount <= 0) {
      _limits.remove(categoryId);
    } else {
      _limits[categoryId] = amount;
    }
    notifyListeners();
  }

  Future<void> clearLimit(String categoryId) async {
    await _database.saveBudget(categoryId, 0);
    if (_limits.remove(categoryId) != null) notifyListeners();
  }

  Future<void> clearAll() async {
    await _database.clearBudgets();
    _limits.clear();
    notifyListeners();
  }
}
