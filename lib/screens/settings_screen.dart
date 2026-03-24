import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/app_scaffold.dart';
import '../core/widgets/animated_card.dart';
import '../providers/settings_provider.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/pdf_service.dart';
import '../services/csv_export_service.dart';
import '../models/loan.dart';
import '../core/constants/loan_icons.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';
import 'pin_entry_screen.dart';

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

          const SizedBox(height: 28),
          _sectionHeader('DATA EXPORT'),
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
                            activeColor: AppTheme.primary,
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
              activeColor: AppTheme.primary,
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
                  if (settings.pin == null) {
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
                }
                await settings.setBiometricEnabled(value);
              },
            ),
          ),
          // PIN Setup (only show if biometrics enabled and PIN exists)
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
                settings.pin != null ? 'PIN is set' : 'Set a backup PIN',
                style: TextStyle(fontSize: 12, color: AppTheme.textLight),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (settings.pin != null)
                    TextButton(
                      onPressed: () async {
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
                if (settings.pin == null) {
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
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsOfServiceScreen())),
            child: Text(
              'Terms of Service',
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
              color: AppTheme.textLight.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
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
      final fileName = 'loan_tracker_export_${DateTime.now().millisecondsSinceEpoch}';

      String filePath;
      if (kIsWeb) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Web export coming soon')),
        );
        return;
      } else {
        final directory = await getTemporaryDirectory();
        filePath = '${directory.path}/$fileName.csv';
        final file = File(filePath);
        await file.writeAsString(csvContent);
      }

      if (context.mounted) {
        await Share.shareXFiles(
          [XFile(filePath)],
          text: 'Loan Tracker Export',
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
