import 'package:flutter/material.dart';
import '../models/store_dto.dart';
import '../services/store_service.dart';

class StoreProvider extends ChangeNotifier {
  final StoreService _storeService = StoreService();
  
  List<StoreDTO> _stores = [];
  bool _isLoading = false;
  String? _error;

  List<StoreDTO> get stores => _stores;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadStores(String companyId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _stores = await _storeService.getAll(companyId);
    } catch (e) {
      _error = e.toString();
      print('Error loading stores: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
