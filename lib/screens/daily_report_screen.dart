// lib/screens/daily_report_screen.dart

import 'package:flutter/material.dart';

import '../navigation/screen_id.dart';
import '../state/ledger_state.dart';
import '../widgets/ledger_drawer.dart';

class DailyReportScreen extends StatelessWidget {
  final LedgerState ledger;

  const DailyReportScreen({Key? key, required this.ledger}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: LedgerDrawer(current: ScreenId.dailyReport, ledger: ledger),
      appBar: AppBar(
        title: const Text('Daily Report'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.today_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 12),
              Text(
                'Daily Report',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                'Coming soon — daily inflows and outflows with a chart.',
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