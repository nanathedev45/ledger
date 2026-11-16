// lib/main.dart

import 'package:flutter/material.dart';

import 'app.dart';
import 'reports/savings.dart';
import 'state/budget_state.dart';
import 'state/ledger_state.dart';
import 'storage/ledger_database.dart';
import 'storage/database_factory_stub.dart'
    if (dart.library.io) 'storage/database_factory_io.dart'
    if (dart.library.html) 'storage/database_factory_web.dart' as platform_db;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await platform_db.configureDatabaseFactory();
  final database = await LedgerDatabase.open();
  final ledger = LedgerState(database);
  final budget = BudgetState(database);
  final savings = SavingsGoal(database);
  await Future.wait([ledger.load(), budget.load(), savings.load()]);
  runApp(LedgerApp(
    ledger: ledger,
    budget: budget,
    savings: savings,
  ));
}
