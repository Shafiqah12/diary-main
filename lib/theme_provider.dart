// lib/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light; // Default theme
  Color _appBarColor = Colors.teal; // Default app bar color

  ThemeMode get themeMode => _themeMode;
  Color get appBarColor => _appBarColor;

  ThemeProvider() {
    _loadThemePreference();
    _loadAppBarColorPreference();
  }

  void _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void _saveThemePreference(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode);
  }

  void _loadAppBarColorPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final colorValue = prefs.getInt('appBarColor') ?? Colors.teal.value;
    _appBarColor = Color(colorValue);
    notifyListeners();
  }

  void _saveAppBarColorPreference(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('appBarColor', color.value);
  }

  void toggleTheme(bool isOn) {
    _themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    _saveThemePreference(isOn);
    notifyListeners();
  }

  void changeAppBarColor(Color newColor) {
    _appBarColor = newColor;
    _saveAppBarColorPreference(newColor);
    notifyListeners();
  }
}