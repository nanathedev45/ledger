// lib/reports/reports.dart
//
// Pure reporting functions over List<MoneyTransaction>.
// No Flutter imports — testable in isolation.
//
// Semantics:
//   - Daily: one calendar day, 00:00:00 .. 23:59:59
//   - Weekly: Monday .. Sunday (ISO week)
//   - Monthly: 1st .. last day of month
//
// Scope filters (weekly/monthly only):
//   - ReportScope.all          → every day in window (7 / 28-31)
//   - ReportScope.weekdaysOnly → only Mon..Fri
//   - ReportScope.weekendsOnly → only Sat, Sun

import '../models/transaction.dart';

/// Which days of the window to include in a weekly or monthly report.
enum ReportScope { all, weekdaysOnly, weekendsOnly }

/// Aggregate view of one calendar day.
class DailySummary {
  final DateTime date;
  final double income;
  final double expense;
  final int transactionCount;

  const DailySummary({
    required this.date,
    required this.income,
    required this.expense,
    required this.transactionCount,
  });

  double get net => income - expense;
}

/// One day's bucket inside a weekly or monthly report.
class DayBucket {
  final DateTime date;
  final double income;
  final double expense;

  const DayBucket({
    required this.date,
    required this.income,
    required this.expense,
  });

  double get net => income - expense;
}

/// Weekly report. `days` contains only the days matching `scope`.
class WeeklyReport {
  final DateTime weekStart;
  final ReportScope scope;
  final double totalIncome;
  final double totalExpense;
  final List<DayBucket> days;

  const WeeklyReport({
    required this.weekStart,
    required this.scope,
    required this.totalIncome,
    required this.totalExpense,
    required this.days,
  });

  double get net => totalIncome - totalExpense;
}

/// Monthly report. `days` contains only the days matching `scope`.
class MonthlyReport {
  final int year;
  final int month;
  final ReportScope scope;
  final double totalIncome;
  final double totalExpense;
  final List<DayBucket> days;

  const MonthlyReport({
    required this.year,
    required this.month,
    required this.scope,
    required this.totalIncome,
    required this.totalExpense,
    required this.days,
  });

  double get net => totalIncome - totalExpense;
}

// ── helpers ─────────────────────────────────────────────────────────────

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool _isWeekend(DateTime d) => d.weekday == DateTime.saturday ||
    d.weekday == DateTime.sunday;

bool _matchesScope(DateTime d, ReportScope scope) {
  switch (scope) {
    case ReportScope.all:
      return true;
    case ReportScope.weekdaysOnly:
      return !_isWeekend(d);
    case ReportScope.weekendsOnly:
      return _isWeekend(d);
  }
}

// ── public API ──────────────────────────────────────────────────────────

DailySummary getDailySummary(
    List<MoneyTransaction> transactions,
    DateTime date,
    ) {
  var income = 0.0;
  var expense = 0.0;
  var count = 0;

  for (final t in transactions) {
    if (!_sameDay(t.dateTime, date)) continue;
    count++;
    if (t.isIncome) {
      income += t.amount;
    } else {
      expense += t.amount;
    }
  }

  return DailySummary(
    date: _dateOnly(date),
    income: income,
    expense: expense,
    transactionCount: count,
  );
}

WeeklyReport getWeeklyReport(
    List<MoneyTransaction> transactions,
    DateTime weekStart, {
      ReportScope scope = ReportScope.all,
    }) {
  final start = _dateOnly(weekStart);
  final days = <DayBucket>[];
  var totalIncome = 0.0;
  var totalExpense = 0.0;

  for (var i = 0; i < 7; i++) {
    final day = start.add(Duration(days: i));
    if (!_matchesScope(day, scope)) continue;

    final s = getDailySummary(transactions, day);
    days.add(DayBucket(date: day, income: s.income, expense: s.expense));
    totalIncome += s.income;
    totalExpense += s.expense;
  }

  return WeeklyReport(
    weekStart: start,
    scope: scope,
    totalIncome: totalIncome,
    totalExpense: totalExpense,
    days: days,
  );
}

MonthlyReport getMonthlyReport(
    List<MoneyTransaction> transactions,
    int year,
    int month, {
      ReportScope scope = ReportScope.all,
    }) {
  // Last day of month via Dart's month-overflow normalization.
  final daysInMonth = DateTime(year, month + 1, 0).day;
  final days = <DayBucket>[];
  var totalIncome = 0.0;
  var totalExpense = 0.0;

  for (var d = 1; d <= daysInMonth; d++) {
    final day = DateTime(year, month, d);
    if (!_matchesScope(day, scope)) continue;

    final s = getDailySummary(transactions, day);
    days.add(DayBucket(date: day, income: s.income, expense: s.expense));
    totalIncome += s.income;
    totalExpense += s.expense;
  }

  return MonthlyReport(
    year: year,
    month: month,
    scope: scope,
    totalIncome: totalIncome,
    totalExpense: totalExpense,
    days: days,
  );
}