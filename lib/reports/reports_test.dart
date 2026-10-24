// test/reports/reports_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/models/transaction.dart';
import 'package:ledger/reports/reports.dart';

MoneyTransaction _tx({
  required TransactionType type,
  required double amount,
  required DateTime at,
  String? source,
  String? categoryId,
}) {
  return MoneyTransaction(
    id: at.millisecondsSinceEpoch.toString() + amount.toString(),
    type: type,
    amount: amount,
    dateTime: at,
    source: source,
    categoryId: categoryId,
  );
}

void main() {
  group('getDailySummary', () {
    test('empty list → zeroed summary', () {
      final s = getDailySummary([], DateTime(2024, 6, 15));
      expect(s.income, 0.0);
      expect(s.expense, 0.0);
      expect(s.transactionCount, 0);
    });

    test('ignores transactions on other days', () {
      final txs = [
        _tx(type: TransactionType.income, amount: 100,
            at: DateTime(2024, 6, 15, 9)),
        _tx(type: TransactionType.expense, amount: 20,
            at: DateTime(2024, 6, 14, 9)),
      ];
      final s = getDailySummary(txs, DateTime(2024, 6, 15));
      expect(s.income, 100.0);
      expect(s.expense, 0.0);
      expect(s.transactionCount, 1);
    });
  });

  group('getWeeklyReport — scope', () {
    final monday = DateTime(2024, 6, 10); // Mon 2024-06-10 .. Sun 06-16

    test('all → 7 days', () {
      final r = getWeeklyReport([], monday);
      expect(r.days.length, 7);
      expect(r.days.first.date.weekday, DateTime.monday);
      expect(r.days.last.date.weekday, DateTime.sunday);
    });

    test('weekdaysOnly → 5 days, Mon..Fri', () {
      final r = getWeeklyReport([], monday, scope: ReportScope.weekdaysOnly);
      expect(r.days.length, 5);
      expect(r.days.first.date.weekday, DateTime.monday);
      expect(r.days.last.date.weekday, DateTime.friday);
    });

    test('weekendsOnly → 2 days, Sat/Sun', () {
      final r = getWeeklyReport([], monday, scope: ReportScope.weekendsOnly);
      expect(r.days.length, 2);
      expect(r.days.first.date.weekday, DateTime.saturday);
      expect(r.days.last.date.weekday, DateTime.sunday);
    });

    test('scope filters totals, not just buckets', () {
      final txs = [
        _tx(type: TransactionType.income, amount: 100,
            at: DateTime(2024, 6, 12, 9)), // Wed
        _tx(type: TransactionType.expense, amount: 30,
            at: DateTime(2024, 6, 15, 9)), // Sat
      ];

      final all = getWeeklyReport(txs, monday);
      expect(all.totalIncome, 100.0);
      expect(all.totalExpense, 30.0);

      final weekdays =
      getWeeklyReport(txs, monday, scope: ReportScope.weekdaysOnly);
      expect(weekdays.totalIncome, 100.0);
      expect(weekdays.totalExpense, 0.0);

      final weekends =
      getWeeklyReport(txs, monday, scope: ReportScope.weekendsOnly);
      expect(weekends.totalIncome, 0.0);
      expect(weekends.totalExpense, 30.0);
    });
  });

  group('getMonthlyReport — scope', () {
    test('June 2024: all=30, weekdays=20, weekends=10', () {
      expect(getMonthlyReport([], 2024, 6).days.length, 30);
      expect(
        getMonthlyReport([], 2024, 6, scope: ReportScope.weekendsOnly)
            .days
            .length,
        10,
      );
      expect(
        getMonthlyReport([], 2024, 6, scope: ReportScope.weekdaysOnly)
            .days
            .length,
        20,
      );
    });

    test('Feb 2024 (leap): all=29, weekends=8, weekdays=21', () {
      expect(getMonthlyReport([], 2024, 2).days.length, 29);
      expect(
        getMonthlyReport([], 2024, 2, scope: ReportScope.weekendsOnly)
            .days
            .length,
        8,
      );
      expect(
        getMonthlyReport([], 2024, 2, scope: ReportScope.weekdaysOnly)
            .days
            .length,
        21,
      );
    });
  });

  group('getCategoryBreakdown', () {
    test('empty → empty list', () {
      expect(
        getCategoryBreakdown([], DateTime(2024, 6, 1), DateTime(2024, 6, 30)),
        isEmpty,
      );
    });

    test('aggregates by category, uncategorized sorts last', () {
      final txs = [
        _tx(type: TransactionType.income, amount: 100,
            at: DateTime(2024, 6, 5), categoryId: 'salary'),
        _tx(type: TransactionType.expense, amount: 30,
            at: DateTime(2024, 6, 10), categoryId: 'food'),
        _tx(type: TransactionType.expense, amount: 20,
            at: DateTime(2024, 6, 12), categoryId: 'food'),
        _tx(type: TransactionType.expense, amount: 5,
            at: DateTime(2024, 6, 14), categoryId: null),
      ];

      final b = getCategoryBreakdown(
          txs, DateTime(2024, 6, 1), DateTime(2024, 6, 30));

      expect(b.length, 3);

      // First: income category
      expect(b[0].categoryId, 'salary');
      expect(b[0].income, 100.0);

      // Second: expense category (food, more spend)
      expect(b[1].categoryId, 'food');
      expect(b[1].expense, 50.0);

      // Third: uncategorized, sorted last
      expect(b[2].categoryId, null);
      expect(b[2].expense, 5.0);
    });

    test('out-of-window transactions excluded', () {
      final txs = [
        _tx(type: TransactionType.expense, amount: 10,
            at: DateTime(2024, 5, 31), categoryId: 'food'),
        _tx(type: TransactionType.expense, amount: 20,
            at: DateTime(2024, 6, 15), categoryId: 'food'),
        _tx(type: TransactionType.expense, amount: 30,
            at: DateTime(2024, 7, 1), categoryId: 'food'),
      ];
      final b = getCategoryBreakdown(
          txs, DateTime(2024, 6, 1), DateTime(2024, 6, 30));
      expect(b.length, 1);
      expect(b.first.expense, 20.0);
    });
  });
}