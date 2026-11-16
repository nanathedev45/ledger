import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'package:synchronized/synchronized.dart';

import '../models/savings_contribution.dart';
import '../models/transaction.dart';
import 'vault_cipher.dart';

/// SQLite persistence with an AES-GCM encrypted snapshot at rest.
class LedgerDatabase {
  LedgerDatabase._(this._database, this._key);

  final Database _database;
  final SecretKey _key;
  final Lock _writeLock = Lock();
  static Future<LedgerDatabase>? _opening;

  static Future<LedgerDatabase> open() {
    _opening ??= _open();
    return _opening!;
  }

  static Future<LedgerDatabase> _open() async {
    final key = await VaultCipher.loadDeviceKey();
    final directory = await getDatabasesPath();
    return _openAtPath(path.join(directory, 'ledger.db'), key);
  }

  @visibleForTesting
  static Future<LedgerDatabase> openForTesting(
    String databasePath,
    SecretKey key,
  ) =>
      _openAtPath(databasePath, key);

  static Future<LedgerDatabase> _openAtPath(
    String databasePath,
    SecretKey key,
  ) async {
    var migrated = false;
    final db = await openDatabase(
      databasePath,
      version: 2,
      onConfigure: (db) => db.execute('PRAGMA secure_delete = ON'),
      onCreate: (db, version) => db.execute(
        'CREATE TABLE vault (id INTEGER PRIMARY KEY CHECK (id = 1), payload TEXT NOT NULL)',
      ),
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'CREATE TABLE vault (id INTEGER PRIMARY KEY CHECK (id = 1), payload TEXT NOT NULL)',
          );
          final snapshot = await _migrateLegacyTables(db);
          final cipher = await VaultCipher.encrypt(jsonEncode(snapshot), key);
          await db.insert('vault', {'id': 1, 'payload': cipher});
          await db.execute('DROP TABLE IF EXISTS transactions');
          await db.execute('DROP TABLE IF EXISTS budgets');
          await db.execute('DROP TABLE IF EXISTS savings_goal');
          await db.execute('DROP TABLE IF EXISTS savings_contributions');
          migrated = true;
        }
      },
    );
    if (migrated) await db.execute('VACUUM');
    return LedgerDatabase._(db, key);
  }

  @visibleForTesting
  Future<void> closeForTesting() => _database.close();

  static Future<Map<String, dynamic>> _migrateLegacyTables(Database db) async {
    final snapshot = <String, dynamic>{
      'transactions': <Map<String, dynamic>>[],
      'budgets': <String, double>{},
      'monthlyTarget': 0.0,
      'contributions': <Map<String, dynamic>>[],
      'nextContributionId': 1,
    };
    final tables = (await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    ))
        .map((row) => row['name'] as String)
        .toSet();

    if (tables.contains('transactions')) {
      final rows = await db.query('transactions');
      snapshot['transactions'] = rows
          .map((row) => <String, dynamic>{
                'id': row['id'],
                'type': row['type'],
                'amount': row['amount'],
                'dateTime': row['date_time'],
                'source': row['source'],
                'categoryId': row['category_id'],
              })
          .toList();
    }
    if (tables.contains('budgets')) {
      final rows = await db.query('budgets');
      snapshot['budgets'] = {
        for (final row in rows)
          row['category_id'] as String:
              (row['monthly_limit'] as num).toDouble(),
      };
    }
    if (tables.contains('savings_goal')) {
      final rows = await db.query('savings_goal', where: 'id = 1');
      if (rows.isNotEmpty) {
        snapshot['monthlyTarget'] =
            (rows.first['monthly_target'] as num).toDouble();
      }
    }
    if (tables.contains('savings_contributions')) {
      final rows = await db.query('savings_contributions', orderBy: 'id ASC');
      snapshot['contributions'] = rows
          .map((row) => <String, dynamic>{
                'id': row['id'],
                'amount': row['amount'],
                'dateTime': row['date_time'],
                'note': row['note'],
              })
          .toList();
      if (rows.isNotEmpty) {
        snapshot['nextContributionId'] = (rows.last['id'] as int) + 1;
      }
    }
    return snapshot;
  }

  Future<Map<String, dynamic>> _readSnapshot() async {
    final rows = await _database.query('vault', where: 'id = 1');
    if (rows.isEmpty) return _emptySnapshot();
    return jsonDecode(await VaultCipher.decrypt(
      rows.first['payload'] as String,
      _key,
    )) as Map<String, dynamic>;
  }

  static Map<String, dynamic> _emptySnapshot() => {
        'transactions': <Map<String, dynamic>>[],
        'budgets': <String, double>{},
        'monthlyTarget': 0.0,
        'contributions': <Map<String, dynamic>>[],
        'nextContributionId': 1,
      };

  Future<void> _writeSnapshot(Map<String, dynamic> snapshot) async {
    final payload = await VaultCipher.encrypt(jsonEncode(snapshot), _key);
    await _database.insert(
      'vault',
      {'id': 1, 'payload': payload},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<T> _mutate<T>(T Function(Map<String, dynamic>) action) =>
      _writeLock.synchronized(() async {
        final snapshot = await _readSnapshot();
        final result = action(snapshot);
        await _writeSnapshot(snapshot);
        return result;
      });

  Future<List<MoneyTransaction>> loadTransactions() async {
    final snapshot = await _readSnapshot();
    final items = snapshot['transactions'] as List<dynamic>;
    return items
        .map((item) => MoneyTransaction.fromJson(
              Map<String, dynamic>.from(item as Map),
            ))
        .toList();
  }

  Future<void> saveTransaction(MoneyTransaction transaction) =>
      _mutate<void>((snapshot) {
        final items = (snapshot['transactions'] as List<dynamic>)
            .cast<Map<String, dynamic>>();
        final index = items.indexWhere((item) => item['id'] == transaction.id);
        if (index == -1) {
          items.add(transaction.toJson());
        } else {
          items[index] = transaction.toJson();
        }
      });

  Future<void> clearTransactions() => _mutate<void>((snapshot) {
        snapshot['transactions'] = <Map<String, dynamic>>[];
      });

  Future<Map<String, double>> loadBudgets() async {
    final snapshot = await _readSnapshot();
    return Map<String, double>.from(
      (snapshot['budgets'] as Map).map(
        (key, value) => MapEntry(key as String, (value as num).toDouble()),
      ),
    );
  }

  Future<void> saveBudget(String categoryId, double amount) =>
      _mutate<void>((snapshot) {
        final budgets = snapshot['budgets'] as Map<String, dynamic>;
        if (amount <= 0) {
          budgets.remove(categoryId);
        } else {
          budgets[categoryId] = amount;
        }
      });

  Future<void> clearBudgets() => _mutate<void>((snapshot) {
        snapshot['budgets'] = <String, double>{};
      });

  Future<double> loadMonthlyTarget() async =>
      ((await _readSnapshot())['monthlyTarget'] as num).toDouble();

  Future<void> saveMonthlyTarget(double amount) => _mutate<void>((snapshot) {
        snapshot['monthlyTarget'] = amount;
      });

  Future<List<SavingsContribution>> loadContributions() async {
    final snapshot = await _readSnapshot();
    return (snapshot['contributions'] as List<dynamic>)
        .map((item) => SavingsContribution(
              id: (item as Map)['id'] as int,
              amount: ((item)['amount'] as num).toDouble(),
              dateTime: DateTime.parse((item)['dateTime'] as String),
              note: (item)['note'] as String?,
            ))
        .toList();
  }

  Future<int> saveContribution(SavingsContribution contribution) =>
      _mutate<int>((snapshot) {
        final id = snapshot['nextContributionId'] as int;
        snapshot['nextContributionId'] = id + 1;
        (snapshot['contributions'] as List<dynamic>).add({
          'id': id,
          'amount': contribution.amount,
          'dateTime': contribution.dateTime.toIso8601String(),
          'note': contribution.note,
        });
        return id;
      });

  Future<void> removeContribution(int id) => _mutate<void>((snapshot) {
        (snapshot['contributions'] as List<dynamic>)
            .removeWhere((item) => (item as Map)['id'] == id);
      });

  Future<void> clearSavings() => _mutate<void>((snapshot) {
        snapshot['contributions'] = <Map<String, dynamic>>[];
        snapshot['monthlyTarget'] = 0.0;
        snapshot['nextContributionId'] = 1;
      });

  Future<Map<String, dynamic>> exportSnapshot() => _readSnapshot();

  Future<void> importSnapshot(Map<String, dynamic> snapshot) async {
    if (snapshot['transactions'] is! List ||
        snapshot['budgets'] is! Map ||
        snapshot['contributions'] is! List ||
        snapshot['monthlyTarget'] is! num) {
      throw const FormatException('The backup data is incomplete.');
    }
    final normalized = _emptySnapshot();
    final transactionIds = <String>{};
    for (final transaction in snapshot['transactions'] as List) {
      final parsed = MoneyTransaction.fromJson(
        Map<String, dynamic>.from(transaction as Map),
      );
      if (!parsed.amount.isFinite ||
          parsed.amount <= 0 ||
          !transactionIds.add(parsed.id)) {
        throw const FormatException(
            'The backup contains invalid transactions.');
      }
      (normalized['transactions'] as List<dynamic>).add(parsed.toJson());
    }
    final budgets = <String, double>{};
    (snapshot['budgets'] as Map).forEach((key, value) {
      if (key is! String ||
          value is! num ||
          !value.toDouble().isFinite ||
          value <= 0) {
        throw const FormatException('The backup contains invalid budgets.');
      }
      budgets[key] = value.toDouble();
    });
    normalized['budgets'] = budgets;

    final target = (snapshot['monthlyTarget'] as num).toDouble();
    if (!target.isFinite || target < 0) {
      throw const FormatException(
          'The backup contains an invalid savings target.');
    }
    normalized['monthlyTarget'] = target;

    final contributionIds = <int>{};
    var nextId = 1;
    for (final item in snapshot['contributions'] as List) {
      final row = Map<String, dynamic>.from(item as Map);
      final id = row['id'];
      final amount = row['amount'];
      final date = row['dateTime'];
      if (id is! int ||
          amount is! num ||
          !amount.toDouble().isFinite ||
          amount <= 0 ||
          date is! String ||
          !contributionIds.add(id)) {
        throw const FormatException(
            'The backup contains invalid savings records.');
      }
      DateTime.parse(date);
      nextId = id >= nextId ? id + 1 : nextId;
      (normalized['contributions'] as List<dynamic>).add({
        'id': id,
        'amount': amount.toDouble(),
        'dateTime': date,
        'note': row['note'] as String?,
      });
    }
    normalized['nextContributionId'] = nextId;
    await _writeLock.synchronized(() => _writeSnapshot(normalized));
  }
}
