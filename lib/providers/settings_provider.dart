import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const String keyTheme = 'theme_mode';
  static const String keyCurrency = 'currency_symbol';
  static const String keyReminderTime = 'reminderTime';
  static const String keyOnboarded = 'isOnboarded';

  ThemeMode _themeMode = ThemeMode.system;
  String _currencySymbol = '\$';
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);
  bool _biometricEnabled = false;
  bool _isOnboarded = false;

  ThemeMode get themeMode => _themeMode;
  String get currencySymbol => _currencySymbol;
  TimeOfDay get reminderTime => _reminderTime;
  bool get biometricEnabled => _biometricEnabled;
  bool get isOnboarded => _isOnboarded;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Theme
    final themeIndex = prefs.getInt(keyTheme) ?? 0;
    if (themeIndex == 1) {
      _themeMode = ThemeMode.light;
    } else if (themeIndex == 2) {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }

    // Currency
    _currencySymbol = prefs.getString(keyCurrency) ?? '\$';

    // Reminder Time
    final timeStr = prefs.getString(keyReminderTime);
    if (timeStr != null && timeStr.contains(':')) {
      final parts = timeStr.split(':');
      _reminderTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
    
    _biometricEnabled = prefs.getBool('biometricEnabled') ?? false;
    _isOnboarded = prefs.getBool(keyOnboarded) ?? false;
    notifyListeners();
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
