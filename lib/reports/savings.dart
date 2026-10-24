// lib/reports/savings.dart
//
// Savings goal logic. In-memory only for now (see budget_state.dart for
// the persistence plan).

import 'package:flutter/foundation.dart';

class SavingsGoal extends ChangeNotifier {
  double _monthlyTarget = 0.0;
  final List<SavingsContribution> _contributions = [];

  double get monthlyTarget => _monthlyTarget;
  List<SavingsContribution> get contributions =>
      List.unmodifiable(_contributions);

  void setMonthlyTarget(double amount) {
    _monthlyTarget = amount < 0 ? 0 : amount;
    notifyListeners();
  }

  void addContribution(double amount, {DateTime? at, String? note}) {
    if (amount <= 0) return;
    _contributions.add(SavingsContribution(
      amount: amount,
      dateTime: at ?? DateTime.now(),
      note: note,
    ));
    notifyListeners();
  }

  void removeContribution(int index) {
    if (index < 0 || index >= _contributions.length) return;
    _contributions.removeAt(index);
    notifyListeners();
  }

  void clearAll() {
    _contributions.clear();
    _monthlyTarget = 0;
    notifyListeners();
  }

  /// Total saved across all time.
  double get totalSaved =>
      _contributions.fold(0.0, (sum, c) => sum + c.amount);

  /// Total saved in a given calendar month.
  double savedInMonth(int year, int month) {
    return _contributions.where((c) {
      return c.dateTime.year == year && c.dateTime.month == month;
    }).fold(0.0, (sum, c) => sum + c.amount);
  }

  /// This month's saved amount.
  double get savedThisMonth {
    final now = DateTime.now();
    return savedInMonth(now.year, now.month);
  }

  /// This month's progress toward monthly target (0..1, capped).
  double get thisMonthProgress {
    if (_monthlyTarget <= 0) return 0.0;
    return (savedThisMonth / _monthlyTarget).clamp(0.0, 1.0);
  }
}

class SavingsContribution {
  final double amount;
  final DateTime dateTime;
  final String? note;

  const SavingsContribution({
    required this.amount,
    required this.dateTime,
    this.note,
  });
}