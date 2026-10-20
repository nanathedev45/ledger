// lib/screens/budget_screen.dart

import 'package:flutter/material.dart';

import '../navigation/screen_id.dart';
import '../state/ledger_state.dart';
import '../widgets/ledger_drawer.dart';

class BudgetScreen extends StatelessWidget {
  final LedgerState ledger;

  const BudgetScreen({Key? key, required this.ledger}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: LedgerDrawer(current: ScreenId.budget, ledger: ledger),
      appBar: AppBar(
        title: const Text('Budget'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.pie_chart_outline, size: 64, color: Colors.grey),
              SizedBox(height: 12),
              Text(
                'Budget',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                'Coming soon — monthly category budgets.',
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