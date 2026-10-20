// lib/screens/monthly_report_screen.dart

import 'package:flutter/material.dart';

import '../navigation/screen_id.dart';
import '../state/ledger_state.dart';
import '../widgets/ledger_drawer.dart';

class MonthlyReportScreen extends StatelessWidget {
  final LedgerState ledger;

  const MonthlyReportScreen({Key? key, required this.ledger})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: LedgerDrawer(current: ScreenId.monthlyReport, ledger: ledger),
      appBar: AppBar(
        title: const Text('Monthly Report'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.calendar_month_outlined,
                  size: 64, color: Colors.grey),
              SizedBox(height: 12),
              Text(
                'Monthly Report',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                'Coming soon — monthly breakdown and trends.',
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