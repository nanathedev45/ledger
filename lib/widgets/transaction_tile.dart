// lib/widgets/transaction_tile.dart
//
// One row in the transaction history list. Hand-built Row instead of
// ListTile — ListTile gives `title` unbounded width during layout, which
// prevents FittedBox from shrinking wide amounts. Expanded(bounded) fixes it.

import 'package:flutter/material.dart';

import '../models/transaction.dart';
import '../utils/currency_format.dart';
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
    // ${sign} braces are required — '₵' would glue into the identifier.
    final amountText = '${sign}GH₵ ${formatAmount(transaction.amount)}';

    final hasSource = transaction.source?.isNotEmpty == true;
    final subtitle = hasSource
        ? '${formatDateTime(transaction.dateTime)}  ·  ${transaction.source}'
        : formatDateTime(transaction.dateTime);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withOpacity(0.12),
            child: Icon(
              isIncome ? Icons.arrow_downward : Icons.arrow_upward,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Expanded → bounded width for the text column → FittedBox
          // has a real ceiling and will shrink when needed.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    amountText,
                    maxLines: 1,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}