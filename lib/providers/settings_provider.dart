import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/secure_pin_service.dart';
import '../core/utils/currency_formatter.dart';

enum AutoLockTimeout {
  immediately,
  oneMinute,
  fiveMinutes;

  String get label {
    switch (this) {
      case AutoLockTimeout.immediately:
        return 'Immediately';
      case AutoLockTimeout.oneMinute:
        return 'After 1 minute';
      case AutoLockTimeout.fiveMinutes:
        return 'After 5 minutes';
    }
  }

  Duration get duration {
    switch (this) {
      case AutoLockTimeout.immediately:
        return Duration.zero;
      case AutoLockTimeout.oneMinute:
        return const Duration(minutes: 1);
      case AutoLockTimeout.fiveMinutes:
        return const Duration(minutes: 5);
    }
  }
}

enum OpenAppOn {
  calculator,
  myLoans,
  lastUsed;

  String get label {
    switch (this) {
      case OpenAppOn.calculator:
        return 'Calculator';
      case OpenAppOn.myLoans:
        return 'My Loans';
      case OpenAppOn.lastUsed:
        return 'Last used';
    }
  }
}

class SettingsProvider extends ChangeNotifier {
  static const String keyTheme = 'theme_mode';
  static const String keyCurrency = 'currency_symbol';
  static const String keyPin = 'security_pin';
  static const String keyReminderTime = 'reminder_time';
  static const String keyOnboarded = 'has_onboarded';
  static const String keyAutoLockTimeout = 'auto_lock_timeout';
  static const String keyOpenAppOn = 'open_app_on';
  static const String keyLastUsedTab = 'last_used_tab';

  final SecurePinService _securePinService = SecurePinService();

  ThemeMode _themeMode = ThemeMode.system;
  String _currencySymbol = '\$';
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);
  bool _biometricEnabled = false;
  bool _isOnboarded = false;
  bool _hasPin = false;
  AutoLockTimeout _autoLockTimeout = AutoLockTimeout.immediately;
  OpenAppOn _openAppOn = OpenAppOn.lastUsed;
  int _lastUsedTab = -1;
  final Map<String, int> _loanReminderDays = {};
  bool _isLoaded = false;
  bool isBiometricPromptActive = false;

  ThemeMode get themeMode => _themeMode;
  String get currencySymbol => _currencySymbol;
  TimeOfDay get reminderTime => _reminderTime;
  bool get biometricEnabled => _biometricEnabled;
  bool get isOnboarded => _isOnboarded;
  bool get hasPin => _hasPin;
  String? get pin => _hasPin ? '******' : null;
  AutoLockTimeout get autoLockTimeout => _autoLockTimeout;
  OpenAppOn get openAppOn => _openAppOn;
  int get lastUsedTab => _lastUsedTab;
  Map<String, int> get loanReminderDays => _loanReminderDays;
  bool get isLoaded => _isLoaded;

  SettingsProvider() {
    _loadSettingsAsync();
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

      // Currency: use saved value if set, otherwise detect device locale currency with fallback to USD
      final savedCurrency = prefs.getString(keyCurrency);
      if (savedCurrency != null && savedCurrency.isNotEmpty) {
        _currencySymbol = savedCurrency;
      } else {
        _currencySymbol = getDefaultLocaleCurrencySymbol();
      }

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
        } catch (_) {
          _reminderTime = const TimeOfDay(hour: 9, minute: 0);
        }
      }

      _biometricEnabled = prefs.getBool('biometricEnabled') ?? false;
      _isOnboarded = prefs.getBool(keyOnboarded) ?? false;

      // Auto-lock timeout
      final timeoutIndex = prefs.getInt(keyAutoLockTimeout) ?? 0;
      _autoLockTimeout = AutoLockTimeout.values.elementAtOrNull(timeoutIndex) ?? AutoLockTimeout.immediately;

      // Open app on
      final openOnIndex = prefs.getInt(keyOpenAppOn);
      if (openOnIndex != null && openOnIndex >= 0 && openOnIndex < OpenAppOn.values.length) {
        _openAppOn = OpenAppOn.values[openOnIndex];
      } else {
        _openAppOn = OpenAppOn.lastUsed;
      }
      _lastUsedTab = prefs.getInt(keyLastUsedTab) ?? -1;

      // Initialize secure PIN service and check if PIN is configured
      await _securePinService.initialize(prefs);
      _hasPin = await _securePinService.hasPin();

      final remindersStr = prefs.getString('loan_reminder_days');
      if (remindersStr != null && remindersStr.isNotEmpty) {
        try {
          for (var pair in remindersStr.split(',')) {
            final split = pair.split(':');
            if (split.length == 2) {
              _loanReminderDays[split[0]] = int.tryParse(split[1]) ?? 5;
            }
          }
        } catch (_) {}
      }

      _isLoaded = true;
      notifyListeners();
    } catch (_) {
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> setPin(String? value) async {
    if (value == null || value.isEmpty) {
      await _securePinService.clearPin();
      _hasPin = false;
    } else {
      await _securePinService.setPin(value);
      _hasPin = true;
    }
    notifyListeners();
  }

  Future<PinVerifyResult> verifyPin(String pin) async {
    return _securePinService.verifyPin(pin);
  }

  Future<int> getRemainingLockoutSeconds() async {
    return _securePinService.getRemainingLockoutSeconds();
  }

  Future<void> setAutoLockTimeout(AutoLockTimeout timeout) async {
    _autoLockTimeout = timeout;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(keyAutoLockTimeout, timeout.index);
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

  Future<void> setReminderDays(String loanId, int days) async {
    _loanReminderDays[loanId] = days;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final encoded = _loanReminderDays.entries.map((e) => '${e.key}:${e.value}').join(',');
    await prefs.setString('loan_reminder_days', encoded);
  }

  Future<void> removeReminder(String loanId) async {
    _loanReminderDays.remove(loanId);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final encoded = _loanReminderDays.entries.map((e) => '${e.key}:${e.value}').join(',');
    await prefs.setString('loan_reminder_days', encoded);
  }

  Future<void> setOpenAppOn(OpenAppOn mode) async {
    _openAppOn = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(keyOpenAppOn, mode.index);
  }

  Future<void> setLastUsedTab(int tabIndex) async {
    _lastUsedTab = tabIndex;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(keyLastUsedTab, tabIndex);
  }

  /// Determines which tab to open on startup.
  /// Tab indices: 0=Home, 1=Calculator, 2=Statistics, 3=Settings.
  /// On fresh install with no loans (or default lastUsed with no previous tab), starts on Calculator.
  int determineInitialTab({required bool hasLoans}) {
    switch (_openAppOn) {
      case OpenAppOn.calculator:
        return 1; // Calculator tab
      case OpenAppOn.myLoans:
        return 0; // Home tab
      case OpenAppOn.lastUsed:
        if (_lastUsedTab >= 0 && _lastUsedTab <= 3) {
          return _lastUsedTab;
        }
        return hasLoans ? 0 : 1; // Home if has loans, Calculator if fresh
    }
  }

  Future<void> completeOnboarding() async {
    _isOnboarded = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyOnboarded, true);
  }
}
