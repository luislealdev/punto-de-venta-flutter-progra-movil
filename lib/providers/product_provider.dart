import 'package:flutter/foundation.dart';
import '../services/product_service.dart';
import '../services/auth_service.dart';
import '../models/product_dto.dart';

/// Provider para manejo de productos
///
/// Este provider centraliza todo el estado relacionado con productos:
/// - Lista de productos
/// - Producto seleccionado para edición
/// - Estado de carga
/// - Errores
class ProductProvider extends ChangeNotifier {
  final ProductService _productService = ProductService();
  final AuthService _authService = AuthService();

  List<ProductDTO> _products = [];
  ProductDTO? _selectedProduct;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<ProductDTO> get products => _products;
  ProductDTO? get selectedProduct => _selectedProduct;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get companyId => _authService.currentCompany?.id;

  /// Cargar todos los productos
  Future<void> loadProducts() async {
    if (companyId == null) {
      _setError('No hay empresa seleccionada');
      return;
    }

    try {
      _setLoading(true);
      _clearError();

      _products = await _productService.getAll(companyId!);

      _setLoading(false);
    } catch (e) {
      _setError('Error al cargar productos: ${e.toString()}');
      _setLoading(false);
    }
  }

  /// Cargar productos con stream (actualizaciones en tiempo real)
  Stream<List<ProductDTO>> getProductsStream() {
    if (companyId == null) {
      return Stream.value([]);
    }
    return _productService.getAllMappedStream(companyId!);
  }

  /// Buscar productos por nombre
  Future<void> searchProducts(String query) async {
    if (companyId == null) {
      _setError('No hay empresa seleccionada');
      return;
    }

    try {
      _setLoading(true);
      _clearError();

      _products = await _productService.searchProductsByName(companyId!, query);

      _setLoading(false);
    } catch (e) {
      _setError('Error al buscar productos: ${e.toString()}');
      _setLoading(false);
    }
  }

  /// Crear nuevo producto
  Future<bool> createProduct(ProductDTO product) async {
    if (companyId == null) {
      _setError('No hay empresa seleccionada');
      return false;
    }

    try {
      _setLoading(true);
      _clearError();

      await _productService.insert(companyId!, product);
      await loadProducts(); // Recargar lista

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Error al crear producto: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Actualizar producto existente
  Future<bool> updateProduct(ProductDTO product) async {
    if (companyId == null || product.id == null || product.id!.isEmpty) {
      _setError('Datos inválidos');
      return false;
    }

    try {
      _setLoading(true);
      _clearError();

      await _productService.update(companyId!, product.id!, product);
      await loadProducts(); // Recargar lista

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Error al actualizar producto: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Eliminar producto
  Future<bool> deleteProduct(String productId) async {
    if (companyId == null) {
      _setError('No hay empresa seleccionada');
      return false;
    }

    try {
      _setLoading(true);
      _clearError();

      await _productService.delete(companyId!, productId);
      _products.removeWhere((p) => p.id == productId);

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al eliminar producto: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Seleccionar producto para edición
  void selectProduct(ProductDTO? product) {
    _selectedProduct = product;
    notifyListeners();
  }

  /// Limpiar producto seleccionado
  void clearSelection() {
    _selectedProduct = null;
    notifyListeners();
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
