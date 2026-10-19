// lib/widgets/balance_card.dart
//
// Masked/unmasked balance card. The amount row is Flexible + FittedBox so
// large balances shrink-to-fit instead of overflowing horizontally.

import 'package:flutter/material.dart';

import '../utils/currency_format.dart';

class BalanceCard extends StatefulWidget {
  final double balance;
  const BalanceCard({Key? key, required this.balance}) : super(key: key);

  @override
  State<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<BalanceCard> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    // Masked form is short by design; revealed form gets comma-separated
    // formatting so it stays consistent with the transaction list.
    final text = _obscured
        ? 'GH₵ *****'
        : 'GH₵ ${formatAmount(widget.balance)}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            const Text(
              'Your Balance',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Flexible + FittedBox: shrink-to-fit if the amount is too
                // wide. Without Flexible, Text has no width ceiling and the
                // outer Row overflows at large balances.
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      text,
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _obscured ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () => setState(() => _obscured = !_obscured),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}