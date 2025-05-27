import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart'; // Ya no es necesario si el tema es fijo

class ThemeNotifier with ChangeNotifier {
  // final String key = "theme_preference"; // No es necesario si el tema es fijo
  // SharedPreferences? _prefs; // No es necesario si el tema es fijo

  // Establece ThemeMode.light por defecto y no lo cambies.
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode; // Siempre devolverá ThemeMode.light

  ThemeNotifier() {
    // No es necesario cargar desde SharedPreferences si siempre queremos el tema claro.
    // El _themeMode ya está inicializado a ThemeMode.light.
    // Si quieres mantener la lógica del interruptor en Ajustes (aunque no cambie el tema general),
    // podrías dejar el código de SharedPreferences, pero asegúrate de que el resultado final
    // de _themeMode siempre sea ThemeMode.light.
    // Para "siempre blanco", lo más simple es no cargar/guardar preferencias de tema.
  }

  // Los siguientes métodos se vuelven redundantes o su efecto es nulo
  // si el tema está fijado a ThemeMode.light.
  // Se mantienen para que el código existente que los llama no se rompa,
  // pero se aseguran de que _themeMode permanezca como ThemeMode.light.

  Future<void> _initPrefs() async {
    // _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> _loadFromPrefs() async {
    // Esta función ya no es necesaria para determinar el tema si siempre es claro.
    // Nos aseguramos de que _themeMode siga siendo light.
    _themeMode = ThemeMode.light;
    // No es necesario notificar si el estado no cambia realmente desde la inicialización.
    // notifyListeners(); 
  }

  Future<void> _saveToPrefs(ThemeMode themeMode) async {
    // Guardar preferencias ya no es relevante si el tema es fijo.
    // await _initPrefs();
    // _prefs!.setInt(key, ThemeMode.light.index); // Si guardas algo, guarda light
  }

  void setThemeMode(ThemeMode mode) {
    // Ignora el 'mode' entrante y asegura que el tema siga siendo light.
    if (_themeMode != ThemeMode.light) {
      _themeMode = ThemeMode.light;
      notifyListeners(); // Notifica solo si realmente hubo un cambio (improbable aquí)
    }
  }

  // Método específico para forzar el tema claro
  void setForceLightMode(bool forceLight) {
    // El tema ya está forzado a ser claro por la lógica de esta clase.
    // Este método no necesita cambiar _themeMode si ya es ThemeMode.light.
    // Si quieres que el interruptor en la UI parezca que hace algo,
    // puedes llamar a notifyListeners() para que la UI se reconstruya,
    // pero el tema subyacente no cambiará de ThemeMode.light.
    if (_themeMode != ThemeMode.light) { // Condición que probablemente nunca sea cierta
        _themeMode = ThemeMode.light;
        notifyListeners();
    }
    // Si el interruptor debe reflejar un estado "forzado" aunque el tema no cambie,
    // podrías necesitar una variable de estado separada para el interruptor.
    // Por ahora, mantenemos la lógica simple: el tema es siempre light.
  }

  bool get isForcingLightMode {
    // Si el tema de la aplicación siempre es ThemeMode.light,
    // entonces se puede considerar que siempre está "forzando" el modo claro.
    return _themeMode == ThemeMode.light; // Esto siempre será true
  }
}