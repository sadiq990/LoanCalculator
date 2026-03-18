import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const String keyTheme = 'theme_mode';
  static const String keyCurrency = 'currency_symbol';
  static const String keyPin = 'security_pin';
  static const String keyReminderTime = 'reminder_time';
  static const String keyOnboarded = 'has_onboarded';

  ThemeMode _themeMode = ThemeMode.system;
  String _currencySymbol = '\$';
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);
  bool _biometricEnabled = false;
  bool _isOnboarded = false;
  String? _pin;
  bool _isLoaded = false;

  ThemeMode get themeMode => _themeMode;
  String get currencySymbol => _currencySymbol;
  TimeOfDay get reminderTime => _reminderTime;
  bool get biometricEnabled => _biometricEnabled;
  bool get isOnboarded => _isOnboarded;
  String? get pin => _pin;
  bool get isLoaded => _isLoaded;

  SettingsProvider() {
    _loadSettings();
  }

  /// Private factory pattern to ensure async initialization
  static Future<SettingsProvider> create() async {
    final provider = SettingsProvider();
    await provider._loadSettingsAsync();
    return provider;
  }

  Future<void> _loadSettings() async {
    await _loadSettingsAsync();
  }

  /// Public method to load settings from SharedPreferences
  Future<void> loadSettingsAsync() async {
    await _loadSettingsAsync();
  }

  Future<void> _loadSettingsAsync() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Theme - with safe extraction
      final themeIndex = prefs.getInt(keyTheme) ?? 0;
      _themeMode = switch (themeIndex) {
        1 => ThemeMode.light,
        2 => ThemeMode.dark,
        _ => ThemeMode.system,
      };

      // Currency
      _currencySymbol = prefs.getString(keyCurrency) ?? '\$';

      // Reminder Time - with safe parsing
      final timeStr = prefs.getString(keyReminderTime);
      if (timeStr != null && timeStr.isNotEmpty && timeStr.contains(':')) {
        try {
          final parts = timeStr.split(':');
          if (parts.length == 2) {
            final hour = int.tryParse(parts[0]) ?? 9;
            final minute = int.tryParse(parts[1]) ?? 0;
            _reminderTime = TimeOfDay(
              hour: hour.clamp(0, 23),
              minute: minute.clamp(0, 59),
            );
          }
        } catch (e) {
          _reminderTime = const TimeOfDay(hour: 9, minute: 0);
        }
      }
      
      _biometricEnabled = prefs.getBool('biometricEnabled') ?? false;
      _isOnboarded = prefs.getBool(keyOnboarded) ?? false;
      _pin = prefs.getString(keyPin);
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      // Log error but don't crash - use defaults
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> setPin(String? value) async {
    _pin = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(keyPin);
    } else {
      await prefs.setString(keyPin, value);
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    int index = 0;
    if (mode == ThemeMode.light) index = 1;
    if (mode == ThemeMode.dark) index = 2;
    await prefs.setInt(keyTheme, index);
  }

  Future<void> setCurrency(String symbol) async {
    _currencySymbol = symbol;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyCurrency, symbol);
  }

  Future<void> setReminderTime(TimeOfDay time) async {
    _reminderTime = time;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyReminderTime, '${time.hour}:${time.minute}');
  }

  Future<void> setBiometricEnabled(bool value) async {
    _biometricEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometricEnabled', value);
  }

  Future<void> completeOnboarding() async {
    _isOnboarded = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyOnboarded, true);
  }
}
