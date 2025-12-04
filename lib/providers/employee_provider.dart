import 'package:flutter/material.dart';
import '../models/employee_dto.dart';
import '../services/employee_service.dart';

class EmployeeProvider extends ChangeNotifier {
  final EmployeeService _employeeService = EmployeeService();
  
  List<EmployeeDTO> _employees = [];
  bool _isLoading = false;
  String? _error;

  List<EmployeeDTO> get employees => _employees;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadEmployees(String companyId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _employees = await _employeeService.getAll(companyId);
    } catch (e) {
      _error = e.toString();
      print('Error loading employees: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
