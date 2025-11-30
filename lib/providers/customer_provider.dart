import 'package:flutter/foundation.dart';
import '../services/customer_service.dart';
import '../services/auth_service.dart';
import '../models/customer_dto.dart';

/// Provider para manejo de clientes
class CustomerProvider extends ChangeNotifier {
  final CustomerService _customerService = CustomerService();
  final AuthService _authService = AuthService();

  List<CustomerDTO> _customers = [];
  CustomerDTO? _selectedCustomer;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<CustomerDTO> get customers => _customers;
  CustomerDTO? get selectedCustomer => _selectedCustomer;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get companyId => _authService.currentCompany?.id;

  /// Cargar todos los clientes
  Future<void> loadCustomers() async {
    if (companyId == null) {
      _setError('No hay empresa seleccionada');
      return;
    }

    try {
      _setLoading(true);
      _clearError();

      _customers = await _customerService.getAll(companyId!);

      _setLoading(false);
    } catch (e) {
      _setError('Error al cargar clientes: ${e.toString()}');
      _setLoading(false);
    }
  }

  /// Cargar clientes con stream
  Stream<List<CustomerDTO>> getCustomersStream() {
    if (companyId == null) {
      return Stream.value([]);
    }
    return _customerService.getAllMappedStream(companyId!);
  }

  /// Crear nuevo cliente
  Future<bool> createCustomer(CustomerDTO customer) async {
    if (companyId == null) {
      _setError('No hay empresa seleccionada');
      return false;
    }

    try {
      _setLoading(true);
      _clearError();

      await _customerService.insert(companyId!, customer);
      await loadCustomers();

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Error al crear cliente: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Actualizar cliente
  Future<bool> updateCustomer(CustomerDTO customer) async {
    if (companyId == null || customer.id == null || customer.id!.isEmpty) {
      _setError('Datos inválidos');
      return false;
    }

    try {
      _setLoading(true);
      _clearError();

      await _customerService.update(companyId!, customer.id!, customer);
      await loadCustomers();

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Error al actualizar cliente: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Eliminar cliente
  Future<bool> deleteCustomer(String customerId) async {
    if (companyId == null) {
      _setError('No hay empresa seleccionada');
      return false;
    }

    try {
      _setLoading(true);
      _clearError();

      await _customerService.delete(companyId!, customerId);
      _customers.removeWhere((c) => c.id == customerId);

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al eliminar cliente: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Seleccionar cliente
  void selectCustomer(CustomerDTO? customer) {
    _selectedCustomer = customer;
    notifyListeners();
  }

  /// Limpiar selección
  void clearSelection() {
    _selectedCustomer = null;
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
