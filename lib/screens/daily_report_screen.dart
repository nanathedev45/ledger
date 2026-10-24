// lib/screens/daily_report_screen.dart

import 'package:flutter/material.dart';

import '../navigation/screen_id.dart';
import '../reports/reports.dart';
import '../reports/savings.dart';
import '../state/budget_state.dart';
import '../state/ledger_state.dart';
import '../utils/currency_format.dart';
import '../widgets/ledger_drawer.dart';
import '../widgets/simple_bar_chart.dart';

class DailyReportScreen extends StatelessWidget {
  final LedgerState ledger;
  final BudgetState budget;
  final SavingsGoal savings;

  const DailyReportScreen({
    Key? key,
    required this.ledger,
    required this.budget,
    required this.savings,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: LedgerDrawer(
        current: ScreenId.dailyReport,
        ledger: ledger,
        budget: budget,
        savings: savings,
      ),
      appBar: AppBar(
        title: const Text('Daily Report'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: AnimatedBuilder(
        animation: ledger,
        builder: (context, _) {
          final today = DateTime.now();
          final summary = getDailySummary(ledger.transactions, today);

          final last7 = List.generate(7, (i) {
            final d = today.subtract(Duration(days: 6 - i));
            final s = getDailySummary(ledger.transactions, d);
            return BarDatum(label: '${d.day}', value: s.net.abs());
          });

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SummaryCard(
                title: 'Today',
                income: summary.income,
                expense: summary.expense,
                net: summary.net,
              ),
              const SizedBox(height: 24),
              const Text(
                'Net activity — last 7 days',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              SimpleBarChart(data: last7),
              const SizedBox(height: 16),
              Text(
                '${summary.transactionCount} transaction(s) today',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          );
        },
      ),
    );
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