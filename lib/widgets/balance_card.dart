import 'package:flutter/material.dart';

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
    final text = _obscured ? 'GH₵ ****' : 'GH₵ ${widget.balance.toStringAsFixed(2)}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            const Text('Balance', style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(text,
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: Icon(_obscured ? Icons.visibility_off : Icons.visibility),
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