import 'package:flutter/material.dart';

class TransactionButtons extends StatelessWidget {
  final VoidCallback onAdd;
  final VoidCallback onDeduct;

  const TransactionButtons(
      {Key? key, required this.onAdd, required this.onDeduct})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onDeduct,
              icon: const Icon(Icons.remove),
              label: const Text('Deduct'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}