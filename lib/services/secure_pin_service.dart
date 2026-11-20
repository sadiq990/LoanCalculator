import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PinVerifyResult {
  final bool success;
  final bool isLockedOut;
  final int remainingLockoutSeconds;
  final int failedAttempts;
  final String? errorMessage;

  const PinVerifyResult({
    required this.success,
    this.isLockedOut = false,
    this.remainingLockoutSeconds = 0,
    this.failedAttempts = 0,
    this.errorMessage,
  });
}

class SecurePinService {
  static const String keyAppHasRunBefore = 'app_has_run_before';
  static const String legacyKeyPin = 'security_pin';

  static const String _keyPinHash = 'secure_pin_hash';
  static const String _keyPinSalt = 'secure_pin_salt';
  static const String _keyFailedAttempts = 'secure_pin_failed_attempts';
  static const String _keyLockoutUntil = 'secure_pin_lockout_until';

  final FlutterSecureStorage _storage;

  SecurePinService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            );

  /// Initializes secure storage, wiping any leftover Keychain data on fresh install
  /// and migrating any existing legacy plaintext PIN.
  Future<void> initialize(SharedPreferences prefs) async {
    final hasRunBefore = prefs.getBool(keyAppHasRunBefore) ?? false;
    if (!hasRunBefore) {
      // Keychain items survive app deletion on iOS. Wipe leftover items on clean install.
      await _storage.deleteAll();
      await prefs.setBool(keyAppHasRunBefore, true);

      final legacyPin = prefs.getString(legacyKeyPin);
      if (legacyPin != null && legacyPin.isNotEmpty) {
        await setPin(legacyPin);
        await prefs.remove(legacyKeyPin);
      }
    } else {
      // Migrate legacy plaintext PIN from SharedPreferences if still present
      final legacyPin = prefs.getString(legacyKeyPin);
      if (legacyPin != null && legacyPin.isNotEmpty) {
        if (!await hasPin()) {
          await setPin(legacyPin);
        }
        await prefs.remove(legacyKeyPin);
      }
    }
  }

  /// Whether a PIN is currently configured
  Future<bool> hasPin() async {
    final hash = await _storage.read(key: _keyPinHash);
    return hash != null && hash.isNotEmpty;
  }

  /// Sets a new PIN: generates a per-install random salt and derives the hash via PBKDF2
  Future<void> setPin(String pin) async {
    final random = Random.secure();
    final salt = List<int>.generate(16, (_) => random.nextInt(256));

    final hashBytes = await _deriveHash(pin, salt);

    await _storage.write(key: _keyPinSalt, value: base64Encode(salt));
    await _storage.write(key: _keyPinHash, value: base64Encode(hashBytes));
    await resetFailedAttempts();
  }

  /// Removes the stored PIN and lockout states
  Future<void> clearPin() async {
    await _storage.delete(key: _keyPinHash);
    await _storage.delete(key: _keyPinSalt);
    await resetFailedAttempts();
  }

  /// Verifies entered PIN with constant-time comparison and brute-force protection
  Future<PinVerifyResult> verifyPin(String pin) async {
    // 1. Check if currently locked out
    final lockoutSeconds = await getRemainingLockoutSeconds();
    if (lockoutSeconds > 0) {
      final attempts = await getFailedAttempts();
      return PinVerifyResult(
        success: false,
        isLockedOut: true,
        remainingLockoutSeconds: lockoutSeconds,
        failedAttempts: attempts,
        errorMessage: 'Too many failed attempts. Try again in ${lockoutSeconds}s.',
      );
    }

    final storedHashBase64 = await _storage.read(key: _keyPinHash);
    final storedSaltBase64 = await _storage.read(key: _keyPinSalt);

    if (storedHashBase64 == null || storedSaltBase64 == null) {
      return const PinVerifyResult(
        success: false,
        errorMessage: 'No PIN configured.',
      );
    }

    final salt = base64Decode(storedSaltBase64);
    final storedHash = base64Decode(storedHashBase64);
    final inputHash = await _deriveHash(pin, salt);

    final isMatch = _constantTimeCompare(inputHash, storedHash);

    if (isMatch) {
      await resetFailedAttempts();
      return const PinVerifyResult(success: true);
    } else {
      final currentAttempts = await _incrementFailedAttempts();
      final penaltySeconds = _getLockoutDurationSeconds(currentAttempts);

      if (penaltySeconds > 0) {
        final lockoutUntil = DateTime.now().toUtc().add(Duration(seconds: penaltySeconds));
        await _storage.write(key: _keyLockoutUntil, value: lockoutUntil.toIso8601String());

        return PinVerifyResult(
          success: false,
          isLockedOut: true,
          remainingLockoutSeconds: penaltySeconds,
          failedAttempts: currentAttempts,
          errorMessage: 'Too many failed attempts. Locked for ${penaltySeconds}s.',
        );
      }

      return PinVerifyResult(
        success: false,
        failedAttempts: currentAttempts,
        errorMessage: 'Incorrect PIN. Try again.',
      );
    }
  }

  Future<int> getFailedAttempts() async {
    final str = await _storage.read(key: _keyFailedAttempts);
    return str == null ? 0 : int.tryParse(str) ?? 0;
  }

  Future<int> getRemainingLockoutSeconds() async {
    final str = await _storage.read(key: _keyLockoutUntil);
    if (str == null) return 0;
    final until = DateTime.tryParse(str);
    if (until == null) return 0;
    final diff = until.difference(DateTime.now().toUtc()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  Future<void> resetFailedAttempts() async {
    await _storage.delete(key: _keyFailedAttempts);
    await _storage.delete(key: _keyLockoutUntil);
  }

  Future<int> _incrementFailedAttempts() async {
    final current = await getFailedAttempts();
    final updated = current + 1;
    await _storage.write(key: _keyFailedAttempts, value: updated.toString());
    return updated;
  }

  /// Escalating lockout delay:
  /// < 5 attempts: 0s
  /// 5 attempts: 30s
  /// 6 attempts: 60s (1m)
  /// 7 attempts: 300s (5m)
  /// >= 8 attempts: 900s (15m)
  int _getLockoutDurationSeconds(int attempts) {
    if (attempts < 5) return 0;
    if (attempts == 5) return 30;
    if (attempts == 6) return 60;
    if (attempts == 7) return 300;
    return 900;
  }

  /// PBKDF2-HMAC-SHA256 derivation with 10,000 iterations
  Future<List<int>> _deriveHash(String pin, List<int> salt) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 10000,
      bits: 256,
    );
    final secretKey = SecretKey(utf8.encode(pin));
    final derived = await pbkdf2.deriveKey(
      secretKey: secretKey,
      nonce: salt,
    );
    return derived.extractBytes();
  }

  /// Constant-time byte array comparison to protect against timing attacks
  bool _constantTimeCompare(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }
}
