import 'package:flutter/material.dart';
import '../models/product_dto.dart';
import '../services/product_service.dart';

class ProductProvider extends ChangeNotifier {
  final ProductService _productService = ProductService();
  
  List<ProductDTO> _products = [];
  List<ProductDTO> _filteredProducts = [];
  bool _isLoading = false;
  String? _error;

  List<ProductDTO> get products => _products;
  List<ProductDTO> get filteredProducts => _filteredProducts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadProducts(String companyId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _products = await _productService.getAll(companyId);
      _filteredProducts = _products;
    } catch (e) {
      _error = e.toString();
      print('Error loading products: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void filterProducts(String searchTerm) {
    if (searchTerm.isEmpty) {
      _filteredProducts = _products;
    } else {
      _filteredProducts = _products.where((product) =>
        (product.name?.toLowerCase().contains(searchTerm.toLowerCase()) ?? false) ||
        (product.barcode?.toLowerCase().contains(searchTerm.toLowerCase()) ?? false) ||
        (product.sku?.toLowerCase().contains(searchTerm.toLowerCase()) ?? false) ||
        (product.description?.toLowerCase().contains(searchTerm.toLowerCase()) ?? false)
      ).toList();
    }
    notifyListeners();
  }

  void clear() {
    _products = [];
    _filteredProducts = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
