import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/app_scaffold.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
                'Privacy Policy',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _section('1. Data Collection', 
            'Loan Tracker is designed with privacy in mind. Your financial data, loan details, and payment history are stored locally on your device and are never transmitted to our servers.'),
          _section('2. Biometric Data', 
            'If you enable Biometric Unlock, authentication is handled by the operating system (FaceID/Fingerprint). We do not have access to your biometric data.'),
          _section('3. PDF Export', 
            'When you export reports, the data is processed on-device to generate the document. You have full control over where these files are stored or shared.'),
          _section('4. Third Party Services', 
            'This app does not use third-party tracking, analytics, or advertising services. No data is sold or shared with third parties.'),
          _section('5. Contact',
            'For any questions regarding privacy, please contact us at: support@loantracker.app'),
          _section('6. Data Storage',
            'All your financial data is stored locally on your device using secure storage. We do not have access to any of your personal or financial information. You can delete all data by uninstalling the app.'),
          _section('7. Changes to This Policy',
            'We may update this privacy policy from time to time. We will notify you of any changes by posting the new policy on this page and updating the "Last Updated" date below.'),
          const SizedBox(height: 48),
          Center(
            child: Text(
              'Last Updated: March 2025',
              style: TextStyle(color: AppTheme.textLight, fontSize: 13),
            ),
          ),
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
