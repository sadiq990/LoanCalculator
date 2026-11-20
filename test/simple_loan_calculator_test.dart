import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:loan_calculator/app.dart';
import 'package:loan_calculator/core/theme/app_theme.dart';
import 'package:loan_calculator/core/utils/simple_loan_calculator.dart';
import 'package:loan_calculator/models/loan.dart';
import 'package:loan_calculator/models/payment.dart';
import 'package:loan_calculator/providers/settings_provider.dart';
import 'package:loan_calculator/screens/add_loan_screen.dart';
import 'package:loan_calculator/screens/calculator_screen.dart';
import 'package:loan_calculator/services/storage_service.dart';

class FakeStorageService extends StorageService {
  final List<Loan> _fakeLoans;
  FakeStorageService([List<Loan>? initialLoans]) : _fakeLoans = initialLoans ?? [];

  @override
  Future<void> init() async {}

  @override
  Future<List<Loan>> getLoans() async => List.unmodifiable(_fakeLoans);

  @override
  Future<void> addLoan(Loan loan) async {
    _fakeLoans.add(loan);
    notifyLoanChange();
  }

  @override
  Future<void> updateLoan(Loan updatedLoan) async {
    final idx = _fakeLoans.indexWhere((l) => l.id == updatedLoan.id);
    if (idx != -1) _fakeLoans[idx] = updatedLoan;
    notifyLoanChange();
  }

  @override
  Future<void> deleteLoan(String loanId) async {
    _fakeLoans.removeWhere((l) => l.id == loanId);
    notifyLoanChange();
  }

  @override
  Future<Loan?> addPayment(String loanId, Payment payment) async {
    final idx = _fakeLoans.indexWhere((l) => l.id == loanId);
    if (idx != -1) {
      final existing = _fakeLoans[idx];
      final updatedPayments = [...existing.payments, payment];
      final updatedLoan = existing.copyWith(payments: updatedPayments);
      _fakeLoans[idx] = updatedLoan;
      notifyLoanChange();
      return updatedLoan;
    }
    return null;
  }
}

