import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      // In a real production app with higher security needs,
      // one might consider requiring authentication for key access:
      // storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  static const _keyMasterSalt = 'master_salt';
  static const _keyMasterHash = 'master_hash';
  static const _keyVaultKey = 'vault_key'; // We still store it, but better protected
  static const _keyBiometricsEnabled = 'biometrics_enabled';

  /// Generate a random vault encryption key (32 bytes) and persist it.
  static Future<List<int>> ensureVaultKey() async {
    final existing = await _storage.read(key: _keyVaultKey);
    if (existing != null) {
      return base64Decode(existing);
    }

    final rng = Random.secure();
    final keyBytes =
        List<int>.generate(32, (_) => rng.nextInt(256)); // 256-bit key
    await _storage.write(
      key: _keyVaultKey,
      value: base64Encode(keyBytes),
    );
    return keyBytes;
  }

  static Future<List<int>> getVaultKey() async {
    final existing = await _storage.read(key: _keyVaultKey);
    if (existing == null) {
      throw StateError('Vault key not initialized');
    }
    return base64Decode(existing);
  }

  static Future<bool> hasMasterPassword() async {
    final hash = await _storage.read(key: _keyMasterHash);
    return hash != null;
  }

  static Future<void> saveMasterPassword(
    String password,
    bool biometricsEnabled,
  ) async {
    final rng = Random.secure();
    final salt = List<int>.generate(16, (_) => rng.nextInt(256));
    final saltBase64 = base64Encode(salt);

    // Using PBKDF2 (via SHA-256 with iterations) logic manually implemented below
    // or simply a stronger hash. Here we stick to SHA-256 for simplicity but salt it.
    // Ideally, use a package like 'pointycastle' for PBKDF2.
    final hash = _hashPassword(password, salt);
    final hashBase64 = base64Encode(hash);

    await _storage.write(key: _keyMasterSalt, value: saltBase64);
    await _storage.write(key: _keyMasterHash, value: hashBase64);
    await _storage.write(
      key: _keyBiometricsEnabled,
      value: biometricsEnabled ? '1' : '0',
    );

    // ensure vault key exists
    await ensureVaultKey();
  }

  static Future<bool> verifyMasterPassword(String password) async {
    final saltBase64 = await _storage.read(key: _keyMasterSalt);
    final hashBase64 = await _storage.read(key: _keyMasterHash);
    if (saltBase64 == null || hashBase64 == null) return false;

    final salt = base64Decode(saltBase64);
    final expectedHash = base64Decode(hashBase64);
    final actualHash = _hashPassword(password, salt);

    if (expectedHash.length != actualHash.length) return false;

    var diff = 0;
    for (var i = 0; i < expectedHash.length; i++) {
      diff |= expectedHash[i] ^ actualHash[i];
    }
    return diff == 0;
  }

  static List<int> _hashPassword(String password, List<int> salt) {
    // 5000 iterations of SHA-256 to slow down brute force
    // (A real PBKDF2 implementation is better, but this is a solid improvement over 1 round)
    var bytes = <int>[];
    bytes.addAll(salt);
    bytes.addAll(utf8.encode(password));
    
    var digest = sha256.convert(bytes);
    
    for (var i = 0; i < 4999; i++) {
      final b = <int>[...digest.bytes, ...salt];
      digest = sha256.convert(b);
    }
    
    return digest.bytes;
  }

  static Future<bool> isBiometricsEnabled() async {
    final value = await _storage.read(key: _keyBiometricsEnabled);
    return value == '1';
  }

  static Future<void> setBiometricsEnabled(bool enabled) async {
    await _storage.write(
      key: _keyBiometricsEnabled,
      value: enabled ? '1' : '0',
    );
  }
}
