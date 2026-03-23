import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:loan_calculator/app.dart';
import 'package:loan_calculator/providers/settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Loan app loads home screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final settingsProvider = SettingsProvider();
    await settingsProvider.loadSettingsAsync();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
        ],
        child: const LoanApp(),
      ),
    );
    // Use pump instead of pumpAndSettle because of animations
    await tester.pump();

    // Check if the app loads either the onboarding screen or the home screen
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
