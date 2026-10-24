// lib/main.dart

import 'package:flutter/material.dart';

import 'app.dart';
import 'reports/savings.dart';
import 'state/budget_state.dart';
import 'state/ledger_state.dart';

void main() {
  runApp(LedgerApp(
    ledger: LedgerState(),
    budget: BudgetState(),
    savings: SavingsGoal(),
  ));
}