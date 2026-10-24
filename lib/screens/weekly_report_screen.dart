// lib/screens/weekly_report_screen.dart

import 'package:flutter/material.dart';

import '../navigation/screen_id.dart';
import '../reports/reports.dart';
import '../reports/savings.dart';
import '../state/budget_state.dart';
import '../state/ledger_state.dart';
import '../utils/currency_format.dart';
import '../widgets/ledger_drawer.dart';
import '../widgets/simple_bar_chart.dart';

class WeeklyReportScreen extends StatefulWidget {
  final LedgerState ledger;
  final BudgetState budget;
  final SavingsGoal savings;

  const WeeklyReportScreen({
    Key? key,
    required this.ledger,
    required this.budget,
    required this.savings,
  }) : super(key: key);

  @override
  State<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends State<WeeklyReportScreen> {
  ReportScope _scope = ReportScope.all;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: LedgerDrawer(
        current: ScreenId.weeklyReport,
        ledger: widget.ledger,
        budget: widget.budget,
        savings: widget.savings,
      ),
      appBar: AppBar(
        title: const Text('Weekly Report'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: AnimatedBuilder(
        animation: widget.ledger,
        builder: (context, _) {
          final today = DateTime.now();
          final weekStart = DateTime(today.year, today.month, today.day)
              .subtract(Duration(days: today.weekday - 1));

          final report = getWeeklyReport(
            widget.ledger.transactions,
            weekStart,
            scope: _scope,
          );

          final bars = report.days
              .map((d) => BarDatum(
            label: _dayLabel(d.date),
            value: d.net.abs(),
          ))
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _scopeChips(),
              const SizedBox(height: 16),
              _SummaryCard(
                title: _titleForScope(),
                income: report.totalIncome,
                expense: report.totalExpense,
                net: report.net,
              ),
              const SizedBox(height: 24),
              Text(
                'Net activity — ${_titleForScope().toLowerCase()}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              SimpleBarChart(data: bars),
              const SizedBox(height: 8),
              Text(
                '${report.days.length} day(s) included',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _scopeChips() {
    return Wrap(
      spacing: 8,
      children: [
        ChoiceChip(
          label: const Text('Full week'),
          selected: _scope == ReportScope.all,
          onSelected: (_) => setState(() => _scope = ReportScope.all),
        ),
        ChoiceChip(
          label: const Text('Weekdays'),
          selected: _scope == ReportScope.weekdaysOnly,
          onSelected: (_) =>
              setState(() => _scope = ReportScope.weekdaysOnly),
        ),
        ChoiceChip(
          label: const Text('Weekends'),
          selected: _scope == ReportScope.weekendsOnly,
          onSelected: (_) =>
              setState(() => _scope = ReportScope.weekendsOnly),
        ),
      ],
    );
  }

  String _titleForScope() {
    switch (_scope) {
      case ReportScope.all:
        return 'This week';
      case ReportScope.weekdaysOnly:
        return 'This week (weekdays)';
      case ReportScope.weekendsOnly:
        return 'This week (weekends)';
    }
  }

  String _dayLabel(DateTime d) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[d.weekday - 1];
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double income;
  final double expense;
  final double net;

  const _SummaryCard({
    required this.title,
    required this.income,
    required this.expense,
    required this.net,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            _row('Income', income, Colors.green),
            _row('Expense', expense, Colors.red),
            const Divider(),
            _row('Net', net, net >= 0 ? Colors.green : Colors.red,
                bold: true),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, double value, Color color, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            'GH₵ ${formatAmount(value)}',
            style: TextStyle(
              color: color,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}