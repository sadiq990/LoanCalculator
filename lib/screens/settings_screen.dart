import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/app_scaffold.dart';
import '../core/widgets/animated_card.dart';
import '../providers/settings_provider.dart';
import '../services/auth_service.dart';
import 'privacy_policy_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return AppScaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          // Header
          Text(
            'Settings',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 24),

          _sectionHeader('APPEARANCE'),
          _buildThemeSelector(context, settings),

          const SizedBox(height: 28),
          _sectionHeader('PREFERENCES'),
          _buildCurrencySelector(context, settings),
          const SizedBox(height: 12),
          _buildReminderSelector(context, settings),

          if (!kIsWeb) ...[
            const SizedBox(height: 28),
            _sectionHeader('SECURITY'),
            _buildBiometricToggle(context, settings),
          ],

          const SizedBox(height: 40),
          _buildAboutSection(context),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppTheme.textLight,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context, SettingsProvider settings) {
    return AnimatedCard(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        children: [
          _buildThemeOption(
            context, settings,
            icon: Icons.brightness_auto_rounded,
            color: AppTheme.accent,
            title: 'System',
            subtitle: 'Follows device settings',
            value: ThemeMode.system,
          ),
          Divider(height: 1, color: AppTheme.divider.withValues(alpha: 0.3),
              indent: 56),
          _buildThemeOption(
            context, settings,
            icon: Icons.light_mode_rounded,
            color: AppTheme.warning,
            title: 'Light',
            subtitle: 'Always light mode',
            value: ThemeMode.light,
          ),
          Divider(height: 1, color: AppTheme.divider.withValues(alpha: 0.3),
              indent: 56),
          _buildThemeOption(
            context, settings,
            icon: Icons.dark_mode_rounded,
            color: AppTheme.primary,
            title: 'Dark',
            subtitle: 'Always dark mode',
            value: ThemeMode.dark,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    SettingsProvider settings, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required ThemeMode value,
  }) {
    final selected = settings.themeMode == value;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.05)],
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: AppTheme.textLight)),
      trailing: AnimatedContainer(
        duration: AppTheme.animFast,
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? AppTheme.primary : Colors.transparent,
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.textLight,
            width: 2,
          ),
        ),
        child: selected
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
            : null,
      ),
      onTap: () {
        HapticFeedback.selectionClick();
        settings.setThemeMode(value);
      },
    );
  }

  Widget _buildCurrencySelector(BuildContext context, SettingsProvider settings) {
    final currencies = ['₼', '\$', '€', '£', '₽', '₺'];

    return AnimatedCard(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primary.withValues(alpha: 0.2),
                AppTheme.primary.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: const Icon(Icons.currency_exchange_rounded, color: AppTheme.primary, size: 20),
        ),
        title: const Text('Currency Symbol',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            border: Border.all(color: AppTheme.divider),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: settings.currencySymbol,
              isDense: true,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary),
              items: currencies
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (val) {
                if (val != null) settings.setCurrency(val);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReminderSelector(BuildContext context, SettingsProvider settings) {
    final time = settings.reminderTime;
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final formattedTime = '$hour:$minute $period';

    return AnimatedCard(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.warning.withValues(alpha: 0.2),
                AppTheme.warning.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: const Icon(Icons.notifications_active_rounded,
              color: AppTheme.warning, size: 20),
        ),
        title: const Text('Daily Reminder',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Text('When to verify payments',
            style: TextStyle(fontSize: 12, color: AppTheme.textLight)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Text(formattedTime,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ),
        onTap: () async {
          final newTime = await showTimePicker(context: context, initialTime: time);
          if (newTime != null) settings.setReminderTime(newTime);
        },
      ),
    );
  }

  Widget _buildBiometricToggle(BuildContext context, SettingsProvider settings) {
    final authService = AuthService();
    return AnimatedCard(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.success.withValues(alpha: 0.2),
                AppTheme.success.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: const Icon(Icons.fingerprint_rounded, color: AppTheme.success, size: 20),
        ),
        title: const Text('Biometric Unlock',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Text('Use FaceID/TouchID to open app',
            style: TextStyle(fontSize: 12, color: AppTheme.textLight)),
        trailing: Switch.adaptive(
          value: settings.biometricEnabled,
          activeColor: AppTheme.primary,
          onChanged: (value) async {
            HapticFeedback.selectionClick();
            if (value) {
              final isAvailable = await authService.isAvailable;
              if (!context.mounted) return;
              if (!isAvailable) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Biometric authentication is not available.'),
                    backgroundColor: AppTheme.error,
                  ),
                );
                return;
              }
            }
            await settings.setBiometricEnabled(value);
          },
        ),
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return AnimatedCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary.withValues(alpha: 0.15),
                  AppTheme.accent.withValues(alpha: 0.08),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.rocket_launch_rounded, size: 32,
                color: AppTheme.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Loan Tracker',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'v1.1.0',
            style: TextStyle(
              color: AppTheme.textLight,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
            child: Text(
              'Privacy Policy',
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Made by Fibontech',
            style: TextStyle(
              color: AppTheme.textLight.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
