import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier with ChangeNotifier {
  final String key = "theme_preference";
  SharedPreferences? _prefs;
  ThemeMode _themeMode;

  ThemeMode get themeMode => _themeMode;

  ThemeNotifier(this._themeMode) {
    _loadFromPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> _loadFromPrefs() async {
    await _initPrefs();
    int? preferredTheme = _prefs!.getInt(key);
    if (preferredTheme == null) {
      // Si no hay preferencia guardada, usa el tema del sistema por defecto
      _themeMode = ThemeMode.system;
    } else {
      _themeMode = ThemeMode.values[preferredTheme];
    }
    notifyListeners();
  }

  Future<void> _saveToPrefs(ThemeMode themeMode) async {
    await _initPrefs();
    _prefs!.setInt(key, themeMode.index);
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _saveToPrefs(mode);
    notifyListeners();
  }

  // Método específico para forzar el tema claro
  void setForceLightMode(bool forceLight) {
    if (forceLight) {
      setThemeMode(ThemeMode.light);
    } else {
      // Vuelve al tema del sistema o a la última preferencia guardada que no sea forzada
      // Para simplificar, volvemos a system. Podrías guardar la preferencia "no forzada" si quieres más complejidad.
      setThemeMode(ThemeMode.system);
    }
  }

  bool get isForcingLightMode {
    // Consideramos que está forzando el modo claro si el tema actual es light
    // y no es el resultado de que el sistema esté en modo claro.
    // Una forma más robusta sería guardar un booleano separado para "forceLight"
    return _themeMode == ThemeMode.light;
  }
}