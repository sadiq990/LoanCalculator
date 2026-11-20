import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants/app_links.dart';
import '../core/constants/feature_flags.dart';
import '../core/constants/app_disclaimers.dart';
import '../services/backup_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/app_scaffold.dart';
import '../core/widgets/animated_card.dart';
import '../providers/settings_provider.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/pdf_service.dart';
import '../services/csv_export_service.dart';
import '../core/utils/file_exporter.dart';
import '../models/loan.dart';
import '../core/constants/loan_icons.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';
import 'pin_entry_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _dismissedNote = false;

  @override
  void initState() {
    super.initState();
    _loadNoteState();
  }

  Future<void> _loadNoteState() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _dismissedNote = prefs.getBool('dismissed_local_storage_note') ?? false;
      });
    }
  }

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
          const SizedBox(height: 20),

          // One-time dismissible local-only privacy note
          if (!_dismissedNote) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.shield_outlined, color: AppTheme.primary, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Privacy Notice: Local-Only Storage',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'All data is stored solely on this device. Create regular backups to safeguard your loan records if you change devices.',
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.35),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      setState(() => _dismissedNote = true);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('dismissed_local_storage_note', true);
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Icon(Icons.close_rounded, size: 18, color: AppTheme.textLight),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          _sectionHeader('APPEARANCE'),
          _buildThemeSelector(context, settings),

          const SizedBox(height: 28),
          _sectionHeader('PREFERENCES'),
          _buildCurrencySelector(context, settings),
          const SizedBox(height: 12),
          _buildOpenAppOnSelector(context, settings),
          if (FeatureFlags.kRemindersEnabled) ...[
            const SizedBox(height: 12),
            _buildReminderSelector(context, settings),
          ],

          if (!kIsWeb) ...[
            const SizedBox(height: 28),
            _sectionHeader('SECURITY'),
            _buildBiometricToggle(context, settings),
          ],

          const SizedBox(height: 28),
          _sectionHeader('DATA & BACKUP'),
          _buildExportSection(context, settings),

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

  Widget _buildOpenAppOnSelector(BuildContext context, SettingsProvider settings) {
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
          child: const Icon(Icons.launch_rounded, color: AppTheme.primary, size: 20),
        ),
        title: const Text('Open app on',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Text(
          settings.openAppOn.label,
          style: TextStyle(fontSize: 12, color: AppTheme.textLight),
        ),
        trailing: Icon(Icons.chevron_right_rounded, color: AppTheme.textLight),
        onTap: () {
          HapticFeedback.selectionClick();
          showModalBottomSheet(
            context: context,
            backgroundColor: Theme.of(context).cardColor,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
            ),
            builder: (ctx) {
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Text(
                          'Open app on',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      const Divider(),
                      ...OpenAppOn.values.map((option) {
                        final isSelected = settings.openAppOn == option;
                        return ListTile(
                          title: Text(
                            option.label,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_rounded, color: AppTheme.primary)
                              : null,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            settings.setOpenAppOn(option);
                            Navigator.pop(ctx);
                          },
                        );
                      }),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildReminderSelector(BuildContext context, SettingsProvider settings) {
    final storage = Provider.of<StorageService>(context, listen: false);

    return FutureBuilder<List<Loan>>(
      future: storage.getLoans(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        
        final activeLoans = snapshot.data!.where((l) => !l.isPaidOff).toList();
        if (activeLoans.isEmpty) {
          return AnimatedCard(
            child: ListTile(
              leading: Icon(Icons.notifications_off_rounded, color: AppTheme.textLight),
              title: Text('No active loans for reminders', style: TextStyle(color: AppTheme.textLight)),
            ),
          );
        }

        return AnimatedCard(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text('Loan Reminders', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textSecondary)),
              ),
              ...activeLoans.map((loan) {
                final days = settings.loanReminderDays[loan.id];
                final isEnabled = days != null;
                
                return Column(
                  children: [
                    if (activeLoans.indexOf(loan) > 0)
                      Divider(height: 1, indent: 16, endIndent: 16, color: AppTheme.divider),
                    ListTile(
                      leading: buildGradientIcon(loan.iconId, size: 32),
                      title: Text(loan.name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.textPrimary)),
                      subtitle: isEnabled 
                        ? Text('Remind $days days before', style: TextStyle(fontSize: 12, color: AppTheme.primary)) 
                        : Text('Off', style: TextStyle(fontSize: 12, color: AppTheme.textLight)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isEnabled)
                            IconButton(
                              icon: const Icon(Icons.edit_calendar_rounded, size: 20),
                              color: AppTheme.primary,
                              onPressed: () async {
                                final result = await _pickReminderDays(context, days);
                                if (result != null) {
                                  settings.setReminderDays(loan.id, result);
                                }
                              },
                            ),
                          Switch.adaptive(
                            value: isEnabled,
                            activeThumbColor: AppTheme.primary,
                            onChanged: (val) {
                              if (val) {
                                settings.setReminderDays(loan.id, 5); // default 5
                              } else {
                                settings.removeReminder(loan.id);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Future<int?> _pickReminderDays(BuildContext context, int currentDays) {
    int selected = currentDays;
    return showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          title: Text('Days Before Payment', style: TextStyle(color: AppTheme.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$selected days', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primary)),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppTheme.primary,
                  inactiveTrackColor: AppTheme.surfaceLight,
                  thumbColor: AppTheme.primary,
                  trackHeight: 4,
                ),
                child: Slider(
                  value: selected.toDouble(),
                  min: 1,
                  max: 14,
                  divisions: 13,
                  onChanged: (v) => setState(() => selected = v.toInt()),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: Text('Cancel', style: TextStyle(color: AppTheme.textLight))
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, selected), 
              child: const Text('Save', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold))
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBiometricToggle(BuildContext context, SettingsProvider settings) {
    final authService = AuthService();
    return AnimatedCard(
      child: Column(
        children: [
          // Biometric Toggle
          ListTile(
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
              activeThumbColor: AppTheme.primary,
              onChanged: (value) async {
                HapticFeedback.selectionClick();
                if (value) {
                  final isAvailable = await authService.isAvailable;
                  if (!context.mounted) return;
                  if (!isAvailable) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Biometric authentication is not available on this device.'),
                        backgroundColor: AppTheme.error,
                      ),
                    );
                    return;
                  }
                  // If enabling and no PIN set, prompt to create PIN
                  if (!settings.hasPin) {
                    final bool? pinCreated = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => PinEntryScreen(
                          onSuccess: () => Navigator.pop(context, true),
                          isSetupMode: true,
                          onPinSet: (pin) => settings.setPin(pin),
                        ),
                      ),
                    );
                    if (pinCreated != true) return;
                  }
                  await settings.setBiometricEnabled(true);
                } else {
                  // Disabling lock requires current PIN or successful biometric check
                  final authenticated = await _authenticateSecurityAction(context, settings);
                  if (authenticated) {
                    await settings.setBiometricEnabled(false);
                  }
                }
              },
            ),
          ),
          // PIN Setup & Auto-lock timeout (only show if biometrics enabled)
          if (settings.biometricEnabled) ...[
            Divider(height: 1, indent: 16, endIndent: 16, color: AppTheme.divider),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: const Icon(Icons.pin_rounded, color: AppTheme.primary, size: 20),
              ),
              title: const Text('Backup PIN',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              subtitle: Text(
                settings.hasPin ? 'PIN is set' : 'Set a backup PIN',
                style: TextStyle(fontSize: 12, color: AppTheme.textLight),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (settings.hasPin)
                    TextButton(
                      onPressed: () async {
                        // Changing PIN requires current PIN or biometric check first
                        final authenticated = await _authenticateSecurityAction(context, settings);
                        if (!authenticated || !context.mounted) return;

                        final bool? resetPin = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => PinEntryScreen(
                              onSuccess: () => Navigator.pop(context, true),
                              isSetupMode: true,
                              onPinSet: (pin) => settings.setPin(pin),
                            ),
                          ),
                        );
                        if (resetPin == true) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('PIN updated successfully'),
                                backgroundColor: AppTheme.success,
                              ),
                            );
                          }
                        }
                      },
                      child: const Text('Change'),
                    ),
                  Icon(Icons.chevron_right_rounded, color: AppTheme.textLight),
                ],
              ),
              onTap: () async {
                if (!settings.hasPin) {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PinEntryScreen(
                        onSuccess: () => Navigator.pop(context),
                        isSetupMode: true,
                        onPinSet: (pin) => settings.setPin(pin),
                      ),
                    ),
                  );
                }
              },
            ),
            Divider(height: 1, indent: 16, endIndent: 16, color: AppTheme.divider),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: const Icon(Icons.timer_outlined, color: AppTheme.accent, size: 20),
              ),
              title: const Text('Require Unlock',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              subtitle: Text(settings.autoLockTimeout.label,
                  style: TextStyle(fontSize: 12, color: AppTheme.textLight)),
              trailing: PopupMenuButton<AutoLockTimeout>(
                initialValue: settings.autoLockTimeout,
                onSelected: (timeout) => settings.setAutoLockTimeout(timeout),
                itemBuilder: (context) => AutoLockTimeout.values.map((t) => PopupMenuItem(
                  value: t,
                  child: Text(t.label),
                )).toList(),
              ),
            ),
          ],
        ],
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
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final version = snapshot.hasData
                  ? 'Version ${snapshot.data!.version} (build ${snapshot.data!.buildNumber})'
                  : 'Version 1.0.0 (build 1)';
              return Text(
                version,
                style: TextStyle(
                  color: AppTheme.textLight,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => _openExternalUrl(
              context,
              AppLinks.privacyPolicyUrl,
              onFallback: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
            ),
            child: Text(
              'Privacy Policy',
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => _openExternalUrl(
              context,
              AppLinks.termsUrl,
              onFallback: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsOfServiceScreen())),
            ),
            child: Text(
              'Terms of Service',
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => _openSupport(context),
            child: Text(
              'Support & Contact',
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              AppDisclaimers.financialDisclaimer,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textLight.withValues(alpha: 0.7),
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Loan Tracker',
            style: TextStyle(
              color: AppTheme.textLight.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openExternalUrl(BuildContext context, String urlString, {VoidCallback? onFallback}) async {
    final uri = Uri.parse(urlString);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && onFallback != null) {
        onFallback();
      }
    } catch (_) {
      if (onFallback != null) {
        onFallback();
      }
    }
  }

  Future<void> _openSupport(BuildContext context) async {
    final emailUri = Uri(
      scheme: 'mailto',
      path: AppLinks.supportEmail,
      queryParameters: {'subject': 'Loan Tracker Support'},
    );
    try {
      final launched = await launchUrl(emailUri);
      if (!launched) {
        await launchUrl(Uri.parse(AppLinks.supportUrl), mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      try {
        await launchUrl(Uri.parse(AppLinks.supportUrl), mode: LaunchMode.externalApplication);
      } catch (_) {}
    }
  }

  Future<bool> _authenticateSecurityAction(BuildContext context, SettingsProvider settings) async {
    final authService = AuthService();
    settings.isBiometricPromptActive = true;
    try {
      final result = await authService.authenticateWithDetails();
      if (result.isSuccess) return true;
    } finally {
      settings.isBiometricPromptActive = false;
    }

    if (!context.mounted) return false;
    if (!settings.hasPin) return false;

    final verified = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PinEntryScreen(
          onSuccess: () => Navigator.pop(context, true),
        ),
      ),
    );
    return verified == true;
  }

  Widget _buildExportSection(BuildContext context, SettingsProvider settings) {
    return FutureBuilder<List<Loan>>(
      future: Provider.of<StorageService>(context, listen: false).getLoans(),
      builder: (context, snapshot) {
        final hasLoans = snapshot.hasData && snapshot.data!.isNotEmpty;

        return AnimatedCard(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              // Export Backup (JSON)
              ListTile(
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
                  child: const Icon(Icons.cloud_upload_outlined, color: AppTheme.primary, size: 20),
                ),
                title: const Text('Export Backup (JSON)',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                subtitle: Text(
                  'Full backup for safe keeping & device transfer',
                  style: TextStyle(fontSize: 12, color: AppTheme.textLight),
                ),
                trailing: Icon(Icons.chevron_right_rounded, color: AppTheme.textLight),
                onTap: () async {
                  try {
                    await BackupService.exportBackup(
                      context: context,
                      loans: snapshot.data ?? [],
                      settings: settings,
                    );
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Backup export failed: $e'), backgroundColor: AppTheme.error),
                      );
                    }
                  }
                },
              ),
              Divider(height: 1, indent: 16, endIndent: 16, color: AppTheme.divider),
              // Import Backup (JSON)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.accent.withValues(alpha: 0.2),
                        AppTheme.accent.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: const Icon(Icons.cloud_download_outlined, color: AppTheme.accent, size: 20),
                ),
                title: const Text('Import Backup (JSON)',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                subtitle: Text(
                  'Restore records with Merge or Replace options',
                  style: TextStyle(fontSize: 12, color: AppTheme.textLight),
                ),
                trailing: Icon(Icons.chevron_right_rounded, color: AppTheme.textLight),
                onTap: () => _handleImportBackup(context, settings),
              ),
              Divider(height: 1, indent: 16, endIndent: 16, color: AppTheme.divider),
              // Export All Loans PDF
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.error.withValues(alpha: 0.2),
                        AppTheme.error.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: const Icon(Icons.picture_as_pdf_rounded, color: AppTheme.error, size: 20),
                ),
                title: const Text('Export All Loans (PDF)',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                subtitle: Text(
                  hasLoans ? '${snapshot.data!.length} loans' : 'No loans to export',
                  style: TextStyle(fontSize: 12, color: AppTheme.textLight),
                ),
                trailing: Icon(Icons.chevron_right_rounded, color: AppTheme.textLight),
                enabled: hasLoans,
                onTap: hasLoans
                    ? () => _showExportDialog(context, settings, snapshot.data!)
                    : null,
              ),
              Divider(height: 1, indent: 16, endIndent: 16, color: AppTheme.divider),
              // Export CSV
              ListTile(
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
                  child: const Icon(Icons.table_chart_rounded, color: AppTheme.success, size: 20),
                ),
                title: const Text('Export All Loans (CSV)',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                subtitle: Text(
                  'For Excel / Spreadsheets',
                  style: TextStyle(fontSize: 12, color: AppTheme.textLight),
                ),
                trailing: Icon(Icons.chevron_right_rounded, color: AppTheme.textLight),
                enabled: hasLoans,
                onTap: hasLoans
                    ? () => _exportCsv(context, settings, snapshot.data!)
                    : null,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleImportBackup(BuildContext context, SettingsProvider settings) async {
    try {
      final preview = await BackupService.pickAndValidateBackup();
      if (preview == null || !context.mounted) return;

      final storage = Provider.of<StorageService>(context, listen: false);

      showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
          title: const Text('Restore Backup', style: TextStyle(fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${preview.loans.length} loan(s) found in backup.'),
              const SizedBox(height: 8),
              Text(
                'Exported: ${DateFormat('yyyy-MM-dd HH:mm').format(preview.exportedAt.toLocal())}',
                style: TextStyle(fontSize: 12, color: AppTheme.textLight),
              ),
              const SizedBox(height: 16),
              const Text(
                'Select how you want to restore:\n\n'
                '• Merge: Retain existing loans and add/update imported loans.\n'
                '• Replace: Clear existing loans and restore backup.',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            OutlinedButton(
              onPressed: () async {
                Navigator.pop(dialogCtx);
                await BackupService.restoreBackup(
                  preview: preview,
                  storage: storage,
                  settings: settings,
                  replaceExisting: false,
                );
                if (context.mounted) {
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Merged ${preview.loans.length} loan(s) successfully.'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                }
              },
              child: const Text('Merge'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(dialogCtx);
                await BackupService.restoreBackup(
                  preview: preview,
                  storage: storage,
                  settings: settings,
                  replaceExisting: true,
                );
                if (context.mounted) {
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Replaced all loans with ${preview.loans.length} backup loan(s).'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                }
              },
              child: const Text('Replace'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import error: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _showExportDialog(BuildContext context, SettingsProvider settings, List<Loan> loans) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
        title: Text(
          'Export Loans',
          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select a loan to export:',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            ...loans.map((loan) => ListTile(
              title: Text(loan.name),
              subtitle: Text('${loan.totalAmount.toStringAsFixed(0)} ${settings.currencySymbol}'),
              onTap: () {
                Navigator.pop(context);
                PdfService.generateLoanReport(loan, settings.currencySymbol);
              },
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppTheme.textLight)),
          ),
        ],
      ),
    );
  }

  Future<void> _exportCsv(BuildContext context, SettingsProvider settings, List<Loan> loans) async {
    try {
      final csvContent = CsvExportService.generateAllLoansCsv(loans, settings.currencySymbol);
      final fileName = 'loan_tracker_export_${DateTime.now().millisecondsSinceEpoch}.csv';

      await FileExporter.exportString(
        content: csvContent,
        fileName: fileName,
        mimeType: 'text/csv',
        subject: 'Loan Tracker Export',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All loans exported as CSV'), backgroundColor: AppTheme.success),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }
}
