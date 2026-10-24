// test/ml/financial_profile_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/ml/financial_profile.dart';
import 'package:ledger/models/transaction.dart';

MoneyTransaction _tx({
  required TransactionType type,
  required double amount,
  required DateTime at,
}) {
  return MoneyTransaction(
    id: at.millisecondsSinceEpoch.toString() + amount.toString(),
    type: type,
    amount: amount,
    dateTime: at,
  );
}

void main() {
  group('computeProfile', () {
    test('empty transactions → insufficientData', () {
      final p = computeProfile([]);
      expect(p.archetype, FinancialArchetype.insufficientData);
      expect(p.confidence, 0.0);
    });

    test('strong savings + consistent spend → steadySaver or disciplinedBuilder',
        () {
      final now = DateTime.now();
      final txs = [
        _tx(type: TransactionType.income, amount: 1000,
            at: now.subtract(const Duration(days: 10))),
        // small, consistent expenses
        for (var i = 1; i <= 15; i++)
          _tx(type: TransactionType.expense, amount: 20,
              at: now.subtract(Duration(days: i))),
      ];
      final p = computeProfile(txs);
      expect(
        p.archetype == FinancialArchetype.steadySaver ||
            p.archetype == FinancialArchetype.disciplinedBuilder,
        true,
      );
      expect(p.advice, isNotEmpty);
      expect(p.signals, isNotEmpty);
    });

    test('overspending with volatile spend → yoloSpender or impulseSpender',
        () {
      final now = DateTime.now();
      final txs = [
        _tx(type: TransactionType.income, amount: 100,
            at: now.subtract(const Duration(days: 20))),
        _tx(type: TransactionType.expense, amount: 400,
            at: now.subtract(const Duration(days: 5))),
        _tx(type: TransactionType.expense, amount: 10,
            at: now.subtract(const Duration(days: 3))),
      ];
      final p = computeProfile(txs);
      expect(
        p.archetype == FinancialArchetype.yoloSpender ||
            p.archetype == FinancialArchetype.impulseSpender ||
            p.archetype == FinancialArchetype.paycheckToPaycheck,
        true,
      );
    });
  });
}