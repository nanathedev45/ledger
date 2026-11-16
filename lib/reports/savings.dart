// lib/reports/savings.dart
//
// Savings goal state backed by the local SQLite database.

import 'package:flutter/foundation.dart';
import '../models/savings_contribution.dart';
import '../storage/ledger_database.dart';

export '../models/savings_contribution.dart';

class SavingsGoal extends ChangeNotifier {
  SavingsGoal(this._database);

  final LedgerDatabase _database;
  double _monthlyTarget = 0.0;
  final List<SavingsContribution> _contributions = [];

  Future<void> load() async {
    _monthlyTarget = await _database.loadMonthlyTarget();
    _contributions
      ..clear()
      ..addAll(await _database.loadContributions());
    notifyListeners();
  }

  double get monthlyTarget => _monthlyTarget;
  List<SavingsContribution> get contributions =>
      List.unmodifiable(_contributions);

  Future<void> setMonthlyTarget(double amount) async {
    final target = amount < 0 ? 0.0 : amount;
    await _database.saveMonthlyTarget(target);
    _monthlyTarget = target;
    notifyListeners();
  }

  Future<void> addContribution(double amount,
      {DateTime? at, String? note}) async {
    if (amount <= 0) return;
    final contribution = SavingsContribution(
      amount: amount,
      dateTime: at ?? DateTime.now(),
      note: note,
    );
    final id = await _database.saveContribution(contribution);
    _contributions.add(SavingsContribution(
      id: id,
      amount: contribution.amount,
      dateTime: contribution.dateTime,
      note: contribution.note,
    ));
    notifyListeners();
  }

  Future<void> removeContribution(int index) async {
    if (index < 0 || index >= _contributions.length) return;
    final id = _contributions[index].id;
    if (id != null) await _database.removeContribution(id);
    _contributions.removeAt(index);
    notifyListeners();
  }

  Future<void> clearAll() async {
    await _database.clearSavings();
    _contributions.clear();
    _monthlyTarget = 0;
    notifyListeners();
  }

  /// Total saved across all time.
  double get totalSaved => _contributions.fold(0.0, (sum, c) => sum + c.amount);

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
    return (savedThisMonth / _monthlyTarget).clamp(0.0, 1.0).toDouble();
  }
}
