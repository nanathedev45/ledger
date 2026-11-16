import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class VaultCipher {
  static const _deviceKeyName = 'ledger.database.key.v1';
  static const _storage = FlutterSecureStorage();
  static final _aes = AesGcm.with256bits();
  static final _random = Random.secure();

  static Future<SecretKey> loadDeviceKey() async {
    var encoded = await _storage.read(key: _deviceKeyName);
    if (encoded == null) {
      final bytes = List<int>.generate(32, (_) => _random.nextInt(256));
      encoded = base64Encode(bytes);
      await _storage.write(key: _deviceKeyName, value: encoded);
    }
    return SecretKey(base64Decode(encoded));
  }

  static Future<String> encrypt(String value, SecretKey key) async {
    final box = await _aes.encrypt(utf8.encode(value), secretKey: key);
    return jsonEncode({
      'nonce': base64Encode(box.nonce),
      'ciphertext': base64Encode(box.cipherText),
      'mac': base64Encode(box.mac.bytes),
    });
  }

  static Future<String> decrypt(String value, SecretKey key) async {
    final encoded = jsonDecode(value) as Map<String, dynamic>;
    final box = SecretBox(
      base64Decode(encoded['ciphertext'] as String),
      nonce: base64Decode(encoded['nonce'] as String),
      mac: Mac(base64Decode(encoded['mac'] as String)),
    );
    return utf8.decode(await _aes.decrypt(box, secretKey: key));
  }

  static Future<String> encryptBackup(String value, String password) async {
    final salt = List<int>.generate(16, (_) => _random.nextInt(256));
    final key = await _deriveBackupKey(password, salt);
    final box = await _aes.encrypt(utf8.encode(value), secretKey: key);
    return jsonEncode({
      'format': 'ledger-encrypted-backup',
      'version': 1,
      'salt': base64Encode(salt),
      'nonce': base64Encode(box.nonce),
      'ciphertext': base64Encode(box.cipherText),
      'mac': base64Encode(box.mac.bytes),
    });
  }

  static Future<String> decryptBackup(String value, String password) async {
    final encoded = jsonDecode(value) as Map<String, dynamic>;
    if (encoded['format'] != 'ledger-encrypted-backup' ||
        encoded['version'] != 1) {
      throw const FormatException('This is not a supported Ledger backup.');
    }
    final salt = base64Decode(encoded['salt'] as String);
    final key = await _deriveBackupKey(password, salt);
    final box = SecretBox(
      base64Decode(encoded['ciphertext'] as String),
      nonce: base64Decode(encoded['nonce'] as String),
      mac: Mac(base64Decode(encoded['mac'] as String)),
    );
    return utf8.decode(await _aes.decrypt(box, secretKey: key));
  }

  static Future<SecretKey> _deriveBackupKey(String password, List<int> salt) {
    final kdf = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 120000,
      bits: 256,
    );
    return kdf.deriveKey(
        secretKey: SecretKey(utf8.encode(password)), nonce: salt);
  }
}
