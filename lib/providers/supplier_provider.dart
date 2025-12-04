import 'package:flutter/material.dart';
import '../models/provider_dto.dart';
import '../services/provider_service.dart';

class SupplierProvider extends ChangeNotifier {
  final ProviderService _providerService = ProviderService();
  
  List<ProviderDTO> _providers = [];
  bool _isLoading = false;
  String? _error;

  List<ProviderDTO> get providers => _providers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadProviders(String companyId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _providers = await _providerService.getAll(companyId);
    } catch (e) {
      _error = e.toString();
      print('Error loading providers: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
