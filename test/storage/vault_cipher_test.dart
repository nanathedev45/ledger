import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/storage/vault_cipher.dart';

void main() {
  group('encrypted backups', () {
    test('round trips with the matching password', () async {
      const data = '{"transactions":[]}';
      final backup =
          await VaultCipher.encryptBackup(data, 'correct horse battery');

      expect(backup, isNot(contains(data)));
      expect(
        await VaultCipher.decryptBackup(backup, 'correct horse battery'),
        data,
      );
    });

    test('rejects an incorrect password', () async {
      final backup = await VaultCipher.encryptBackup(
        '{"budgets":{}}',
        'correct horse battery',
      );

      expect(
        () => VaultCipher.decryptBackup(backup, 'wrong password'),
        throwsA(isA<SecretBoxAuthenticationError>()),
      );
    });
  });
}
