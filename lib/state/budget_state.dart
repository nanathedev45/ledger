// lib/state/budget_state.dart
//
// Per-category budget limits. In-memory only for now — persistence comes
// when shared_preferences is available. Same shape as LedgerState will be:
// call load() at startup, save() on every mutation.

import 'package:flutter/foundation.dart';

class BudgetState extends ChangeNotifier {
  // categoryId -> monthly limit
  final Map<String, double> _limits = {};

  Map<String, double> get limits => Map.unmodifiable(_limits);

  double? limitFor(String categoryId) => _limits[categoryId];

  void setLimit(String categoryId, double amount) {
    if (amount <= 0) {
      _limits.remove(categoryId);
    } else {
      _limits[categoryId] = amount;
    }
    notifyListeners();
  }

  void clearLimit(String categoryId) {
    if (_limits.remove(categoryId) != null) notifyListeners();
  }

  void clearAll() {
    if (_limits.isEmpty) return;
    _limits.clear();
    notifyListeners();
  }
}