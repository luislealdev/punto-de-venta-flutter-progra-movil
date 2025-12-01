import 'package:shared_preferences/shared_preferences.dart';

/// Servicio para manejar el estado del onboarding
class OnboardingService {
  static const String _onboardingKey = 'onboarding_complete';

  /// Verifica si el usuario ya vio el onboarding
  static Future<bool> hasSeenOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_onboardingKey) ?? false;
    } catch (e) {
      print('Error al verificar onboarding: $e');
      return false;
    }
  }

  /// Marca el onboarding como completado
  static Future<void> completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingKey, true);
    } catch (e) {
      print('Error al completar onboarding: $e');
    }
  }

  /// Resetea el onboarding (útil para testing)
  static Future<void> resetOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_onboardingKey);
    } catch (e) {
      print('Error al resetear onboarding: $e');
    }
  }
}
