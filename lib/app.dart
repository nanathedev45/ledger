// lib/app.dart

import 'package:flutter/material.dart';

import 'reports/savings.dart';
import 'screens/home_screen.dart';
import 'state/budget_state.dart';
import 'state/ledger_state.dart';

class LedgerApp extends StatelessWidget {
  final LedgerState ledger;
  final BudgetState budget;
  final SavingsGoal savings;

  const LedgerApp({
    Key? key,
    required this.ledger,
    required this.budget,
    required this.savings,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ledger',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.teal, useMaterial3: true),
      home: HomeScreen(ledger: ledger, budget: budget, savings: savings),
    );
  }
}