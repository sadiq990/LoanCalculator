import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import '../core/theme/app_theme.dart';
import '../providers/settings_provider.dart';
import '../core/widgets/animated_card.dart';
import '../services/auth_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Settings'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionHeader('Appearance'),
          _buildThemeSelector(context, settings),

          const SizedBox(height: 24),
          _buildSectionHeader('Preferences'),
          _buildCurrencySelector(context, settings),
          const SizedBox(height: 16),
          _buildReminderSelector(context, settings),
          if (!kIsWeb) ...[
            const SizedBox(height: 24), // Added SizedBox for spacing
            _buildSectionHeader('Security'),
            _buildBiometricToggle(context, settings),
          ],
          const SizedBox(height: 40),
          _buildAboutSection(), // Changed from _buildInfoSection to _buildAboutSection
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppTheme.textSecondary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context, SettingsProvider settings) {
    return AnimatedCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: RadioGroup<ThemeMode>(
        groupValue: settings.themeMode,
        onChanged: (value) {
          if (value != null) {
            settings.setThemeMode(value);
          }
        },
        child: Column(
          children: [
            RadioListTile<ThemeMode>(
              title: Text('Device System'),
              subtitle: Text('Follows system settings'),
              value: ThemeMode.system,
              activeColor: AppTheme.primary,
            ),
            Divider(height: 1, color: AppTheme.divider.withValues(alpha: 0.5)),
            RadioListTile<ThemeMode>(
              title: Text('Light Mode'),
              value: ThemeMode.light,
              activeColor: AppTheme.primary,
            ),
            Divider(height: 1, color: AppTheme.divider.withValues(alpha: 0.5)),
            RadioListTile<ThemeMode>(
              title: Text('Dark Mode'),
              value: ThemeMode.dark,
              activeColor: AppTheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencySelector(
    BuildContext context,
    SettingsProvider settings,
  ) {
    final currencies = ['₼', '\$', '€', '£', '₽'];

    return AnimatedCard(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.currency_exchange_rounded,
            color: AppTheme.primary,
          ),
        ),
        title: Text('Currency Symbol'),
        trailing: DropdownButton<String>(
          value: settings.currencySymbol,
          underline: const SizedBox(),
          items: currencies
              .map(
                (c) => DropdownMenuItem(
                  value: c,
                  child: Text(
                    c,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (val) {
            if (val != null) settings.setCurrency(val);
          },
        ),
      ),
    );
  }

  Widget _buildReminderSelector(
    BuildContext context,
    SettingsProvider settings,
  ) {
    final time = settings.reminderTime;
    final formattedTime =
        '${time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour)}:00 ${time.hour >= 12 ? 'PM' : 'AM'}';

    return AnimatedCard(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.notifications_active_rounded,
            color: AppTheme.warning,
          ),
        ),
        title: Text('Daily Reminder'),
        subtitle: Text('When to verify payments'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Text(
            formattedTime,
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        onTap: () async {
          // Simple hour picker
          final newTime = await showTimePicker(
            context: context,
            initialTime: time,
          );
          if (newTime != null) {
            settings.setReminderTime(newTime);
          }
        },
      ),
    );
  }

  Widget _buildBiometricToggle(
    BuildContext context,
    SettingsProvider settings,
  ) {
    final authService = AuthService();
    return AnimatedCard(
      child: SwitchListTile(
        title: Text(
          'Biometric Unlock',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('Use FaceID/TouchID to open app'),
        value: settings.biometricEnabled,
        onChanged: (value) async {
          if (value) {
            final isAvailable = await authService.isAvailable;
            if (!context.mounted) return;
            if (!isAvailable) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Biometric authentication is not available on this device.',
                  ),
                  backgroundColor: AppTheme.error,
                ),
              );
              return;
            }
          }
          await settings.setBiometricEnabled(value);
        },
      ),
    );
  }

  Widget _buildAboutSection() {
    return AnimatedCard(
      child: Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        child: Column(
          children: [
            Icon(
              Icons.rocket_launch_rounded,
              size: 48,
              color: AppTheme.textLight,
            ),
            const SizedBox(height: 16),
            Text(
              'Loan Tracker v1.1.0',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Made with Flutter',
              style: TextStyle(
                color: AppTheme.textLight.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


