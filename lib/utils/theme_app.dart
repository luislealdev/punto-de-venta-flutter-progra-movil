// TODO: CHECK COLORS
import 'package:flutter/material.dart';

class ThemeApp {
  // Colores personalizados para el tema
  static const Color _primaryBlue = Color(0xFF2196F3);
  static const Color _primaryBlueDark = Color(0xFF1976D2);
  static const Color _accentTeal = Color(0xFF00BCD4);
  static const Color _accentAmber = Color(0xFFFFC107);

  // Dark Theme
  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        brightness: Brightness.dark,
        primary: _primaryBlue,
        onPrimary: Colors.white,
        primaryContainer: _primaryBlueDark,
        onPrimaryContainer: Colors.white,
        secondary: _accentTeal,
        onSecondary: Colors.black,
        secondaryContainer: Color(0xFF004D57),
        onSecondaryContainer: Color(0xFFB3E5FC),
        tertiary: _accentAmber,
        onTertiary: Colors.black,
        error: Color(0xFFCF6679),
        onError: Colors.black,
        surface: Color(0xFF121212),
        onSurface: Colors.white,
        surfaceContainerHighest: Color(0xFF2C2C2C),
        outline: Color(0xFF5F5F5F),
        background: Color(0xFF0A0A0A),
        onBackground: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.black26,
        centerTitle: true,
      ),
      // cardTheme: CardTheme(
      //   color: const Color(0xFF1E1E1E),
      //   shadowColor: Colors.black54,
      //   elevation: 4,
      //   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      // ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryBlue,
          foregroundColor: Colors.white,
          elevation: 3,
          shadowColor: _primaryBlue.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primaryBlue, width: 2),
        ),
      ),
    );
  }

  // Light Theme
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        brightness: Brightness.light,
        primary: _primaryBlueDark,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFBBDEFB),
        onPrimaryContainer: Color(0xFF0D47A1),
        secondary: _accentTeal,
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFFB2EBF2),
        onSecondaryContainer: Color(0xFF00695C),
        tertiary: Color(0xFFFF9800),
        onTertiary: Colors.white,
        error: Color(0xFFD32F2F),
        onError: Colors.white,
        surface: Colors.white,
        onSurface: Color(0xFF1C1B1F),
        surfaceContainerHighest: Color(0xFFF5F5F5),
        outline: Color(0xFF79747E),
        background: Color(0xFFFAFAFA),
        onBackground: Color(0xFF1C1B1F),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _primaryBlueDark,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black12,
        centerTitle: true,
      ),
      // cardTheme: CardTheme(
      //   color: Colors.white,
      //   shadowColor: Colors.black12,
      //   elevation: 2,
      //   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      // ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryBlueDark,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: _primaryBlueDark.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primaryBlueDark, width: 2),
        ),
      ),
    );
  }
}
