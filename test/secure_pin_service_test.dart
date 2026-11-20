import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:loan_calculator/services/secure_pin_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SecurePinService Security & Brute-Force Tests', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      SharedPreferences.setMockInitialValues({});
    });

    test('PBKDF2 derives hash and constant-time verify succeeds for valid PIN', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = SecurePinService();
      await service.initialize(prefs);

      expect(await service.hasPin(), isFalse);

      await service.setPin('123456');
      expect(await service.hasPin(), isTrue);

      // Verify correct PIN
      final validResult = await service.verifyPin('123456');
      expect(validResult.success, isTrue);
      expect(validResult.isLockedOut, isFalse);

      // Verify incorrect PIN
      final invalidResult = await service.verifyPin('654321');
      expect(invalidResult.success, isFalse);
      expect(invalidResult.failedAttempts, equals(1));
    });

    test('Fresh install wipes leftover Keychain items', () async {
      // Simulate leftover data from previous installation in keychain
      FlutterSecureStorage.setMockInitialValues({
        'secure_pin_hash': 'leftover_hash',
        'secure_pin_salt': 'leftover_salt',
      });
      // SharedPreferences is empty (fresh install)
      SharedPreferences.setMockInitialValues({});

      final prefs = await SharedPreferences.getInstance();
      final service = SecurePinService();
      await service.initialize(prefs);

      // Should be wiped on fresh install
      expect(await service.hasPin(), isFalse);
      expect(prefs.getBool(SecurePinService.keyAppHasRunBefore), isTrue);
    });

    test('Legacy plaintext PIN in SharedPreferences is migrated and removed', () async {
      FlutterSecureStorage.setMockInitialValues({});
      SharedPreferences.setMockInitialValues({
        SecurePinService.legacyKeyPin: '998877',
      });

      final prefs = await SharedPreferences.getInstance();
      final service = SecurePinService();
      await service.initialize(prefs);

      // PIN should now be in secure storage
      expect(await service.hasPin(), isTrue);
      // Plaintext key must be deleted
      expect(prefs.containsKey(SecurePinService.legacyKeyPin), isFalse);

      // Correct PIN verifies
      final result = await service.verifyPin('998877');
      expect(result.success, isTrue);
    });

    test('Brute force lockout: 5th failure triggers 30s delay, success resets counter', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = SecurePinService();
      await service.initialize(prefs);
      await service.setPin('112233');

      // Fail 4 times: no lockout yet
      for (int i = 1; i <= 4; i++) {
        final res = await service.verifyPin('000000');
        expect(res.success, isFalse);
        expect(res.isLockedOut, isFalse);
        expect(res.failedAttempts, equals(i));
      }

      // 5th failure: triggers 30s lockout
      final res5 = await service.verifyPin('000000');
      expect(res5.success, isFalse);
      expect(res5.isLockedOut, isTrue);
      expect(res5.remainingLockoutSeconds, closeTo(30, 2));

      // Attempt while locked out is rejected immediately
      final resLocked = await service.verifyPin('112233');
      expect(resLocked.success, isFalse);
      expect(resLocked.isLockedOut, isTrue);

      // Reset lockout and verify correct PIN resets counter
      await service.resetFailedAttempts();
      final resSuccess = await service.verifyPin('112233');
      expect(resSuccess.success, isTrue);
      expect(await service.getFailedAttempts(), equals(0));
    });
  });
}
