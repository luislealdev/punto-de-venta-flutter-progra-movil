import 'package:flutter/foundation.dart';
import '../services/sale_service.dart';
import '../services/auth_service.dart';
import '../models/sale_dto.dart';
import '../models/product_dto.dart';

/// Item del carrito de compras
class CartItem {
  final ProductDTO product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get subtotal => (product.basePrice ?? 0.0) * quantity;
}

/// Provider para manejo de ventas y carrito de compras
class SaleProvider extends ChangeNotifier {
  final SaleService _saleService = SaleService();
  final AuthService _authService = AuthService();

  List<SaleDTO> _sales = [];
  List<CartItem> _cartItems = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<SaleDTO> get sales => _sales;
  List<CartItem> get cartItems => _cartItems;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get companyId => _authService.currentCompany?.id;

  int get cartItemCount =>
      _cartItems.fold(0, (sum, item) => sum + item.quantity);
  double get cartTotal =>
      _cartItems.fold(0.0, (sum, item) => sum + item.subtotal);
  bool get isCartEmpty => _cartItems.isEmpty;

  /// Cargar todas las ventas
  Future<void> loadSales() async {
    if (companyId == null) {
      _setError('No hay empresa seleccionada');
      return;
    }

    try {
      _setLoading(true);
      _clearError();

      _sales = await _saleService.getAll(companyId!);

      _setLoading(false);
    } catch (e) {
      _setError('Error al cargar ventas: ${e.toString()}');
      _setLoading(false);
    }
  }

  /// Cargar ventas con stream
  Stream<List<SaleDTO>> getSalesStream() {
    if (companyId == null) {
      return Stream.value([]);
    }
    return _saleService.getAllMappedStream(companyId!);
  }

  /// Crear nueva venta
  Future<bool> createSale(SaleDTO sale) async {
    if (companyId == null) {
      _setError('No hay empresa seleccionada');
      return false;
    }

    try {
      _setLoading(true);
      _clearError();

      await _saleService.insert(companyId!, sale);
      await loadSales();

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Error al crear venta: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Agregar producto al carrito
  void addToCart(ProductDTO product, {int quantity = 1}) {
    final existingIndex = _cartItems.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (existingIndex >= 0) {
      _cartItems[existingIndex].quantity += quantity;
    } else {
      _cartItems.add(CartItem(product: product, quantity: quantity));
    }

    notifyListeners();
  }

  /// Remover producto del carrito
  void removeFromCart(String productId) {
    _cartItems.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  /// Actualizar cantidad de producto en carrito
  void updateQuantity(String productId, int newQuantity) {
    if (newQuantity <= 0) {
      removeFromCart(productId);
      return;
    }

    final index = _cartItems.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      _cartItems[index].quantity = newQuantity;
      notifyListeners();
    }
  }

  /// Limpiar carrito
  void clearCart() {
    _cartItems.clear();
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