Widget createTestApp({
  required SettingsProvider settings,
  required StorageService storage,
  Widget? home,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<SettingsProvider>.value(value: settings),
      Provider<StorageService>.value(value: storage),
    ],
    child: MaterialApp(
      theme: AppTheme.buildLightTheme(),
      home: home ?? const MainShell(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Simple Loan Calculator Tests (Task 6d)', () {
    // Test 1: 10,000 at 9% for 12 months
    test('(1) 10,000 at 9% for 12 months: monthly ~874.51, interest ~494.1, total repaid ~10,494.1', () {
      final res = SimpleLoanCalculator.calculate(
        amount: 10000,
        annualRate: 9,
        termMonths: 12,
      );
      expect(res, isNotNull);
      expect((res!.monthlyPayment - 874.51).abs(), lessThan(0.1));
      expect((res.totalInterest - 494.1).abs(), lessThan(0.2));
      expect((res.totalRepaid - 10494.1).abs(), lessThan(0.2));
      expect(res.plainSentence((v) => '\$$v'), contains('You borrow \$10000.0 and repay'));
      expect(res.interestSummary(), contains('Interest is'));
    });

    // Test 2: 24,000 at 5% for 48 months = 552.70
    test('(2) 24,000 at 5% for 48 months = 552.70', () {
      final res = SimpleLoanCalculator.calculate(
        amount: 24000,
        annualRate: 5,
        termMonths: 48,
      );
      expect(res, isNotNull);
      expect(res!.monthlyPayment, 552.70);
    });

    // Test 3: 300,000 at 6% for 360 months = 1,798.65
    test('(3) 300,000 at 6% for 360 months = 1,798.65', () {
      final res = SimpleLoanCalculator.calculate(
        amount: 300000,
        annualRate: 6,
        termMonths: 360,
      );
      expect(res, isNotNull);
      expect(res!.monthlyPayment, 1798.65);
    });

    // Test 4: 10,000 at 0% for 10 months = 1,000.00 with zero interest
    test('(4) 10,000 at 0% for 10 months = 1,000.00 with zero interest', () {
      final res = SimpleLoanCalculator.calculate(
        amount: 10000,
        annualRate: 0,
        termMonths: 10,
      );
      expect(res, isNotNull);
      expect(res!.monthlyPayment, 1000.00);
      expect(res.totalInterest, 0.0);
      expect(res.totalRepaid, 10000.00);
    });

    // Test 5: 1-month term
    test('(5) 1-month term executes cleanly', () {
      final res = SimpleLoanCalculator.calculate(
        amount: 1200,
        annualRate: 12,
        termMonths: 1,
      );
      expect(res, isNotNull);
      expect(res!.schedule.length, 1);
      expect(res.monthlyPayment, 1212.00);
      expect(res.totalInterest, 12.00);
      expect(res.totalRepaid, 1212.00);
    });

    // Test 6: Invalid inputs return validation errors, never NaN or Infinity
    test('(6) invalid inputs return validation errors, never NaN or Infinity', () {
      // Amount validation
      final vEmpty = SimpleLoanCalculator.validate(amountText: '', rateText: '5', termText: '12');
      expect(vEmpty.isValid, false);
      expect(vEmpty.amountError, isNotNull);

      final vZeroAmount = SimpleLoanCalculator.validate(amountText: '0', rateText: '5', termText: '12');
      expect(vZeroAmount.isValid, false);
      expect(vZeroAmount.amountError, isNotNull);

      final vNegAmount = SimpleLoanCalculator.validate(amountText: '-500', rateText: '5', termText: '12');
      expect(vNegAmount.isValid, false);
      expect(vNegAmount.amountError, isNotNull);

      final vExceedAmount = SimpleLoanCalculator.validate(amountText: '100000001', rateText: '5', termText: '12');
      expect(vExceedAmount.isValid, false);
      expect(vExceedAmount.amountError, isNotNull);

      // Rate validation
      final vNegRate = SimpleLoanCalculator.validate(amountText: '1000', rateText: '-1', termText: '12');
      expect(vNegRate.isValid, false);
      expect(vNegRate.rateError, isNotNull);

      final vExceedRate = SimpleLoanCalculator.validate(amountText: '1000', rateText: '100.1', termText: '12');
      expect(vExceedRate.isValid, false);
      expect(vExceedRate.rateError, isNotNull);

      // Term validation
      final vZeroTerm = SimpleLoanCalculator.validate(amountText: '1000', rateText: '5', termText: '0');
      expect(vZeroTerm.isValid, false);
      expect(vZeroTerm.termError, isNotNull);

      final vExceedTermMonths = SimpleLoanCalculator.validate(amountText: '1000', rateText: '5', termText: '601', isYears: false);
      expect(vExceedTermMonths.isValid, false);
      expect(vExceedTermMonths.termError, isNotNull);

      final vExceedTermYears = SimpleLoanCalculator.validate(amountText: '1000', rateText: '5', termText: '51', isYears: true);
      expect(vExceedTermYears.isValid, false);
      expect(vExceedTermYears.termError, isNotNull);

      // Calculate on boundary or invalid values never throws NaN or Infinity
      final calcZero = SimpleLoanCalculator.calculate(amount: 0, annualRate: 5, termMonths: 12);
      expect(calcZero, isNull);

      final calcNegRate = SimpleLoanCalculator.calculate(amount: 1000, annualRate: -1, termMonths: 12);
      expect(calcNegRate, isNull);

      final calcOverTerm = SimpleLoanCalculator.calculate(amount: 1000, annualRate: 5, termMonths: 601);
      expect(calcOverTerm, isNull);
    });

    // Test 7: The calculator's numbers equal the numbers of a saved loan with identical parameters
    test('(7) the calculator numbers equal the numbers of a saved loan with identical parameters', () {
      final savedLoan = Loan(
        id: 'saved-loan-compare-test',
        name: 'Car Loan',
        totalAmount: 18500,
        interestRate: 6.75,
        termMonths: 36,
        paymentDay: 1,
        createdAt: DateTime.now(),
      );

      final calcRes = SimpleLoanCalculator.calculate(
        amount: 18500,
        annualRate: 6.75,
        termMonths: 36,
      )!;

      expect(calcRes.monthlyPayment, (savedLoan.monthlyRequired * 100).round() / 100.0);
      final schedule = savedLoan.getOriginalAmortizationSchedule();
      expect(calcRes.schedule.length, schedule.length);
      final totalInterest = (schedule.fold<double>(0.0, (s, e) => s + e.interest) * 100).round() / 100.0;
      expect(calcRes.totalInterest, totalInterest);
      final totalRepaid = (schedule.fold<double>(0.0, (s, e) => s + e.payment) * 100).round() / 100.0;
      expect(calcRes.totalRepaid, totalRepaid);
    });

    // Test 8: Widget test: typing values shows results live
    testWidgets('(8) typing values shows results live', (tester) async {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
      final settings = SettingsProvider();
      await settings.loadSettingsAsync();
      final storage = FakeStorageService();

      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(createTestApp(
        settings: settings,
        storage: storage,
        home: const CalculatorScreen(),
      ));
      await tester.pumpAndSettle();

      // Enter inputs
      await tester.enterText(find.byKey(const Key('calc_amount_input')), '10000');
      await tester.enterText(find.byKey(const Key('calc_rate_input')), '9');
      await tester.enterText(find.byKey(const Key('calc_term_input')), '12');

      // Debounce is 150ms
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      // Verify results are displayed live
      expect(find.textContaining('874.51'), findsWidgets);
      expect(find.text('Monthly payment'), findsOneWidget);
      expect(find.text('Extra interest'), findsOneWidget);
    });

    // Test 9: Widget test: switching tabs preserves the typed inputs
    testWidgets('(9) switching tabs preserves typed inputs (IndexedStack)', (tester) async {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
      final settings = SettingsProvider();
      await settings.loadSettingsAsync();
      final storage = FakeStorageService();

      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(createTestApp(
        settings: settings,
        storage: storage,
        home: const MainShell(),
      ));
      await tester.pumpAndSettle();

      // Switch to calculator tab
      await tester.tap(find.byKey(const Key('tab_calculator')));
      await tester.pumpAndSettle();

      // Enter inputs
      await tester.enterText(find.byKey(const Key('calc_amount_input')), '25000');
      await tester.enterText(find.byKey(const Key('calc_rate_input')), '6.5');
      await tester.enterText(find.byKey(const Key('calc_term_input')), '36');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      // Switch to Home tab
      await tester.tap(find.byKey(const Key('tab_home')));
      await tester.pumpAndSettle();

      // Switch back to Calculator tab
      await tester.tap(find.byKey(const Key('tab_calculator')));
      await tester.pumpAndSettle();

      // Verify controllers preserved their text
      final amountField = tester.widget<TextField>(find.byKey(const Key('calc_amount_input')));
      expect(amountField.controller?.text, '25000');
      final rateField = tester.widget<TextField>(find.byKey(const Key('calc_rate_input')));
      expect(rateField.controller?.text, '6.5');
      final termField = tester.widget<TextField>(find.byKey(const Key('calc_term_input')));
      expect(termField.controller?.text, '36');

      // Results card is still visible
      expect(find.text('Monthly payment'), findsOneWidget);
    });

    // Test 10: Widget test: the "Your current loans" strip is hidden with no loans, visible with loans and shows correct sums, and tapping it switches tabs
    testWidgets('(10) "Your current loans" strip is hidden with no loans, visible with loans, and tapping switches tabs', (tester) async {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
      final settings = SettingsProvider();
      await settings.loadSettingsAsync();

      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // Part A: 0 loans -> strip is hidden
      final emptyStorage = FakeStorageService();
      await tester.pumpWidget(createTestApp(
        settings: settings,
        storage: emptyStorage,
        home: const CalculatorScreen(),
      ));
      await tester.pumpAndSettle();
      expect(find.text('YOUR CURRENT LOANS'), findsNothing);

      // Part B: with active loans -> strip is visible and shows correct values
      final testLoan = Loan(
        id: 'test-strip-loan-1',
        name: 'Auto Loan',
        totalAmount: 12000,
        interestRate: 6.0,
        termMonths: 24,
        paymentDay: 1,
        createdAt: DateTime.now(),
      );
      final filledStorage = FakeStorageService([testLoan]);

      await tester.pumpWidget(createTestApp(
        settings: settings,
        storage: filledStorage,
        home: const MainShell(),
      ));
      await tester.pumpAndSettle();

      // Select calculator tab
      await tester.tap(find.byKey(const Key('tab_calculator')));
      await tester.pumpAndSettle();

      expect(find.text('YOUR CURRENT LOANS'), findsOneWidget);

      // Tapping strip switches to Home tab
      await tester.tap(find.text('YOUR CURRENT LOANS'));
      await tester.pumpAndSettle();

      // Verify Home tab is now shown with the loan name
      expect(find.text('Auto Loan'), findsWidgets);
    });

    // Test 11: "Save as loan" opens AddLoanScreen with prefilled values
    testWidgets('(11) "Save as loan" opens AddLoanScreen with prefilled values', (tester) async {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
      final settings = SettingsProvider();
      await settings.loadSettingsAsync();
      final storage = FakeStorageService();

      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(createTestApp(
        settings: settings,
        storage: storage,
        home: const CalculatorScreen(),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('calc_amount_input')), '15000');
      await tester.enterText(find.byKey(const Key('calc_rate_input')), '7.5');
      await tester.enterText(find.byKey(const Key('calc_term_input')), '24');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      final saveButton = find.byKey(const Key('calc_save_as_loan_button'));
      expect(saveButton, findsOneWidget);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // AddLoanScreen is pushed
      expect(find.byType(AddLoanScreen), findsOneWidget);
      final addScreen = tester.widget<AddLoanScreen>(find.byType(AddLoanScreen));
      expect(addScreen.initialAmount, 15000.0);
      expect(addScreen.initialRate, 7.5);
      expect(addScreen.initialTermMonths, 24);
    });

    // Test 12: The "Open app on" setting is respected, including the fresh-install default
    testWidgets('(12) the "Open app on" setting is respected, including fresh-install default', (tester) async {
      // 12a: Fresh install with no loans -> starts on Calculator (tab 1)
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
      final settingsFresh = SettingsProvider();
      await settingsFresh.loadSettingsAsync();
      expect(settingsFresh.openAppOn, OpenAppOn.lastUsed);
      expect(settingsFresh.determineInitialTab(hasLoans: false), 1); // Calculator

      // 12b: Open app on = My Loans -> starts on tab 0 (Home)
      await settingsFresh.setOpenAppOn(OpenAppOn.myLoans);
      expect(settingsFresh.determineInitialTab(hasLoans: false), 0);
      expect(settingsFresh.determineInitialTab(hasLoans: true), 0);

      // 12c: Open app on = Calculator -> starts on tab 1
      await settingsFresh.setOpenAppOn(OpenAppOn.calculator);
      expect(settingsFresh.determineInitialTab(hasLoans: false), 1);
      expect(settingsFresh.determineInitialTab(hasLoans: true), 1);

      // 12d: Open app on = Last used with lastUsedTab = 0
      await settingsFresh.setOpenAppOn(OpenAppOn.lastUsed);
      await settingsFresh.setLastUsedTab(0);
      expect(settingsFresh.determineInitialTab(hasLoans: false), 0);

      // 12e: Open app on = Last used with lastUsedTab = 1
      await settingsFresh.setLastUsedTab(1);
      expect(settingsFresh.determineInitialTab(hasLoans: true), 1);

      // 12f: In MainShell widget, fresh install default mounts Calculator tab
      SharedPreferences.setMockInitialValues({});
      final settingsWidget = SettingsProvider();
      await settingsWidget.loadSettingsAsync();
      final emptyStorage = FakeStorageService();

      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(createTestApp(
        settings: settingsWidget,
        storage: emptyStorage,
        home: const MainShell(),
      ));
      await tester.pumpAndSettle();

      // Calculator screen is visible initially
      expect(find.byType(CalculatorScreen), findsOneWidget);
    });

    // Test 13: Saving a loan from Calculator switches to My Loans and immediately displays it
    testWidgets('(13) saving a loan from Calculator switches to My Loans and immediately displays it', (tester) async {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
      final settings = SettingsProvider();
      await settings.loadSettingsAsync();
      final storage = FakeStorageService();

      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(createTestApp(
        settings: settings,
        storage: storage,
        home: const MainShell(),
      ));
      await tester.pumpAndSettle();

      // Enter loan values in Calculator
      await tester.enterText(find.byKey(const Key('calc_amount_input')), '25000');
      await tester.enterText(find.byKey(const Key('calc_rate_input')), '10');
      await tester.enterText(find.byKey(const Key('calc_term_input')), '36');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      // Tap "Save as loan"
      final saveBtn = find.byKey(const Key('calc_save_as_loan_button'));
      expect(saveBtn, findsOneWidget);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // We are in AddLoanScreen
      expect(find.byType(AddLoanScreen), findsOneWidget);

      // Step 1: Enter Name and tap Continue
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.first, 'Test Auto Loan');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 2: Amount (prefilled from calculator) -> tap Continue
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 3: Term/Schedule (prefilled) -> tap Continue
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 4: Review -> tap Create Loan
      await tester.tap(find.text('Create Loan'));
      await tester.pumpAndSettle();

      // Should have popped back to shell, switched to Home tab and loan should be visible!
      expect(find.text('Test Auto Loan'), findsOneWidget);
    });
  });
}
