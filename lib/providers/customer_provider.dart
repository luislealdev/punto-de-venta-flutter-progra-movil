import 'package:flutter/material.dart';
import '../models/customer_dto.dart';
import '../services/customer_service.dart';

class CustomerProvider extends ChangeNotifier {
  final CustomerService _customerService = CustomerService();
  
  List<CustomerDTO> _customers = [];
  List<CustomerDTO> _filteredCustomers = [];
  bool _isLoading = false;
  String? _error;

  List<CustomerDTO> get customers => _customers;
  List<CustomerDTO> get filteredCustomers => _filteredCustomers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadCustomers(String companyId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _customers = await _customerService.getActiveCustomers(companyId);
      _filteredCustomers = _customers;
    } catch (e) {
      _error = e.toString();
      print('Error loading customers: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void filterCustomers(String searchTerm) {
    if (searchTerm.isEmpty) {
      _filteredCustomers = _customers;
    } else {
      _filteredCustomers = _customers.where((customer) =>
        (customer.name?.toLowerCase().contains(searchTerm.toLowerCase()) ?? false) ||
        (customer.email?.toLowerCase().contains(searchTerm.toLowerCase()) ?? false) ||
        (customer.phone?.toLowerCase().contains(searchTerm.toLowerCase()) ?? false) ||
        (customer.taxId?.toLowerCase().contains(searchTerm.toLowerCase()) ?? false)
      ).toList();
    }
    notifyListeners();
  }

  Future<void> addCustomer(CustomerDTO customer) async {
    // Optimistic update or reload? Reload is safer for now.
    // But we need companyId. 
    // Ideally, addCustomer returns the new customer with ID.
    // For now, we'll just rely on the screen calling loadCustomers again or we can implement add logic here.
    // Let's just notify for now.
    notifyListeners();
  }
  
  // Clear data when logging out
  void clear() {
    _customers = [];
    _filteredCustomers = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
