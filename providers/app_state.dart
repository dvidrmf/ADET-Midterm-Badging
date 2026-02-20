import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeChoice { deepSea, sunset, forest }

class AppThemeData {
  final String label;
  final Color primary;
  final Color secondary;
  final Color accent;
  final LinearGradient headerGradient;

  const AppThemeData({
    required this.label,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.headerGradient,
  });
}

final Map<AppThemeChoice, AppThemeData> kThemes = {
  AppThemeChoice.deepSea: const AppThemeData(
    label: 'Blue',
    primary: Color(0xFF0A4D8C),
    secondary: Color(0xFF1A7ABF),
    accent: Color(0xFF00D4FF),
    headerGradient: LinearGradient(
      colors: [Color(0xFF0A1628), Color(0xFF0A4D8C)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  AppThemeChoice.sunset: const AppThemeData(
    label: 'Orange',
    primary: Color(0xFFBF3A0A),
    secondary: Color(0xFFE8622A),
    accent: Color(0xFFFFAB40),
    headerGradient: LinearGradient(
      colors: [Color(0xFF3D0C02), Color(0xFFBF3A0A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  AppThemeChoice.forest: const AppThemeData(
    label: 'Green',
    primary: Color(0xFF1B5E20),
    secondary: Color(0xFF388E3C),
    accent: Color(0xFF69F0AE),
    headerGradient: LinearGradient(
      colors: [Color(0xFF071A08), Color(0xFF1B5E20)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
};

class AppState extends ChangeNotifier {
  String _displayName = 'Student';
  AppThemeChoice _themeChoice = AppThemeChoice.deepSea;

  String get displayName => _displayName;
  AppThemeChoice get themeChoice => _themeChoice;
  AppThemeData get theme => kThemes[_themeChoice]!;
  Color get primaryColor => theme.primary;
  Color get accentColor => theme.accent;

  ThemeData get materialTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.dark(
          primary: theme.primary,
          secondary: theme.secondary,
          tertiary: theme.accent,
          surface: const Color(0xFF121212),
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: theme.accent,
          thumbColor: theme.accent,
          overlayColor: theme.accent.withValues(alpha: 0.2),
          inactiveTrackColor: theme.primary.withValues(alpha: 0.3),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1E1E1E),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.primary.withValues(alpha: 0.4)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.accent, width: 2),
          ),
          labelStyle: TextStyle(color: theme.accent.withValues(alpha: 0.8)),
        ),
      );

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _displayName = prefs.getString('displayName') ?? 'Student';
    final idx = prefs.getInt('themeChoice') ?? 0;
    _themeChoice = AppThemeChoice.values[idx];
    notifyListeners();
  }

  Future<void> setDisplayName(String name) async {
    _displayName = name.trim().isEmpty ? 'Student' : name.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('displayName', _displayName);
    notifyListeners();
  }

  Future<void> setTheme(AppThemeChoice choice) async {
    _themeChoice = choice;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeChoice', choice.index);
    notifyListeners();
  }
}
