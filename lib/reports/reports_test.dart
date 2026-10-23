// test/reports/reports_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/models/transaction.dart';
import 'package:ledger/reports/reports.dart';

MoneyTransaction _tx({
  required TransactionType type,
  required double amount,
  required DateTime at,
  String? source,
}) {
  return MoneyTransaction(
    id: at.millisecondsSinceEpoch.toString() + amount.toString(),
    type: type,
    amount: amount,
    dateTime: at,
    source: source,
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
    // Week of Monday 2024-06-10 → Sunday 2024-06-16
    final monday = DateTime(2024, 6, 10);

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
        // Wed income 100
        _tx(type: TransactionType.income, amount: 100,
            at: DateTime(2024, 6, 12, 9)),
        // Sat expense 30
        _tx(type: TransactionType.expense, amount: 30,
            at: DateTime(2024, 6, 15, 9)),
      ];

      final all = getWeeklyReport(txs, monday);
      expect(all.totalIncome, 100.0);
      expect(all.totalExpense, 30.0);

      final weekdays = getWeeklyReport(txs, monday,
          scope: ReportScope.weekdaysOnly);
      expect(weekdays.totalIncome, 100.0);
      expect(weekdays.totalExpense, 0.0);  // Sat excluded

      final weekends = getWeeklyReport(txs, monday,
          scope: ReportScope.weekendsOnly);
      expect(weekends.totalIncome, 0.0);   // Wed excluded
      expect(weekends.totalExpense, 30.0);
    });
  });

  group('getMonthlyReport — scope', () {
    test('June 2024: all=30, weekdays=20, weekends=10', () {
      final all = getMonthlyReport([], 2024, 6);
      expect(all.days.length, 30);
      // June 2024: Sat/Sun = Jun 1,2,8,9,15,16,22,23,29,30 → 10 weekend days
      final weekends = getMonthlyReport([], 2024, 6,
          scope: ReportScope.weekendsOnly);
      expect(weekends.days.length, 10);
      // 30 - 10 = 20 weekday days
      final weekdays = getMonthlyReport([], 2024, 6,
          scope: ReportScope.weekdaysOnly);
      expect(weekdays.days.length, 20);
    });

    test('Feb 2024 (leap): all=29, weekends=8, weekdays=21', () {
      // Feb 2024 weekends: Feb 3,4,10,11,17,18,24,25 → 8 days
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

    test('scope filters totals within the month only', () {
      final txs = [
        _tx(type: TransactionType.income, amount: 100,
            at: DateTime(2024, 6, 5)),       // Wed, weekday
        _tx(type: TransactionType.expense, amount: 40,
            at: DateTime(2024, 6, 8)),       // Sat, weekend
      ];
      final weekdays = getMonthlyReport(txs, 2024, 6,
          scope: ReportScope.weekdaysOnly);
      expect(weekdays.totalIncome, 100.0);
      expect(weekdays.totalExpense, 0.0);

      final weekends = getMonthlyReport(txs, 2024, 6,
          scope: ReportScope.weekendsOnly);
      expect(weekends.totalIncome, 0.0);
      expect(weekends.totalExpense, 40.0);
    });
  });
}