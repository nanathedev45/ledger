// lib/widgets/transaction_tile.dart
//
// One row in the transaction history list. Pure presentation — takes a
// MoneyTransaction, renders it, no state, no callbacks (yet).

import 'package:flutter/material.dart';

import '../models/transaction.dart';
import '../utils/date_format.dart';

class TransactionTile extends StatelessWidget {
  final MoneyTransaction transaction;

  const TransactionTile({Key? key, required this.transaction})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.isIncome;
    final sign = isIncome ? '+' : '−'; // U+2212 minus, not hyphen
    final color = isIncome ? Colors.green.shade700 : Colors.red.shade700;
    // Braces on ${sign} are required — '₵' continues the identifier, so
    // '$signGH₵' would look for a variable named 'signGH₵'.
    final amountText = '${sign}GH₵ ${transaction.amount.toStringAsFixed(2)}';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.12),
        child: Icon(
          isIncome ? Icons.arrow_downward : Icons.arrow_upward,
          color: color,
          size: 20,
        ),
      ),
      title: Text(
        amountText,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        transaction.note?.isNotEmpty == true
            ? '${formatDateTime(transaction.dateTime)}  ·  ${transaction.note}'
            : formatDateTime(transaction.dateTime),
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      ),
    );
  }
}