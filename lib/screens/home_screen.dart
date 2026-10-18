// lib/screens/home_screen.dart
//
// Balance + Add/Deduct buttons + transaction history list.
// Rebuilds on LedgerState changes via AnimatedBuilder.

import 'package:flutter/material.dart';

import '../models/transaction.dart';
import '../state/ledger_state.dart';
import '../widgets/balance_card.dart';
import '../widgets/transaction_buttons.dart';
import '../widgets/transaction_tile.dart';

class HomeScreen extends StatelessWidget {
  final LedgerState ledger;

  const HomeScreen({Key? key, required this.ledger}) : super(key: key);

  Future<void> _promptAmount(
      BuildContext context,
      TransactionType type,
      ) async {
    final result = await showDialog<double>(
      context: context,
      builder: (_) => _AmountDialog(type: type),
    );
    if (result != null) {
      ledger.addTransaction(type, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ledger')),
      body: AnimatedBuilder(
        animation: ledger,
        builder: (context, _) {
          // Newest first.
          final items = ledger.transactions.reversed.toList(growable: false);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: BalanceCard(balance: ledger.balance),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TransactionButtons(
                  onAdd: () =>
                      _promptAmount(context, TransactionType.income),
                  onDeduct: () =>
                      _promptAmount(context, TransactionType.expense),
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              Expanded(
                child: items.isEmpty
                    ? const Center(
                  child: Text(
                    'No transactions yet.\nTap Add or Deduct to begin.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final t = items[i];
                    return TransactionTile(
                      key: ValueKey(t.id),
                      transaction: t,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Owns its own TextEditingController so the controller's lifetime matches
/// the dialog's lifetime. Disposing in `dispose()` guarantees it stays alive
/// through the dialog's exit animation.
class _AmountDialog extends StatefulWidget {
  final TransactionType type;

  const _AmountDialog({required this.type});

  @override
  State<_AmountDialog> createState() => _AmountDialogState();
}

class _AmountDialogState extends State<_AmountDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    final parsed = double.tryParse(_controller.text.trim());
    if (parsed == null || parsed <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a positive amount')),
      );
      return;
    }
    Navigator.of(context).pop(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = widget.type == TransactionType.income;
    final label = isIncome ? 'Add money' : 'Deduct money';
    final color = isIncome ? Colors.green : Colors.red;

    return AlertDialog(
      title: Text(label),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          prefixText: 'GH₵ ',
          hintText: '0.00',
        ),
        onSubmitted: (_) => _confirm(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _confirm,
          child: Text('Confirm', style: TextStyle(color: color)),
        ),
      ],
    );
  }
}