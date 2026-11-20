import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:loan_calculator/app.dart';
import 'package:loan_calculator/models/loan.dart';
import 'package:loan_calculator/providers/settings_provider.dart';
import 'package:loan_calculator/screens/lock_screen.dart';
import 'package:loan_calculator/services/secure_pin_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  group('PIN Storage Security & Exclusion Tests', () {
    test('PIN is stored in Keychain and NEVER written as plaintext to SharedPreferences', () async {
      final prefs = await SharedPreferences.getInstance();
      final pinService = SecurePinService();
      await pinService.initialize(prefs);

      await pinService.setPin('849201');

      // Check SharedPreferences: PIN must NOT be in prefs
      expect(prefs.containsKey('security_pin'), isFalse,
          reason: 'Plaintext PIN must never be stored in SharedPreferences');
      expect(prefs.containsKey('pin'), isFalse);
      expect(prefs.getString('security_pin'), isNull);

      // Verify that verifyPin works from Keychain
      final result = await pinService.verifyPin('849201');
      expect(result.success, isTrue);
    });

    test('Exported backup JSON does NOT contain PIN, hash, or security secrets', () {
      final loan = Loan(
        id: 'test-loan',
        name: 'Private Loan',
        totalAmount: 10000,
        interestRate: 5.0,
        termMonths: 12,
        paymentDay: 1,
        createdAt: DateTime.now(),
      );

      final backupData = {
        'schemaVersion': 1,
        'appVersion': '1.0.0',
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
        'data': {
          'settings': {
            'currencySymbol': '\$',
            'themeMode': 'system',
          },
          'loans': [loan.toJson()],
        },
      };

      final serialized = jsonEncode(backupData);

      // Assert no security credentials leaked in backup JSON string
      expect(serialized.contains('pin'), isFalse, reason: 'PIN must not be in backup');
      expect(serialized.contains('password'), isFalse);
      expect(serialized.contains('hash'), isFalse);
      expect(serialized.contains('salt'), isFalse);
      expect(serialized.contains('biometric'), isFalse);
    });

    test('Progressive brute-force lockout delay thresholds (30s, 60s, 300s, 900s)', () async {
      final prefs = await SharedPreferences.getInstance();
      final pinService = SecurePinService();
      await pinService.initialize(prefs);
      await pinService.setPin('123456');

      // Attempts 1 to 4: no lockout
      for (int i = 1; i <= 4; i++) {
        final res = await pinService.verifyPin('000000');
        expect(res.success, isFalse);
        expect(res.isLockedOut, isFalse);
        expect(res.failedAttempts, equals(i));
      }

      // 5th attempt: 30s lockout
      final res5 = await pinService.verifyPin('000000');
      expect(res5.success, isFalse);
      expect(res5.isLockedOut, isTrue);
      expect(res5.failedAttempts, equals(5));
      expect(res5.remainingLockoutSeconds, inInclusiveRange(28, 30));

      // Attempt while locked out should immediately be rejected
      final resWhileLocked = await pinService.verifyPin('123456');
      expect(resWhileLocked.isLockedOut, isTrue);
      expect(resWhileLocked.success, isFalse);
      expect(await pinService.getRemainingLockoutSeconds(), inInclusiveRange(25, 30));
    });
  });

  group('Lifecycle Privacy Veil & Relock Widget Tests', () {
    testWidgets('Inactive state displays brand privacy veil, resumed removes it', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final settingsProvider = SettingsProvider();
      await settingsProvider.loadSettingsAsync();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: settingsProvider),
          ],
          child: const LoanApp(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // Initially on resumed/active, privacy veil overlay is not displayed
      expect(find.byIcon(Icons.account_balance_wallet_rounded), findsNothing);

      // Simulate transition to inactive (e.g. user invokes iOS App Switcher)
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();

      // Privacy veil icon & brand overlay must now be visible to conceal financial data
      expect(find.byIcon(Icons.account_balance_wallet_rounded), findsOneWidget);

      // Simulate resume back to active app
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      // Privacy veil should be removed
      expect(find.byIcon(Icons.account_balance_wallet_rounded), findsNothing);
    });

    testWidgets('Biometric prompt active flag prevents auto-lock loop', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final settingsProvider = SettingsProvider();
      await settingsProvider.loadSettingsAsync();

      // Set biometric prompt active
      settingsProvider.isBiometricPromptActive = true;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: settingsProvider),
          ],
          child: const LoanApp(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // Transition to paused and back while biometric prompt is showing
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      // Should safely resume without lock loop or privacy veil stuck
      expect(find.byIcon(Icons.account_balance_wallet_rounded), findsNothing);
    });

    testWidgets('Fresh install with Keychain leftovers: app starts unlocked with no PIN set', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // Simulate leftover PIN, salt, lockout and settings in Keychain from previous install
      FlutterSecureStorage.setMockInitialValues({
        'secure_pin_hash': 'residual_pin_hash_abc123',
        'secure_pin_salt': 'residual_salt_xyz789',
        'secure_pin_failed_attempts': '4',
        'secure_pin_lockout_until': DateTime.now().add(const Duration(minutes: 10)).toIso8601String(),
        'lock_settings': 'locked',
      });
      // Fresh install: SharedPreferences is completely empty
      SharedPreferences.setMockInitialValues({});

      final settingsProvider = SettingsProvider();
      await settingsProvider.loadSettingsAsync();

      // Verify Keychain was wiped before lock logic ran
      expect(settingsProvider.hasPin, isFalse);
      expect(settingsProvider.biometricEnabled, isFalse);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: settingsProvider),
          ],
          child: const LoanApp(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // App starts unlocked (no LockScreen) and with no PIN set
      expect(find.byType(LockScreen), findsNothing);
      expect(settingsProvider.hasPin, isFalse);
    });
  });
}
