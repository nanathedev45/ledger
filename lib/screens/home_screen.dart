import 'package:flutter/material.dart';

import '../models/transaction.dart';
import '../state/ledger_state.dart';
import '../widgets/balance_card.dart';
import '../widgets/transaction_buttons.dart';

class HomeScreen extends StatelessWidget {
  final LedgerState ledger;

  const HomeScreen({Key? key, required this.ledger}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ledger,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: const Text('Ledger')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              BalanceCard(balance: ledger.balance),
              const SizedBox(height: 32),
              TransactionButtons(
                onAdd: () => _showAmountDialog(context, TransactionType.income),
                onDeduct: () => _showAmountDialog(context, TransactionType.expense),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAmountDialog(BuildContext context, TransactionType type) {
    final controller = TextEditingController();
    final isIncome = type == TransactionType.income;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isIncome ? 'Add money' : 'Deduct money'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(prefixText: 'GH₵ ', hintText: '0.00'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(controller.text);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter a valid amount')),
                );
                return;
              }
              ledger.addTransaction(type, amount);
              Navigator.pop(dialogContext);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}