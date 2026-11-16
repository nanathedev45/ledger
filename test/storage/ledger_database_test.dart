import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:ledger/models/transaction.dart';
import 'package:ledger/models/savings_contribution.dart';
import 'package:ledger/storage/ledger_database.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('records survive closing and reopening the encrypted database',
      () async {
    final directory = await Directory.systemTemp.createTemp('ledger-db-test-');
    final databasePath = path.join(directory.path, 'ledger.db');
    final key = SecretKey(List<int>.filled(32, 7));
    final firstOpen = await LedgerDatabase.openForTesting(databasePath, key);

    await firstOpen.saveTransaction(MoneyTransaction(
      id: 'tx-1',
      type: TransactionType.expense,
      amount: 42.5,
      dateTime: DateTime.utc(2026, 11, 10),
      source: 'Groceries',
      categoryId: 'food',
    ));
    await firstOpen.saveBudget('food', 300);
    await firstOpen.saveMonthlyTarget(100);
    await firstOpen.saveContribution(SavingsContribution(
      amount: 25,
      dateTime: DateTime.utc(2026, 11, 12),
      note: 'weekly savings',
    ));
    await firstOpen.closeForTesting();

    final reopened = await LedgerDatabase.openForTesting(databasePath, key);
    addTearDown(() async {
      await reopened.closeForTesting();
      await directory.delete(recursive: true);
    });

    expect((await reopened.loadTransactions()).single.categoryId, 'food');
    expect((await reopened.loadTransactions()).single.amount, 42.5);
    expect(await reopened.loadBudgets(), {'food': 300.0});
    expect(await reopened.loadMonthlyTarget(), 100.0);
    expect((await reopened.loadContributions()).single.amount, 25.0);
  });

  test('migrates version 1 plaintext rows into the encrypted vault', () async {
    final directory = await Directory.systemTemp.createTemp('ledger-migrate-');
    final databasePath = path.join(directory.path, 'ledger.db');
    final legacy = await openDatabase(
      databasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE transactions (
            id TEXT PRIMARY KEY, type TEXT NOT NULL, amount REAL NOT NULL,
            date_time TEXT NOT NULL, source TEXT, category_id TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE budgets (
            category_id TEXT PRIMARY KEY, monthly_limit REAL NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE savings_goal (
            id INTEGER PRIMARY KEY, monthly_target REAL NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE savings_contributions (
            id INTEGER PRIMARY KEY AUTOINCREMENT, amount REAL NOT NULL,
            date_time TEXT NOT NULL, note TEXT
          )
        ''');
        await db.insert('transactions', {
          'id': 'old-1',
          'type': 'expense',
          'amount': 12.5,
          'date_time': '2026-10-01T12:00:00.000Z',
          'source': 'Market',
          'category_id': 'food',
        });
        await db
            .insert('budgets', {'category_id': 'food', 'monthly_limit': 80});
        await db.insert('savings_goal', {'id': 1, 'monthly_target': 55});
        await db.insert('savings_contributions', {
          'amount': 10,
          'date_time': '2026-10-02T12:00:00.000Z',
          'note': 'saved',
        });
      },
    );
    await legacy.close();

    final migrated = await LedgerDatabase.openForTesting(
      databasePath,
      SecretKey(List<int>.filled(32, 8)),
    );
    addTearDown(() async {
      await migrated.closeForTesting();
      await directory.delete(recursive: true);
    });

    expect((await migrated.loadTransactions()).single.categoryId, 'food');
    expect(await migrated.loadBudgets(), {'food': 80.0});
    expect(await migrated.loadMonthlyTarget(), 55.0);
    expect((await migrated.loadContributions()).single.amount, 10.0);

    final inspection = await databaseFactory.openDatabase(databasePath);
    final tables = await inspection.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    );
    expect(tables.map((row) => row['name']), contains('vault'));
    expect(tables.map((row) => row['name']), isNot(contains('transactions')));
    final payload =
        (await inspection.query('vault')).single['payload'] as String;
    expect(payload, isNot(contains('Market')));
    await inspection.close();
  });
}
