import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_info_dto.dart';
import '../models/company_dto.dart';

/// Provider para manejo de autenticación y estado del usuario
///
/// Este provider centraliza todo el estado relacionado con:
/// - Usuario autenticado actual
/// - Información del usuario (UserInfoDTO)
/// - Empresa actual
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;

  // Getters para acceder al estado del AuthService
  User? get currentUser => _authService.currentUser;
  UserInfoDTO? get currentUserInfo => _authService.currentUserInfo;
  CompanyDTO? get currentCompany => _authService.currentCompany;
  String? get currentCompanyId => _authService.currentCompanyId;
  String? get currentStoreId => _authService.currentStoreId;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => currentUser != null;

  /// Iniciar sesión con email y contraseña
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      _setLoading(true);
      _clearError();

      final credential = await _authService.signInWithEmailAndPassword(
        email,
        password,
      );

      _setLoading(false);
      notifyListeners();

      return credential != null && credential.user != null;
    } catch (e) {
      _setError('Error al iniciar sesión: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Registrar nuevo usuario con empresa
  Future<bool> createCompanyManagerWithEmailAndPassword({
    required String email,
    required String password,
    required String companyName,
    String? displayName,
    String? phone,
    String? companyEmail,
    String? companyPhone,
    String? companyAddress,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // AuthService usa parámetros posicionales para los primeros 3
      final credential = await _authService
          .createCompanyManagerWithEmailAndPassword(
            email,
            password,
            companyName,
            displayName: displayName,
            phone: phone,
            companyEmail: companyEmail,
            companyPhone: companyPhone,
            companyAddress: companyAddress,
          );

      _setLoading(false);
      notifyListeners();

      return credential != null && credential.user != null;
    } catch (e) {
      _setError('Error al registrar: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Cerrar sesión
  Future<void> signOut() async {
    try {
      _setLoading(true);
      _clearError();

      await _authService.signOut();

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Error al cerrar sesión: ${e.toString()}');
      _setLoading(false);
    }
  }

  /// Recargar contexto del usuario
  Future<void> reloadUserContext() async {
    try {
      _setLoading(true);
      _clearError();

      if (currentUser != null) {
        await _authService.reloadUserContext();
      }

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Error al recargar contexto: ${e.toString()}');
      _setLoading(false);
    }
  }

  /// Cambiar de tienda
  Future<bool> switchStore(String storeId) async {
    try {
      _setLoading(true);
      _clearError();

      await _authService.switchStore(storeId);

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al cambiar de tienda: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Verificar si tiene un permiso
  Future<bool> hasPermission(String permission) async {
    return await _authService.hasPermission(permission);
  }

  // Métodos privados para manejo de estado
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
