# setup.ps1  (Run inside your Flutter project root)
$ErrorActionPreference = "Stop"

function Ensure-Dir($p) {
  if (!(Test-Path $p)) { New-Item -ItemType Directory -Path $p | Out-Null }
}

$dirs = @(
  "lib",
  "lib/core/constants",
  "lib/core/utils",
  "lib/core/widgets",
  "lib/features/loan_calculator/presentation/pages",
  "lib/features/loan_calculator/presentation/widgets",
  "lib/features/loan_calculator/presentation/state",
  "lib/features/loan_calculator/domain/entities",
  "lib/features/loan_calculator/domain/usecases",
  "test/features/loan_calculator/domain"
)

foreach ($d in $dirs) { Ensure-Dir $d }

# --- lib/main.dart ---
@"
import 'package:flutter/material.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LoanApp());
}
"@ | Set-Content -Encoding UTF8 "lib/main.dart"

# --- lib/app.dart ---
@"
import 'package:flutter/material.dart';
import 'core/constants/app_strings.dart';
import 'features/loan_calculator/presentation/pages/loan_page.dart';

class LoanApp extends StatelessWidget {
  const LoanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const LoanPage(),
    );
  }
}
"@ | Set-Content -Encoding UTF8 "lib/app.dart"

# --- core/constants/app_strings.dart ---
@"
class AppStrings {
  static const appName = 'Loan Calculator';

  static const title = 'Loan Calculator';
  static const amount = 'Loan amount';
  static const annualRate = 'Annual interest (%)';
  static const months = 'Term (months)';

  static const monthlyPayment = 'Monthly payment';
  static const totalPayment = 'Total payment';
  static const totalInterest = 'Total interest';

  static const calculate = 'Calculate';
  static const clear = 'Clear';
}
"@ | Set-Content -Encoding UTF8 "lib/core/constants/app_strings.dart"

# --- core/utils/validators.dart ---
@"
class Validators {
  static String? positiveNumber(String? v) {
    if (v == null) return 'Required';
    final s = v.trim();
    if (s.isEmpty) return 'Required';
    final x = double.tryParse(s.replaceAll(',', '.'));
    if (x == null) return 'Invalid number';
    if (x <= 0) return 'Must be > 0';
    return null;
  }

  static String? nonNegativePercent(String? v) {
    if (v == null) return 'Required';
    final s = v.trim();
    if (s.isEmpty) return 'Required';
    final x = double.tryParse(s.replaceAll(',', '.'));
    if (x == null) return 'Invalid number';
    if (x < 0) return 'Must be ≥ 0';
    if (x > 1000) return 'Too large';
    return null;
  }

  static String? months(String? v) {
    if (v == null) return 'Required';
    final s = v.trim();
    if (s.isEmpty) return 'Required';
    final x = int.tryParse(s);
    if (x == null) return 'Invalid integer';
    if (x <= 0) return 'Must be > 0';
    if (x > 1200) return 'Too large';
    return null;
  }
}
"@ | Set-Content -Encoding UTF8 "lib/core/utils/validators.dart"

# --- core/utils/formatters.dart ---
@"
class Formatters {
  static String money(double value, {int fractionDigits = 2}) {
    // Simple formatting without intl (keeps dependencies minimal)
    return value.toStringAsFixed(fractionDigits);
  }
}
"@ | Set-Content -Encoding UTF8 "lib/core/utils/formatters.dart"

# --- core/widgets/section_card.dart ---
@"
import 'package:flutter/material.dart';

class SectionCard extends StatelessWidget {
  final Widget child;
  const SectionCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}
"@ | Set-Content -Encoding UTF8 "lib/core/widgets/section_card.dart"

