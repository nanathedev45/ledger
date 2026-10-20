// lib/screens/weekly_report_screen.dart

import 'package:flutter/material.dart';

import '../navigation/screen_id.dart';
import '../state/ledger_state.dart';
import '../widgets/ledger_drawer.dart';

class WeeklyReportScreen extends StatelessWidget {
  final LedgerState ledger;

  const WeeklyReportScreen({Key? key, required this.ledger})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: LedgerDrawer(current: ScreenId.weeklyReport, ledger: ledger),
      appBar: AppBar(
        title: const Text('Weekly Report'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.date_range_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 12),
              Text(
                'Weekly Report',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                'Coming soon — weekly totals and comparisons.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}