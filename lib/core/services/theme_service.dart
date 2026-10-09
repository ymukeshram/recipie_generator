import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeService {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  static const _storage = FlutterSecureStorage();
  static const _themeKey = 'rasoiai_theme_mode';

  final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

  bool get isDark => themeModeNotifier.value == ThemeMode.dark;

  Future<void> init() async {
    try {
      final saved = await _storage.read(key: _themeKey);
      if (saved == 'dark') {
        themeModeNotifier.value = ThemeMode.dark;
      } else {
        themeModeNotifier.value = ThemeMode.light;
      }
    } catch (_) {
      themeModeNotifier.value = ThemeMode.light;
    }
  }

  Future<void> toggleTheme() async {
    final next = isDark ? ThemeMode.light : ThemeMode.dark;
    themeModeNotifier.value = next;
    try {
      await _storage.write(key: _themeKey, value: next == ThemeMode.dark ? 'dark' : 'light');
    } catch (_) {}
  }

  Future<void> setTheme(ThemeMode mode) async {
    themeModeNotifier.value = mode;
    try {
      await _storage.write(key: _themeKey, value: mode == ThemeMode.dark ? 'dark' : 'light');
    } catch (_) {}
  }
}

final themeService = ThemeService();