# --- core/widgets/primary_button.dart ---
@"
import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const PrimaryButton({super.key, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}
"@ | Set-Content -Encoding UTF8 "lib/core/widgets/primary_button.dart"

# --- core/widgets/primary_text_field.dart ---
@"
import 'package:flutter/material.dart';

class PrimaryTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const PrimaryTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    required this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
"@ | Set-Content -Encoding UTF8 "lib/core/widgets/primary_text_field.dart"

# --- domain/entities/loan_input.dart ---
@"
class LoanInput {
  final double principal;
  final double annualRatePercent;
  final int termMonths;

  const LoanInput({
    required this.principal,
    required this.annualRatePercent,
    required this.termMonths,
  });
}
"@ | Set-Content -Encoding UTF8 "lib/features/loan_calculator/domain/entities/loan_input.dart"

# --- domain/entities/loan_result.dart ---
@"
class LoanResult {
  final double monthlyPayment;
  final double totalPayment;
  final double totalInterest;

  const LoanResult({
    required this.monthlyPayment,
    required this.totalPayment,
    required this.totalInterest,
  });
}
"@ | Set-Content -Encoding UTF8 "lib/features/loan_calculator/domain/entities/loan_result.dart"

# --- domain/usecases/calculate_loan.dart ---
@"
import '../entities/loan_input.dart';
import '../entities/loan_result.dart';

class CalculateLoan {
  LoanResult call(LoanInput input) {
    final p = input.principal;
    final n = input.termMonths;
    final annual = input.annualRatePercent;

    if (p <= 0 || n <= 0) {
      return const LoanResult(monthlyPayment: 0, totalPayment: 0, totalInterest: 0);
    }

    final r = (annual / 100.0) / 12.0; // monthly rate
    double monthly;

    if (r == 0) {
      monthly = p / n;
    } else {
      final powVal = _pow(1 + r, n);
      monthly = p * r * powVal / (powVal - 1);
    }

    final totalPayment = monthly * n;
    final totalInterest = totalPayment - p;

    return LoanResult(
      monthlyPayment: monthly,
      totalPayment: totalPayment,
      totalInterest: totalInterest,
    );
  }

  double _pow(double base, int exp) {
    var result = 1.0;
    for (var i = 0; i < exp; i++) {
      result *= base;
    }
    return result;
  }
}
"@ | Set-Content -Encoding UTF8 "lib/features/loan_calculator/domain/usecases/calculate_loan.dart"

# --- presentation/state/loan_state.dart ---
@"
import '../../domain/entities/loan_result.dart';

class LoanState {
  final bool hasResult;
  final LoanResult? result;

  const LoanState({required this.hasResult, this.result});

  factory LoanState.initial() => const LoanState(hasResult: false, result: null);

  LoanState copyWith({bool? hasResult, LoanResult? result}) {
    return LoanState(
      hasResult: hasResult ?? this.hasResult,
      result: result ?? this.result,
    );
  }
}
"@ | Set-Content -Encoding UTF8 "lib/features/loan_calculator/presentation/state/loan_state.dart"

# --- presentation/state/loan_notifier.dart ---
@"
import 'package:flutter/foundation.dart';
import '../../domain/entities/loan_input.dart';
import '../../domain/usecases/calculate_loan.dart';
import 'loan_state.dart';

class LoanNotifier extends ChangeNotifier {
  final CalculateLoan _calculateLoan;
  LoanState _state = LoanState.initial();

  LoanNotifier({CalculateLoan? calculateLoan})
      : _calculateLoan = calculateLoan ?? CalculateLoan();

  LoanState get state => _state;

  void calculate(LoanInput input) {
    final res = _calculateLoan(input);
    _state = LoanState(hasResult: true, result: res);
    notifyListeners();
  }

  void clear() {
    _state = LoanState.initial();
    notifyListeners();
  }
}
"@ | Set-Content -Encoding UTF8 "lib/features/loan_calculator/presentation/state/loan_notifier.dart"

# --- presentation/pages/loan_page.dart ---
@"
import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../state/loan_notifier.dart';
import '../widgets/loan_form.dart';
import '../widgets/results_card.dart';

class LoanPage extends StatefulWidget {
  const LoanPage({super.key});

  @override
  State<LoanPage> createState() => _LoanPageState();
}

class _LoanPageState extends State<LoanPage> {
  late final LoanNotifier notifier;

  @override
  void initState() {
    super.initState();
    notifier = LoanNotifier();
  }

  @override
  void dispose() {
    notifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          LoanForm(notifier: notifier),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: notifier,
            builder: (context, _) {
              if (!notifier.state.hasResult || notifier.state.result == null) {
                return const SizedBox.shrink();
              }
              return ResultsCard(result: notifier.state.result!);
            },
          ),
        ],
      ),
    );
  }
}
"@ | Set-Content -Encoding UTF8 "lib/features/loan_calculator/presentation/pages/loan_page.dart"

