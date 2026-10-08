import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeProvider({ThemeMode initialMode = ThemeMode.light}) {
    _themeMode = initialMode;
    _updateSystemUI();
  }

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void setDarkMode(bool enabled) {
    final newMode = enabled ? ThemeMode.dark : ThemeMode.light;
    if (_themeMode != newMode) {
      _themeMode = newMode;
      _updateSystemUI();
      notifyListeners();
    }
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      _updateSystemUI();
      notifyListeners();
    }
  }

  void toggleTheme() {
    setDarkMode(!isDarkMode);
  }

  void _updateSystemUI() {
    final bool dark = isDarkMode;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
        statusBarBrightness: dark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor:
            dark ? const Color(0xFF0E131F) : const Color(0xFFF8FAFC),
        systemNavigationBarIconBrightness:
            dark ? Brightness.light : Brightness.dark,
      ),
    );
  }
}
