import 'package:flutter/foundation.dart';
import '../services/provider_service.dart';
import '../services/auth_service.dart';
import '../models/provider_dto.dart';

/// Provider para manejo de proveedores (suppliers)
/// Nota: Se llama SupplierProvider para evitar confusión con Provider de Flutter
class SupplierProvider extends ChangeNotifier {
  final ProviderService _providerService = ProviderService();
  final AuthService _authService = AuthService();

  List<ProviderDTO> _suppliers = [];
  ProviderDTO? _selectedSupplier;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<ProviderDTO> get suppliers => _suppliers;
  ProviderDTO? get selectedSupplier => _selectedSupplier;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get companyId => _authService.currentCompany?.id;

  /// Cargar todos los proveedores
  Future<void> loadSuppliers() async {
    if (companyId == null) {
      _setError('No hay empresa seleccionada');
      return;
    }

    try {
      _setLoading(true);
      _clearError();

      _suppliers = await _providerService.getAll(companyId!);

      _setLoading(false);
    } catch (e) {
      _setError('Error al cargar proveedores: ${e.toString()}');
      _setLoading(false);
    }
  }

  /// Cargar proveedores con stream
  Stream<List<ProviderDTO>> getSuppliersStream() {
    if (companyId == null) {
      return Stream.value([]);
    }
    return _providerService.getAllMappedStream(companyId!);
  }

  /// Crear nuevo proveedor
  Future<bool> createSupplier(ProviderDTO supplier) async {
    if (companyId == null) {
      _setError('No hay empresa seleccionada');
      return false;
    }

    try {
      _setLoading(true);
      _clearError();

      await _providerService.insert(companyId!, supplier);
      await loadSuppliers();

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Error al crear proveedor: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Actualizar proveedor
  Future<bool> updateSupplier(ProviderDTO supplier) async {
    if (companyId == null || supplier.id == null || supplier.id!.isEmpty) {
      _setError('Datos inválidos');
      return false;
    }

    try {
      _setLoading(true);
      _clearError();

      await _providerService.update(companyId!, supplier.id!, supplier);
      await loadSuppliers();

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Error al actualizar proveedor: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Eliminar proveedor
  Future<bool> deleteSupplier(String supplierId) async {
    if (companyId == null) {
      _setError('No hay empresa seleccionada');
      return false;
    }

    try {
      _setLoading(true);
      _clearError();

      await _providerService.delete(companyId!, supplierId);
      _suppliers.removeWhere((s) => s.id == supplierId);

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al eliminar proveedor: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Seleccionar proveedor
  void selectSupplier(ProviderDTO? supplier) {
    _selectedSupplier = supplier;
    notifyListeners();
  }

  /// Limpiar selección
  void clearSelection() {
    _selectedSupplier = null;
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
