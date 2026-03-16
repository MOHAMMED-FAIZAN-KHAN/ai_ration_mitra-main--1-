import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  // 🔹 Storage key constant (avoid hardcoded strings everywhere)
  static const String _themeKey = 'isDark';

  // 🔹 Internal theme state
  ThemeMode _themeMode = ThemeMode.system;

  // 🔹 Cached SharedPreferences instance
  SharedPreferences? _prefs;

  // 🔹 Public getter
  ThemeMode get themeMode => _themeMode;

  // 🔹 Helper getter (useful for switches)
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  // ==============================
  // 🔥 Initialize Provider
  // ==============================
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadTheme();
  }

  // ==============================
  // 🔥 Load saved theme
  // ==============================
  Future<void> _loadTheme() async {
    try {
      final isDark = _prefs?.getBool(_themeKey) ?? false;
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      notifyListeners();
    } catch (e) {
      debugPrint("Theme Load Error: $e");
    }
  }

  // ==============================
  // 🔥 Toggle Theme
  // ==============================
  Future<void> toggleTheme(bool isDark) async {
    try {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      await _prefs?.setBool(_themeKey, isDark);
      notifyListeners();
    } catch (e) {
      debugPrint("Theme Save Error: $e");
    }
  }

  // ==============================
  // 🔥 Direct Theme Setter (future ready)
  // ==============================
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs?.setBool(_themeKey, mode == ThemeMode.dark);
    notifyListeners();
  }
}