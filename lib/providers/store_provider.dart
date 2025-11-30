import 'package:flutter/foundation.dart';
import '../services/store_service.dart';
import '../services/auth_service.dart';
import '../models/store_dto.dart';

/// Provider para manejo de tiendas
class StoreProvider extends ChangeNotifier {
  final StoreService _storeService = StoreService();
  final AuthService _authService = AuthService();

  List<StoreDTO> _stores = [];
  StoreDTO? _selectedStore;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<StoreDTO> get stores => _stores;
  StoreDTO? get selectedStore => _selectedStore;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get companyId => _authService.currentCompany?.id;

  /// Cargar todas las tiendas
  Future<void> loadStores() async {
    if (companyId == null) {
      _setError('No hay empresa seleccionada');
      return;
    }

    try {
      _setLoading(true);
      _clearError();

      _stores = await _storeService.getAll(companyId!);

      _setLoading(false);
    } catch (e) {
      _setError('Error al cargar tiendas: ${e.toString()}');
      _setLoading(false);
    }
  }

  /// Cargar tiendas con stream
  Stream<List<StoreDTO>> getStoresStream() {
    if (companyId == null) {
      return Stream.value([]);
    }
    return _storeService.getAllMappedStream(companyId!);
  }

  /// Crear nueva tienda
  Future<bool> createStore(StoreDTO store) async {
    if (companyId == null) {
      _setError('No hay empresa seleccionada');
      return false;
    }

    try {
      _setLoading(true);
      _clearError();

      await _storeService.insert(companyId!, store);
      await loadStores();

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Error al crear tienda: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Actualizar tienda
  Future<bool> updateStore(StoreDTO store) async {
    if (companyId == null || store.id == null || store.id!.isEmpty) {
      _setError('Datos inválidos');
      return false;
    }

    try {
      _setLoading(true);
      _clearError();

      await _storeService.update(companyId!, store.id!, store);
      await loadStores();

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Error al actualizar tienda: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Eliminar tienda
  Future<bool> deleteStore(String storeId) async {
    if (companyId == null) {
      _setError('No hay empresa seleccionada');
      return false;
    }

    try {
      _setLoading(true);
      _clearError();

      await _storeService.delete(companyId!, storeId);
      _stores.removeWhere((s) => s.id == storeId);

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al eliminar tienda: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Seleccionar tienda
  void selectStore(StoreDTO? store) {
    _selectedStore = store;
    notifyListeners();
  }

  /// Limpiar selección
  void clearSelection() {
    _selectedStore = null;
    notifyListeners();
  }

  // Métodos privados
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
