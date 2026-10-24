// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';

import '../ml/financial_profile.dart';
import '../navigation/screen_id.dart';
import '../reports/savings.dart';
import '../state/budget_state.dart';
import '../state/ledger_state.dart';
import '../widgets/ledger_drawer.dart';

class ProfileScreen extends StatefulWidget {
  final LedgerState ledger;
  final BudgetState budget;
  final SavingsGoal savings;

  const ProfileScreen({
    Key? key,
    required this.ledger,
    required this.budget,
    required this.savings,
  }) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: LedgerDrawer(
        current: ScreenId.profile,
        ledger: widget.ledger,
        budget: widget.budget,
        savings: widget.savings,
      ),
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Recalculate',
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([widget.ledger, widget.budget]),
        builder: (context, _) {
          final limits = widget.budget.limits.values;
          final monthlyBudget =
          limits.isEmpty ? null : limits.reduce((a, b) => a + b);

          final profile = computeProfile(
            widget.ledger.transactions,
            monthlyBudget: monthlyBudget,
          );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ArchetypeCard(profile: profile),
              const SizedBox(height: 24),
              if (profile.signals.isNotEmpty) ...[
                const Text(
                  'Your signals',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                ...profile.signals.map(
                      (s) => _SignalCard(signal: s),
                ),
                const SizedBox(height: 24),
              ],
              if (profile.advice.isNotEmpty) ...[
                const Text(
                  'Advice',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                ...profile.advice.map(
                      (a) => _AdviceCard(advice: a),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ArchetypeCard extends StatelessWidget {
  final FinancialProfile profile;

  const _ArchetypeCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.psychology_outlined,
                    color: Colors.blue, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.archetypeLabel,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Your financial archetype',
                        style:
                        TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              profile.summary,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Confidence',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  '${(profile.confidence * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: profile.confidence,
                minHeight: 6,
                backgroundColor: Colors.blue.withOpacity(0.15),
                valueColor:
                const AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignalCard extends StatelessWidget {
  final FeatureSignal signal;

  const _SignalCard({required this.signal});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  signal.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${(signal.value * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: signal.value.clamp(0.0, 1.0),
                minHeight: 5,
                backgroundColor: Colors.blue.withOpacity(0.12),
                valueColor:
                const AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              signal.interpretation,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdviceCard extends StatelessWidget {
  final Advice advice;

  const _AdviceCard({required this.advice});

  Color get _color {
    switch (advice.severity) {
      case 'positive':
        return Colors.green;
      case 'warning':
        return Colors.amber.shade800;
      default:
        return Colors.blueGrey;
    }
  }

  IconData get _icon {
    switch (advice.severity) {
      case 'positive':
        return Icons.check_circle_outline;
      case 'warning':
        return Icons.warning_amber_outlined;
      default:
        return Icons.lightbulb_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_icon, color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    advice.headline,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    advice.detail,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}