# --- presentation/widgets/loan_form.dart ---
@"
import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/primary_text_field.dart';
import '../../../../core/widgets/section_card.dart';
import '../../domain/entities/loan_input.dart';
import '../state/loan_notifier.dart';

class LoanForm extends StatefulWidget {
  final LoanNotifier notifier;
  const LoanForm({super.key, required this.notifier});

  @override
  State<LoanForm> createState() => _LoanFormState();
}

class _LoanFormState extends State<LoanForm> {
  final _formKey = GlobalKey<FormState>();

  final _amountCtrl = TextEditingController(text: '10000');
  final _rateCtrl = TextEditingController(text: '18');
  final _monthsCtrl = TextEditingController(text: '12');

  @override
  void dispose() {
    _amountCtrl.dispose();
    _rateCtrl.dispose();
    _monthsCtrl.dispose();
    super.dispose();
  }

  void _onCalculate() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final principal = double.parse(_amountCtrl.text.trim().replaceAll(',', '.'));
    final annual = double.parse(_rateCtrl.text.trim().replaceAll(',', '.'));
    final months = int.parse(_monthsCtrl.text.trim());

    widget.notifier.calculate(
      LoanInput(principal: principal, annualRatePercent: annual, termMonths: months),
    );
  }

  void _onClear() {
    widget.notifier.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            PrimaryTextField(
              controller: _amountCtrl,
              label: AppStrings.amount,
              hint: 'e.g. 10000',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: Validators.positiveNumber,
            ),
            const SizedBox(height: 12),
            PrimaryTextField(
              controller: _rateCtrl,
              label: AppStrings.annualRate,
              hint: 'e.g. 18',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: Validators.nonNegativePercent,
            ),
            const SizedBox(height: 12),
            PrimaryTextField(
              controller: _monthsCtrl,
              label: AppStrings.months,
              hint: 'e.g. 12',
              keyboardType: TextInputType.number,
              validator: Validators.months,
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: AppStrings.calculate,
              onPressed: _onCalculate,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _onClear,
              child: const Text(AppStrings.clear),
            )
          ],
        ),
      ),
    );
  }
}
"@ | Set-Content -Encoding UTF8 "lib/features/loan_calculator/presentation/widgets/loan_form.dart"

# --- presentation/widgets/results_card.dart ---
@"
import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/section_card.dart';
import '../../domain/entities/loan_result.dart';

class ResultsCard extends StatelessWidget {
  final LoanResult result;
  const ResultsCard({super.key, required this.result});

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row(AppStrings.monthlyPayment, Formatters.money(result.monthlyPayment)),
          _row(AppStrings.totalPayment, Formatters.money(result.totalPayment)),
          _row(AppStrings.totalInterest, Formatters.money(result.totalInterest)),
        ],
      ),
    );
  }
}
"@ | Set-Content -Encoding UTF8 "lib/features/loan_calculator/presentation/widgets/results_card.dart"

# --- test/features/loan_calculator/domain/calculate_loan_test.dart ---
@"
import 'package:flutter_test/flutter_test.dart';
import 'package:loan_calculator/features/loan_calculator/domain/entities/loan_input.dart';
import 'package:loan_calculator/features/loan_calculator/domain/usecases/calculate_loan.dart';

void main() {
  test('0% interest should be principal/months', () {
    final calc = CalculateLoan();
    final r = calc(LoanInput(principal: 1200, annualRatePercent: 0, termMonths: 12));
    expect(r.monthlyPayment, closeTo(100, 1e-9));
    expect(r.totalInterest, closeTo(0, 1e-9));
  });

  test('basic sanity check', () {
    final calc = CalculateLoan();
    final r = calc(LoanInput(principal: 10000, annualRatePercent: 18, termMonths: 12));
    expect(r.monthlyPayment, greaterThan(0));
    expect(r.totalPayment, greaterThan(10000));
    expect(r.totalInterest, greaterThan(0));
  });
}
"@ | Set-Content -Encoding UTF8 "test/features/loan_calculator/domain/calculate_loan_test.dart"

Write-Host "✅ Structure + code generated."
Write-Host "Next: run 'flutter test' then 'flutter run'."
