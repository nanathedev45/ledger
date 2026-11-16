import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../state/budget_state.dart';
import '../state/ledger_state.dart';
import '../reports/savings.dart';
import '../storage/ledger_database.dart';
import '../storage/vault_cipher.dart';
import 'backup_download_stub.dart'
    if (dart.library.html) 'backup_download_web.dart' as web_download;

class BackupScreen extends StatefulWidget {
  final LedgerState ledger;
  final BudgetState budget;
  final SavingsGoal savings;

  const BackupScreen({
    Key? key,
    required this.ledger,
    required this.budget,
    required this.savings,
  }) : super(key: key);

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _working = false;

  Future<void> _exportBackup() async {
    final password = await _passwordDialog(confirm: true);
    if (password == null) return;
    await _run(() async {
      final database = await LedgerDatabase.open();
      final json = jsonEncode({
        'data': await database.exportSnapshot(),
      });
      final encrypted = await VaultCipher.encryptBackup(json, password);
      final fileName =
          'ledger-backup-${DateTime.now().millisecondsSinceEpoch}.ledgerbackup';
      final bytes = Uint8List.fromList(utf8.encode(encrypted));
      if (kIsWeb) {
        web_download.downloadBackup(fileName, bytes);
      } else if (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS) {
        await Share.shareXFiles([
          XFile.fromData(
            bytes,
            name: fileName,
            mimeType: 'application/octet-stream',
          ),
        ]);
      } else {
        final destination = await getSaveLocation(
          suggestedName: fileName,
        );
        if (!mounted) return;
        if (destination == null) return;
        await XFile.fromData(bytes, name: fileName).saveTo(destination.path);
      }
      _message('Encrypted backup created. Keep its password somewhere safe.');
    });
  }

  Future<void> _importBackup() async {
    final file = await openFile();
    if (!mounted) return;
    if (file == null) return;
    final password = await _passwordDialog(confirm: false);
    if (!mounted) return;
    if (password == null) return;
    final replace = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Replace device data?'),
        content: const Text(
          'Importing this backup replaces the current transactions, budgets, and savings data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Replace'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (replace != true) return;

    await _run(() async {
      final plaintext = await VaultCipher.decryptBackup(
        await file.readAsString(),
        password,
      );
      final decoded = jsonDecode(plaintext) as Map<String, dynamic>;
      final data = Map<String, dynamic>.from(decoded['data'] as Map);
      final database = await LedgerDatabase.open();
      await database.importSnapshot(data);
      await Future.wait([
        widget.ledger.load(),
        widget.budget.load(),
        widget.savings.load(),
      ]);
      _message('Backup restored.');
    });
  }

  Future<String?> _passwordDialog({required bool confirm}) =>
      showDialog<String>(
        context: context,
        builder: (context) => _BackupPasswordDialog(confirm: confirm),
      );

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _working = true);
    try {
      await action();
    } catch (error) {
      _message(error is SecretBoxAuthenticationError
          ? 'That password is incorrect or the backup is damaged.'
          : 'Backup operation failed: $error');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data backup')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(Icons.lock_outline, size: 48, color: Colors.teal),
          const SizedBox(height: 12),
          const Text(
            'Your local database is encrypted on this device. Create a separate encrypted backup to move data to another device or keep an offline copy.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _working ? null : _exportBackup,
            icon: const Icon(Icons.upload_file),
            label: const Text('Create encrypted backup'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _working ? null : _importBackup,
            icon: const Icon(Icons.download),
            label: const Text('Restore backup'),
          ),
          if (_working) ...[
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator()),
          ],
          const SizedBox(height: 20),
          const Text(
            'The backup password is not stored or recoverable. Without it, the backup cannot be restored.',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _BackupPasswordDialog extends StatefulWidget {
  final bool confirm;
  const _BackupPasswordDialog({required this.confirm});

  @override
  State<_BackupPasswordDialog> createState() => _BackupPasswordDialogState();
}

class _BackupPasswordDialogState extends State<_BackupPasswordDialog> {
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  void _submit() {
    if (_password.text.length < 10) {
      setState(() => _error = 'Use at least 10 characters.');
      return;
    }
    if (widget.confirm && _password.text != _confirmation.text) {
      setState(() => _error = 'The passwords do not match.');
      return;
    }
    Navigator.pop(context, _password.text);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.confirm ? 'Set backup password' : 'Backup password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _password,
              obscureText: true,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            if (widget.confirm)
              TextField(
                controller: _confirmation,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: 'Confirm password'),
                onSubmitted: (_) => _submit(),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(onPressed: _submit, child: const Text('Continue')),
        ],
      );
}
