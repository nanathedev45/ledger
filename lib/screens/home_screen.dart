// lib/screens/home_screen.dart
//
// Balance + Add/Deduct buttons + tabbed transaction lists + reset FAB.
// Drawer navigation added. Budget & savings passed through for the drawer.

import 'package:flutter/material.dart';

import '../models/transaction.dart';
import '../navigation/screen_id.dart';
import '../reports/savings.dart';
import '../state/budget_state.dart';
import '../state/ledger_state.dart';
import '../widgets/balance_card.dart';
import '../widgets/ledger_drawer.dart';
import '../widgets/transaction_buttons.dart';
import '../widgets/transaction_tile.dart';

class HomeScreen extends StatelessWidget {
  final LedgerState ledger;
  final BudgetState budget;
  final SavingsGoal savings;

  const HomeScreen({
    Key? key,
    required this.ledger,
    required this.budget,
    required this.savings,
  }) : super(key: key);

  Future<void> _promptAmount(
      BuildContext context,
      TransactionType type,
      ) async {
    final result = await showDialog<_AmountResult>(
      context: context,
      builder: (_) => _AmountDialog(type: type),
    );
    if (result != null) {
      ledger.addTransaction(type, result.amount, source: result.source);
    }
  }

  Future<void> _confirmReset(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Reset everything?'),
          content: const Text(
            'This will delete all transactions and set the balance to zero. '
                'This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text(
                'Reset',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
    if (ok == true) {
      ledger.clearAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: LedgerDrawer(
        current: ScreenId.home,
        ledger: ledger,
        budget: budget,
        savings: savings,
      ),
      appBar: AppBar(
        title: const Text('Ledger'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Reset',
        onPressed: () => _confirmReset(context),
        child: const Icon(Icons.refresh),
      ),
      body: AnimatedBuilder(
        animation: ledger,
        builder: (context, _) {
          final all = ledger.transactions.reversed.toList(growable: false);
          final income =
          all.where((t) => t.isIncome).toList(growable: false);
          final expense =
          all.where((t) => !t.isIncome).toList(growable: false);

          return DefaultTabController(
            length: 3,
            child: Column(
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
                const TabBar(
                  tabs: [
                    Tab(text: 'All'),
                    Tab(text: 'Income'),
                    Tab(text: 'Expenditures'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _TransactionList(
                        items: all,
                        emptyText:
                        'No transactions yet.\nTap Add or Deduct to begin.',
                      ),
                      _TransactionList(
                        items: income,
                        emptyText: 'No additions yet.',
                      ),
                      _TransactionList(
                        items: expense,
                        emptyText: 'No deductions yet.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TransactionList extends StatelessWidget {
  final List<MoneyTransaction> items;
  final String emptyText;

  const _TransactionList({required this.items, required this.emptyText});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            emptyText,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final t = items[i];
        return TransactionTile(key: ValueKey(t.id), transaction: t);
      },
    );
  }
}

class _AmountResult {
  final double amount;
  final String? source;
  const _AmountResult(this.amount, this.source);
}

class _AmountDialog extends StatefulWidget {
  final TransactionType type;

  const _AmountDialog({required this.type});

  @override
  State<_AmountDialog> createState() => _AmountDialogState();
}

class _AmountDialogState extends State<_AmountDialog> {
  final _amountController = TextEditingController();
  final _sourceController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _sourceController.dispose();
    super.dispose();
  }

  void _confirm() {
    final parsed = double.tryParse(_amountController.text.trim());
    if (parsed == null || parsed <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a positive amount')),
      );
      return;
    }
    final source = _sourceController.text.trim();
    Navigator.of(context).pop(
      _AmountResult(parsed, source.isEmpty ? null : source),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = widget.type == TransactionType.income;
    final label = isIncome ? 'Add money' : 'Deduct money';
    final color = isIncome ? Colors.green : Colors.red;
    final sourceLabel = isIncome ? 'Source' : 'Reason';
    final sourceHint = isIncome
        ? 'e.g. allowance, gift, stipend'
        : 'e.g. food, transport, books';

    return AlertDialog(
      title: Text(label),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _amountController,
            autofocus: true,
            keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              prefixText: 'GH₵ ',
              hintText: '0.00',
              labelText: 'Amount',
            ),
            onSubmitted: (_) => _confirm(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _sourceController,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: '$sourceLabel (optional)',
              hintText: sourceHint,
            ),
            onSubmitted: (_) => _confirm(),
          ),
        ],
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