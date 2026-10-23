// lib/screens/monthly_report_screen.dart

import 'package:flutter/material.dart';

import '../navigation/screen_id.dart';
import '../reports/reports.dart';
import '../state/ledger_state.dart';
import '../utils/currency_format.dart';
import '../widgets/ledger_drawer.dart';
import '../widgets/simple_bar_chart.dart';

class MonthlyReportScreen extends StatefulWidget {
  final LedgerState ledger;

  const MonthlyReportScreen({Key? key, required this.ledger})
      : super(key: key);

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  ReportScope _scope = ReportScope.all;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: LedgerDrawer(
        current: ScreenId.monthlyReport,
        ledger: widget.ledger,
      ),
      appBar: AppBar(
        title: const Text('Monthly Report'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: AnimatedBuilder(
        animation: widget.ledger,
        builder: (context, _) {
          final today = DateTime.now();
          final report = getMonthlyReport(
            widget.ledger.transactions,
            today.year,
            today.month,
            scope: _scope,
          );

          final bars = report.days
              .asMap()
              .entries
              .map((e) => BarDatum(
            label: (e.key % 5 == 0 ||
                e.key == report.days.length - 1)
                ? '${e.value.date.day}'
                : '',
            value: e.value.net.abs(),
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
                'Net activity — $_titleForScope().toLowerCase()',
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
          label: const Text('Full month'),
          selected: _scope == ReportScope.all,
          onSelected: (_) => setState(() => _scope = ReportScope.all),
        ),
        ChoiceChip(
          label: const Text('Weekdays'),
          selected: _scope == ReportScope.weekdaysOnly,
          onSelected: (_) => setState(() => _scope = ReportScope.weekdaysOnly),
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
        return 'This month';
      case ReportScope.weekdaysOnly:
        return 'This month (weekdays)';
      case ReportScope.weekendsOnly:
        return 'This month (weekends)';
    }
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
            Text(title,
                style:
                const TextStyle(fontSize: 16, color: Colors.grey)),
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