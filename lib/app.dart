// app.dart
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'state/ledger_state.dart';

class LedgerApp extends StatelessWidget {
  final LedgerState ledger;
  const LedgerApp({Key? key, required this.ledger}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ledger',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.teal, useMaterial3: true),
      home: HomeScreen(ledger: ledger),
    );
  }
}