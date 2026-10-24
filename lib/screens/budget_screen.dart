// lib/screens/budget_screen.dart

import 'package:flutter/material.dart';

import '../models/category.dart';
import '../navigation/screen_id.dart';
import '../reports/reports.dart';
import '../reports/savings.dart';
import '../state/budget_state.dart';
import '../state/ledger_state.dart';
import '../utils/currency_format.dart';
import '../widgets/ledger_drawer.dart';

class BudgetScreen extends StatefulWidget {
  final LedgerState ledger;
  final BudgetState budget;
  final SavingsGoal savings;

  const BudgetScreen({
    Key? key,
    required this.ledger,
    required this.budget,
    required this.savings,
  }) : super(key: key);

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: LedgerDrawer(
        current: ScreenId.budget,
        ledger: widget.ledger,
        budget: widget.budget,
        savings: widget.savings,
      ),
      appBar: AppBar(
        title: const Text('Budget'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add budget',
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([widget.ledger, widget.budget]),
        builder: (context, _) {
          final now = DateTime.now();
          final breakdown = getCategoryBreakdown(
            widget.ledger.transactions,
            DateTime(now.year, now.month, 1),
            DateTime(now.year, now.month, now.day),
          );

          final spentBy = <String, double>{};
          for (final c in breakdown) {
            if (c.categoryId != null && c.expense > 0) {
              spentBy[c.categoryId!] = c.expense;
            }
          }

          final limits = widget.budget.limits;
          if (limits.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No budgets set yet.\nTap + to add a monthly budget for a category.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            );
          }

          final entries = limits.entries.toList()
            ..sort((a, b) => Categories.labelOf(a.key)
                .compareTo(Categories.labelOf(b.key)));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            itemBuilder: (context, i) {
              final id = entries[i].key;
              final limit = entries[i].value;
              final spent = spentBy[id] ?? 0.0;
              final ratio = limit > 0 ? spent / limit : 0.0;
              return _BudgetRow(
                categoryId: id,
                limit: limit,
                spent: spent,
                ratio: ratio,
                onEdit: () => _showEditDialog(id, limit),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showAddDialog() async {
    final used = widget.budget.limits.keys.toSet();
    final available = Categories.expensePresets
        .where((c) => !used.contains(c.id))
        .toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All categories already have budgets')),
      );
      return;
    }

    Category selected = available.first;
    final controller = TextEditingController();

    final result = await showDialog<MapEntry<String, double>?>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            title: const Text('Add budget'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<Category>(
                  value: selected,
                  items: available
                      .map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(c.label),
                  ))
                      .toList(),
                  onChanged: (c) {
                    if (c != null) setLocal(() => selected = c);
                  },
                  decoration:
                  const InputDecoration(labelText: 'Category'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Monthly limit',
                    prefixText: 'GH₵ ',
                    hintText: '0.00',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  final parsed = double.tryParse(controller.text.trim());
                  if (parsed == null || parsed <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Enter a positive amount')),
                    );
                    return;
                  }
                  Navigator.of(ctx).pop(MapEntry(selected.id, parsed));
                },
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );

    controller.dispose();

    if (result != null) {
      widget.budget.setLimit(result.key, result.value);
    }
  }

  Future<void> _showEditDialog(String categoryId, double currentLimit) async {
    final controller = TextEditingController(
      text: currentLimit.toStringAsFixed(2),
    );

    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit ${Categories.labelOf(categoryId)} budget'),
        content: TextField(
          controller: controller,
          keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Monthly limit',
            prefixText: 'GH₵ ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('delete'),
            child: const Text('Delete',
                style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('cancel'),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('save'),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (!mounted) {
      controller.dispose();
      return;
    }

    if (action == 'delete') {
      widget.budget.clearLimit(categoryId);
    } else if (action == 'save') {
      final parsed = double.tryParse(controller.text.trim());
      if (parsed == null || parsed <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a positive amount')),
        );
      } else {
        widget.budget.setLimit(categoryId, parsed);
      }
    }

    controller.dispose();
  }
}

class _BudgetRow extends StatelessWidget {
  final String categoryId;
  final double limit;
  final double spent;
  final double ratio;
  final VoidCallback onEdit;

  const _BudgetRow({
    required this.categoryId,
    required this.limit,
    required this.spent,
    required this.ratio,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final color = ratio >= 1.0
        ? Colors.red
        : ratio >= 0.75
        ? Colors.amber.shade800
        : Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    Categories.labelOf(categoryId),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${(ratio * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: color.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'GH₵ ${formatAmount(spent)} spent',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    'of GH₵ ${formatAmount(limit)}',
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
      ),
    );
  }
}