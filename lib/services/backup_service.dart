import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../core/utils/file_exporter.dart';
import '../models/loan.dart';
import '../providers/settings_provider.dart';
import 'storage_service.dart';

class BackupPreview {
  final int schemaVersion;
  final String appVersion;
  final DateTime exportedAt;
  final List<Loan> loans;
  final String? currencySymbol;
  final ThemeMode? themeMode;

  const BackupPreview({
    required this.schemaVersion,
    required this.appVersion,
    required this.exportedAt,
    required this.loans,
    this.currencySymbol,
    this.themeMode,
  });
}

class BackupService {
  static const int currentSchemaVersion = 1;

  /// Creates and shares a JSON backup via the iOS share sheet
  static Future<void> exportBackup({
    required BuildContext context,
    required List<Loan> loans,
    required SettingsProvider settings,
  }) async {
    final packageInfo = await PackageInfo.fromPlatform();
    final now = DateTime.now().toUtc();
    final dateStr = DateFormat('yyyy-MM-dd').format(now);

    final Map<String, dynamic> backupJson = {
      'schemaVersion': currentSchemaVersion,
      'appVersion': packageInfo.version,
      'exportedAt': now.toIso8601String(),
      'data': {
        'settings': {
          'currencySymbol': settings.currencySymbol,
          'themeMode': settings.themeMode.name,
        },
        'loans': loans.map((loan) => loan.toJson()).toList(),
      },
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(backupJson);
    final fileName = 'LoanTracker-Backup-$dateStr.json';
    await FileExporter.exportString(
      content: jsonString,
      fileName: fileName,
      mimeType: 'application/json',
      subject: 'Loan Tracker Backup ($dateStr)',
    );
  }

  /// Picks a file and validates schemaVersion & structure before touching storage
  static Future<BackupPreview?> pickAndValidateBackup() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final file = result.files.single;
    String content;
    if (file.bytes != null) {
      content = utf8.decode(file.bytes!);
    } else if (file.path != null) {
      final ioFile = File(file.path!);
      content = await ioFile.readAsString();
    } else {
      throw const FormatException('Cannot access selected backup file.');
    }

    return parseBackupJson(content);
  }

  /// Validates and parses backup JSON content
  static BackupPreview parseBackupJson(String content) {
    dynamic decoded;
    try {
      decoded = jsonDecode(content);
    } catch (_) {
      throw const FormatException('Invalid JSON format in backup file.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Backup file root must be a JSON object.');
    }

    final schemaVersion = decoded['schemaVersion'];
    if (schemaVersion is! int) {
      throw const FormatException('Missing or invalid schemaVersion in backup file.');
    }

    if (schemaVersion > currentSchemaVersion) {
      throw FormatException(
        'This backup was created with a newer version of Loan Tracker (schema version $schemaVersion). '
        'Please update the app to restore it.',
      );
    }

    final appVersion = decoded['appVersion'] as String? ?? '1.0.0';
    final exportedAtStr = decoded['exportedAt'] as String?;
    final exportedAt = exportedAtStr != null
        ? DateTime.tryParse(exportedAtStr) ?? DateTime.now().toUtc()
        : DateTime.now().toUtc();

    final data = decoded['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Missing "data" object in backup file.');
    }

    final rawLoans = data['loans'];
    if (rawLoans is! List) {
      throw const FormatException('Missing "loans" list in backup data.');
    }

    final List<Loan> validatedLoans = [];
    for (int i = 0; i < rawLoans.length; i++) {
      final rawItem = rawLoans[i];
      if (rawItem is! Map<String, dynamic>) {
        throw FormatException('Loan entry #$i is invalid.');
      }
      try {
        final loan = Loan.fromJson(rawItem);
        validatedLoans.add(loan);
      } catch (e) {
        throw FormatException('Failed to deserialize loan entry #$i: $e');
      }
    }

    String? currency;
    ThemeMode? theme;
    final settingsMap = data['settings'];
    if (settingsMap is Map<String, dynamic>) {
      currency = settingsMap['currencySymbol'] as String?;
      final themeStr = settingsMap['themeMode'] as String?;
      if (themeStr != null) {
        theme = ThemeMode.values.firstWhere(
          (t) => t.name == themeStr,
          orElse: () => ThemeMode.system,
        );
      }
    }

    return BackupPreview(
      schemaVersion: schemaVersion,
      appVersion: appVersion,
      exportedAt: exportedAt,
      loans: validatedLoans,
      currencySymbol: currency,
      themeMode: theme,
    );
  }

  /// Restores loans with Merge or Replace strategy atomically
  static Future<void> restoreBackup({
    required BackupPreview preview,
    required StorageService storage,
    required SettingsProvider settings,
    required bool replaceExisting,
  }) async {
    if (replaceExisting) {
      await storage.replaceAllLoans(preview.loans);
    } else {
      await storage.mergeLoans(preview.loans);
    }

    if (preview.currencySymbol != null) {
      await settings.setCurrency(preview.currencySymbol!);
    }
    if (preview.themeMode != null) {
      await settings.setThemeMode(preview.themeMode!);
    }
  }
}
