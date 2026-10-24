// lib/screens/savings_screen.dart

import 'package:flutter/material.dart';

import '../navigation/screen_id.dart';
import '../reports/savings.dart';
import '../state/budget_state.dart';
import '../state/ledger_state.dart';
import '../utils/currency_format.dart';
import '../utils/date_format.dart';
import '../widgets/ledger_drawer.dart';

class SavingsScreen extends StatefulWidget {
  final LedgerState ledger;
  final BudgetState budget;
  final SavingsGoal savings;

  const SavingsScreen({
    Key? key,
    required this.ledger,
    required this.budget,
    required this.savings,
  }) : super(key: key);

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: LedgerDrawer(
        current: ScreenId.savings,
        ledger: widget.ledger,
        budget: widget.budget,
        savings: widget.savings,
      ),
      appBar: AppBar(
        title: const Text('Savings'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Edit monthly target',
            icon: const Icon(Icons.flag_outlined),
            onPressed: _showTargetDialog,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add contribution',
        onPressed: _showAddContributionDialog,
        child: const Icon(Icons.add),
      ),
      body: AnimatedBuilder(
        animation: widget.savings,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ProgressCard(savings: widget.savings),
              const SizedBox(height: 24),
              const Text(
                'Contributions',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              if (widget.savings.contributions.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No contributions yet.\nTap + to log your first saving.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ...widget.savings.contributions
                    .asMap()
                    .entries
                    .toList()
                    .reversed
                    .map((e) => _ContributionTile(
                  contribution: e.value,
                  onDelete: () =>
                      widget.savings.removeContribution(e.key),
                )),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showTargetDialog() async {
    final controller = TextEditingController(
      text: widget.savings.monthlyTarget > 0
          ? widget.savings.monthlyTarget.toStringAsFixed(2)
          : '',
    );

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Monthly savings target'),
        content: TextField(
          controller: controller,
          keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Target',
            prefixText: 'GH₵ ',
            hintText: '0.00',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (!mounted || ok != true) {
      controller.dispose();
      return;
    }

    final parsed = double.tryParse(controller.text.trim());
    controller.dispose();

    if (parsed == null || parsed < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }

    widget.savings.setMonthlyTarget(parsed);
  }

  Future<void> _showAddContributionDialog() async {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add contribution'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: 'GH₵ ',
                hintText: '0.00',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'e.g. end of month transfer',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (!mounted || ok != true) {
      amountCtrl.dispose();
      noteCtrl.dispose();
      return;
    }

    final parsed = double.tryParse(amountCtrl.text.trim());
    final note = noteCtrl.text.trim();
    amountCtrl.dispose();
    noteCtrl.dispose();

    if (parsed == null || parsed <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a positive amount')),
      );
      return;
    }

    widget.savings.addContribution(
      parsed,
      note: note.isEmpty ? null : note,
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final SavingsGoal savings;

  const _ProgressCard({required this.savings});

  @override
  Widget build(BuildContext context) {
    final target = savings.monthlyTarget;
    final saved = savings.savedThisMonth;
    final progress = savings.thisMonthProgress;
    final remaining = (target - saved).clamp(0.0, double.infinity);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'This month',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 140,
              height: 140,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 12,
                      backgroundColor: Colors.blue.withOpacity(0.12),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.blue),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'GH₵ ${formatAmount(saved)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (target > 0) ...[
              Text(
                'Target: GH₵ ${formatAmount(target)}',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                remaining > 0
                    ? 'GH₵ ${formatAmount(remaining)} to go'
                    : 'Target reached',
                style: TextStyle(
                  fontSize: 12,
                  color: remaining > 0
                      ? Colors.grey
                      : Colors.green.shade700,
                  fontWeight: remaining > 0
                      ? FontWeight.normal
                      : FontWeight.w600,
                ),
              ),
            ] else
              const Text(
                'No monthly target set — tap the flag icon to set one.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total saved', style: TextStyle(fontSize: 14)),
                Text(
                  'GH₵ ${formatAmount(savings.totalSaved)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ContributionTile extends StatelessWidget {
  final SavingsContribution contribution;
  final VoidCallback onDelete;

  const _ContributionTile({
    required this.contribution,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0x1F2196F3),
          child: Icon(Icons.savings_outlined, color: Colors.blue, size: 20),
        ),
        title: Text(
          'GH₵ ${formatAmount(contribution.amount)}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          contribution.note != null && contribution.note!.isNotEmpty
              ? '${formatDateTime(contribution.dateTime)}  ·  ${contribution.note}'
              : formatDateTime(contribution.dateTime),
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, size: 20),
          onPressed: onDelete,
          tooltip: 'Remove',
        ),
      ),
    );
  }
}