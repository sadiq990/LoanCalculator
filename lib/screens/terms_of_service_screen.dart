import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/app_scaffold.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const Text(
                'Terms of Service',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _section('1. Acceptance of Terms',
            'By downloading, installing, or using Loan Tracker app, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the app.'),
          _section('2. Description of Service',
            'Loan Tracker is a personal finance management tool designed to help you track and manage your loan payments, view amortization schedules, and monitor your debt payoff progress.'),
          _section('3. User Responsibilities',
            'You agree to:\n• Use the app only for lawful purposes\n• Provide accurate information when entering loan data\n• Keep your device secure to prevent unauthorized access\n• Accept responsibility for all activity under your account'),
          _section('4. Financial Information Disclaimer',
            'Loan Tracker provides calculations and estimates based on the information you input. While we strive for accuracy, we cannot guarantee the precision of all calculations. Always verify critical financial decisions with official sources or financial advisors. This app is not a substitute for professional financial advice.'),
          _section('5. Data Accuracy',
            'You are solely responsible for the accuracy of all data you enter into the app. We recommend regularly reviewing your loan statements and verifying calculations against official documents from your lender.'),
          _section('6. Privacy',
            'Your privacy is important to us. Please review our Privacy Policy, which explains how we collect, use, and protect your information. By using this app, you also agree to our Privacy Policy.'),
          _section('7. Intellectual Property',
            'All content, features, and functionality of Loan Tracker are owned by us and are protected by copyright, trademark, and other intellectual property laws.'),
          _section('8. Limitation of Liability',
            'To the maximum extent permitted by law, we shall not be liable for any indirect, incidental, special, consequential, or punitive damages resulting from your use of or inability to use the app.'),
          _section('9. Changes to Terms',
            'We reserve the right to modify these terms at any time. We will notify users of significant changes by updating the "Last Updated" date. Continued use of the app after changes constitutes acceptance of the new terms.'),
          _section('10. Termination',
            'We may terminate or suspend your access to the app at any time for any reason without prior notice. Upon termination, your right to use the app will cease immediately.'),
          _section('11. Governing Law',
            'These terms shall be governed by and construed in accordance with applicable laws, without regard to its conflict of law provisions.'),
          _section('12. Contact',
            'For any questions regarding these Terms of Service, please contact us at: support@loantracker.app'),
          const SizedBox(height: 48),
          Center(
            child: Text(
              'Last Updated: March 2025',
              style: TextStyle(color: AppTheme.textLight, fontSize: 13),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _section(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(content, style: TextStyle(fontSize: 15, color: AppTheme.textSecondary, height: 1.5)),
        ],
      ),
    );
  }
}
