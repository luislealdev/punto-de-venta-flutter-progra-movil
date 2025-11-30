import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Provider para manejo del tema (claro/oscuro)
///
/// Este provider reemplaza el ValueNotifier que se usaba anteriormente
/// para manejar el cambio de tema en la aplicación.
class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  /// Alternar entre tema claro y oscuro
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  /// Establecer tema específico
  void setTheme(bool isDark) {
    if (_isDarkMode != isDark) {
      _isDarkMode = isDark;
      notifyListeners();
    }
  }

  /// Establecer tema claro
  void setLightTheme() {
    setTheme(false);
  }

  /// Establecer tema oscuro
  void setDarkTheme() {
    setTheme(true);
  }
}
