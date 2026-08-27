// コード管理番号: VER-20260827-02
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode {
  light,
  dark,
  system,
}

/// ユーザー設定・テーマ状態管理プロバイダー
class SettingsProvider extends ChangeNotifier {
  static const String _keyThemeMode = 'app_theme_mode';
  static const String _keyShowJapanese = 'default_show_japanese';
  static const String _keySoundEnabled = 'sound_effects_enabled';

  static SettingsProvider? _instance;
  static SettingsProvider get instance => _instance ??= SettingsProvider();

  AppThemeMode _themeMode = AppThemeMode.light;
  bool _defaultShowJapanese = true;
  bool _soundEnabled = true;
  bool _isLoaded = false;

  AppThemeMode get themeMode => _themeMode;
  bool get defaultShowJapanese => _defaultShowJapanese;
  bool get soundEnabled => _soundEnabled;
  bool get isLoaded => _isLoaded;

  bool isDarkMode(BuildContext context) {
    if (_themeMode == AppThemeMode.dark) return true;
    if (_themeMode == AppThemeMode.light) return false;
    return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
  }

  Future<void> loadSettings() async {
    if (_isLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeStr = prefs.getString(_keyThemeMode) ?? 'light';
      _themeMode = AppThemeMode.values.firstWhere(
        (e) => e.name == modeStr,
        orElse: () => AppThemeMode.light,
      );
      _defaultShowJapanese = prefs.getBool(_keyShowJapanese) ?? true;
      _soundEnabled = prefs.getBool(_keySoundEnabled) ?? true;
    } catch (e) {
      debugPrint('SettingsProvider load error: ');
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyThemeMode, mode.name);
    } catch (e) {
      debugPrint('SettingsProvider save theme error: ');
    }
  }

  Future<void> toggleTheme() async {
    final newMode = _themeMode == AppThemeMode.dark ? AppThemeMode.light : AppThemeMode.dark;
    await setThemeMode(newMode);
  }

  Future<void> setDefaultShowJapanese(bool show) async {
    if (_defaultShowJapanese == show) return;
    _defaultShowJapanese = show;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyShowJapanese, show);
    } catch (e) {
      debugPrint('SettingsProvider save showJapanese error: ');
    }
  }

  Future<void> setSoundEnabled(bool enabled) async {
    if (_soundEnabled == enabled) return;
    _soundEnabled = enabled;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keySoundEnabled, enabled);
    } catch (e) {
      debugPrint('SettingsProvider save soundEnabled error: ');
    }
  }
}
