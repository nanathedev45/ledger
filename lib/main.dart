// main.dart
import 'package:flutter/material.dart';
import 'app.dart';
import 'state/ledger_state.dart';

void main() {
  final ledger = LedgerState();
  runApp(LedgerApp(ledger: ledger));
}