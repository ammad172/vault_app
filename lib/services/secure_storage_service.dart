import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/export.dart';

/// Service for secure storage of sensitive data like master password hash and vault encryption key
class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      sharedPreferencesName: 'vault_prefs',
      preferencesKeyPrefix: 'vault_',
    ),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _keyMasterSalt = 'master_salt';
  static const _keyMasterHash = 'master_hash';
  static const _keyVaultKey = 'vault_key';
  static const _keyBiometricsEnabled = 'biometrics_enabled';
  static const _keyFailedAttempts = 'failed_attempts';
  static const _keyLockoutUntil = 'lockout_until';

  static const int _maxFailedAttempts = 5;
  static const int _lockoutSeconds = 30;

  /// Generate a random vault encryption key (32 bytes) and persist it.
  static Future<List<int>> ensureVaultKey() async {
    final existing = await _storage.read(key: _keyVaultKey);
    if (existing != null) {
      return base64Decode(existing);
    }

    final rng = Random.secure();
    final keyBytes = List<int>.generate(
      32,
      (_) => rng.nextInt(256),
    ); // 256-bit key
    await _storage.write(key: _keyVaultKey, value: base64Encode(keyBytes));
    return keyBytes;
  }

  static Future<List<int>> getVaultKey() async {
    final existing = await _storage.read(key: _keyVaultKey);
    if (existing == null) {
      throw StateError(
        'Vault key not initialized. Please set up your master password first.',
      );
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
    // Validate password strength
    if (password.length < 12) {
      throw ArgumentError('Password must be at least 12 characters long');
    }

    final rng = Random.secure();
    final salt = List<int>.generate(16, (_) => rng.nextInt(256));
    final saltBase64 = base64Encode(salt);

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

  /// Verify master password with rate limiting to prevent brute force attacks
  static Future<bool> verifyMasterPassword(String password) async {
    // Check if currently locked out
    final lockoutUntilStr = await _storage.read(key: _keyLockoutUntil);
    if (lockoutUntilStr != null) {
      final lockoutUntil = DateTime.parse(lockoutUntilStr);
      if (DateTime.now().isBefore(lockoutUntil)) {
        final remaining = lockoutUntil.difference(DateTime.now()).inSeconds;
        throw Exception(
          'Too many failed attempts. Try again in $remaining seconds.',
        );
      } else {
        // Lockout expired, reset
        await _storage.delete(key: _keyLockoutUntil);
        await _storage.delete(key: _keyFailedAttempts);
      }
    }

    final saltBase64 = await _storage.read(key: _keyMasterSalt);
    final hashBase64 = await _storage.read(key: _keyMasterHash);
    if (saltBase64 == null || hashBase64 == null) return false;

    final salt = base64Decode(saltBase64);
    final expectedHash = base64Decode(hashBase64);
    final actualHash = _hashPassword(password, salt);

    if (expectedHash.length != actualHash.length) {
      await _recordFailedAttempt();
      return false;
    }

    var diff = 0;
    for (var i = 0; i < expectedHash.length; i++) {
      diff |= expectedHash[i] ^ actualHash[i];
    }

    if (diff != 0) {
      await _recordFailedAttempt();
      return false;
    }

    // Success - reset failed attempts
    await _storage.delete(key: _keyFailedAttempts);
    return true;
  }

  /// Record a failed unlock attempt and trigger lockout if needed
  static Future<void> _recordFailedAttempt() async {
    final attemptsStr = await _storage.read(key: _keyFailedAttempts);
    final attempts = int.tryParse(attemptsStr ?? '0') ?? 0;
    final newAttempts = attempts + 1;

    if (newAttempts >= _maxFailedAttempts) {
      // Trigger lockout
      final lockoutUntil = DateTime.now().add(
        const Duration(seconds: _lockoutSeconds),
      );
      await _storage.write(
        key: _keyLockoutUntil,
        value: lockoutUntil.toIso8601String(),
      );
      await _storage.write(key: _keyFailedAttempts, value: '0');
    } else {
      await _storage.write(
        key: _keyFailedAttempts,
        value: newAttempts.toString(),
      );
    }
  }

  /// Hash password using PBKDF2 with 600,000 iterations (OWASP 2024 recommendation)
  static List<int> _hashPassword(String password, List<int> salt) {
    // PBKDF2 with 600,000 iterations (OWASP recommended for 2024)
    // Using HMAC-SHA256 for the PRF (Pseudorandom Function)
    final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(Uint8List.fromList(salt), 600000, 32));

    return pbkdf2.process(Uint8List.fromList(utf8.encode(password)));
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

  /// Get remaining lockout time in seconds (0 if not locked out)
  static Future<int> getRemainingLockoutSeconds() async {
    final lockoutUntilStr = await _storage.read(key: _keyLockoutUntil);
    if (lockoutUntilStr == null) return 0;

    final lockoutUntil = DateTime.parse(lockoutUntilStr);
    if (DateTime.now().isBefore(lockoutUntil)) {
      return lockoutUntil.difference(DateTime.now()).inSeconds;
    }
    return 0;
  }
}
