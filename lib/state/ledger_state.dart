import 'package:flutter/foundation.dart';
import '../models/transaction.dart';

class LedgerState extends ChangeNotifier {
  final List<MoneyTransaction> _transactions = [];

  List<MoneyTransaction> get transactions => List.unmodifiable(_transactions);

  double get balance =>
      _transactions.fold(0.0, (sum, t) => sum + (t.isIncome ? t.amount : -t.amount));

  void addTransaction(TransactionType type, double amount, {String? note}) {
    _transactions.add(MoneyTransaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      amount: amount,
      dateTime: DateTime.now(),
      note: note,
    ));
    notifyListeners();
  }
}