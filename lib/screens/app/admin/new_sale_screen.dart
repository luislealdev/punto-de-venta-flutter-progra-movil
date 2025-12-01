import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/product_dto.dart';
import '../../../models/product_variety_dto.dart';
import '../../../models/customer_dto.dart';
import '../../../models/sale_dto.dart';
import '../../../models/sale_item_dto.dart';
import '../../../services/product_service.dart';
import '../../../services/product_variety_service.dart';
import '../../../services/customer_service.dart';
import '../../../services/sale_service.dart';
import '../../../services/whatsapp_service.dart';
import '../../../services/auth_service.dart';

class NewSaleScreen extends StatefulWidget {
  const NewSaleScreen({super.key});

  @override
  State<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends State<NewSaleScreen> {
  final ProductService _productService = ProductService();
  final ProductVarietyService _varietyService = ProductVarietyService();
  final CustomerService _customerService = CustomerService();
  final SaleService _saleService = SaleService();
  final AuthService _authService = AuthService();

  final Color _primaryColor = const Color(0xFF1A237E);
  final Color _accentColor = const Color(0xFF00BFA5);
  final Color _backgroundColor = const Color(0xFFF5F7FA);

  // Estados principales
  String _companyId = '';
  List<ProductDTO> _products = [];
  List<ProductVarietyDTO> _varieties = [];
  List<CustomerDTO> _customers = [];
  List<SaleItemModel> _cartItems = [];

  // Estados de UI
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'all'; // all, products, varieties
  CustomerDTO? _selectedCustomer;
  String _paymentMethod = 'cash'; // cash, credit
  String _saleStep = 'products'; // products, customer, payment, summary

  // Modo edición
  bool _isEditMode = false;
  SaleDTO? _saleToEdit;

  // Controladores
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Verificar si se está en modo edición
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['editMode'] == true) {
      _isEditMode = true;
      _saleToEdit = args['saleToEdit'] as SaleDTO?;
      if (_saleToEdit != null) {
        _loadSaleForEditing();
      }
    }
  }

  Future<void> _initializeScreen() async {
    try {
      print('🔍 Iniciando pantalla de Nueva Venta...');

      // Primero inicializar el contexto del usuario
      await _authService.initializeContext();

      final userInfo = _authService.currentUserInfo;
      print('👤 UserInfo: ${userInfo?.companyId}');

      if (userInfo != null && userInfo.companyId != null) {
        setState(() => _companyId = userInfo.companyId!);
        print('🏢 CompanyId establecido: $_companyId');
        await _loadData();
      } else {
        // No hay usuario o companyId, detener loading y mostrar error
        print('❌ No hay userInfo o companyId');
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Error: No se pudo obtener la información de la empresa',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('💥 Error en inicialización: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al inicializar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadData() async {
    if (_companyId.isEmpty) {
      print('⚠️ CompanyId vacío, no se pueden cargar datos');
      setState(() => _isLoading = false);
      return;
    }

    try {
      print('📊 Cargando datos para companyId: $_companyId');
      setState(() => _isLoading = true);

      final results = await Future.wait([
        _productService.getActiveProducts(_companyId),
        _varietyService.getActiveVarieties(_companyId),
        _customerService.getActiveCustomers(_companyId),
      ]);

      print('✅ Datos cargados:');
      print('   - Productos: ${(results[0] as List).length}');
      print('   - Variedades: ${(results[1] as List).length}');
      print('   - Clientes: ${(results[2] as List).length}');

      setState(() {
        _products = results[0] as List<ProductDTO>;
        _varieties = results[1] as List<ProductVarietyDTO>;
        _customers = results[2] as List<CustomerDTO>;
        _isLoading = false;
      });

      print('🎉 Datos establecidos correctamente');
    } catch (e) {
      print('💥 Error al cargar datos: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadSaleForEditing() async {
    if (_saleToEdit == null) return;

    try {
      // Cargar items de la venta
      final saleItems = await _saleService.getSaleItems(
        _companyId,
        _saleToEdit!.id!,
      );

      // Convertir SaleItemDTO a SaleItemModel para el carrito
      final cartItems = <SaleItemModel>[];

      for (final item in saleItems) {
        String itemName = 'Producto/Variedad';
        String itemId = '';

        if (item.productId != null) {
          // Es un producto
          final product = _products
              .where((p) => p.id == item.productId)
              .firstOrNull;
          itemName = product?.name ?? 'Producto eliminado';
          itemId = 'product_${item.productId}';

          cartItems.add(
            SaleItemModel(
              id: itemId,
              productId: item.productId,
              name: itemName,
              quantity: item.quantity ?? 1,
              unitPrice: item.unitPrice ?? 0.0,
              subtotal: (item.quantity ?? 1) * (item.unitPrice ?? 0.0),
            ),
          );
        } else if (item.productVarietyId != null) {
          // Es una variedad
          final variety = _varieties
              .where((v) => v.id == item.productVarietyId)
              .firstOrNull;
          itemName = variety?.name ?? 'Variedad eliminada';
          itemId = 'variety_${item.productVarietyId}';

          cartItems.add(
            SaleItemModel(
              id: itemId,
              productVarietyId: item.productVarietyId,
              name: itemName,
              quantity: item.quantity ?? 1,
              unitPrice: item.unitPrice ?? 0.0,
              subtotal: (item.quantity ?? 1) * (item.unitPrice ?? 0.0),
            ),
          );
        }
      }

      // Buscar el cliente si existe
      CustomerDTO? selectedCustomer;
      if (_saleToEdit!.customerId != null) {
        try {
          selectedCustomer = _customers.firstWhere(
            (c) => c.id == _saleToEdit!.customerId,
          );
        } catch (e) {
          // Cliente no encontrado en la lista actual
          selectedCustomer = await _customerService.getById(
            _companyId,
            _saleToEdit!.customerId!,
          );
        }
      }

      setState(() {
        _cartItems = cartItems;
        _selectedCustomer = selectedCustomer;
        _paymentMethod = _saleToEdit!.paymentMethod ?? 'cash';
        _notesController.text = _saleToEdit!.notes ?? '';
      });

      print('✅ Venta cargada para edición: ${_cartItems.length} items');
    } catch (e) {
      print('💥 Error cargando venta para edición: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cargando venta: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<dynamic> get _filteredItems {
    List<dynamic> items = [];

    switch (_selectedFilter) {
      case 'products':
        items = _products;
        break;
      case 'varieties':
        items = _varieties;
        break;
      case 'all':
      default:
        items = [..._products, ..._varieties];
        break;
    }

    if (_searchQuery.isEmpty) return items;

    return items.where((item) {
      final name = item is ProductDTO
          ? item.name
          : (item as ProductVarietyDTO).name;
      return name!.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  double get _subtotal {
    return _cartItems.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  double get _total {
    return _subtotal;
  }

  void _addToCart(dynamic item) async {
    await _showQuantityModal(item);
  }

  Future<void> _showQuantityModal(dynamic item) async {
    final isProduct = item is ProductDTO;
    final name = isProduct ? item.name : (item as ProductVarietyDTO).name;
    final basePrice = isProduct
        ? item.basePrice
        : (item as ProductVarietyDTO).price;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QuantityModal(
        itemName: name!,
        basePrice: basePrice ?? 0.0,
        onAddToCart: (quantity, unitPrice) {
          final newItem = SaleItemModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            productId: isProduct
                ? item.id
                : (item as ProductVarietyDTO).productId,
            productVarietyId: isProduct ? null : (item as ProductVarietyDTO).id,
            name: name,
            quantity: quantity,
            unitPrice: unitPrice,
            subtotal: quantity * unitPrice,
          );

          setState(() {
            // Verificar si el item ya existe en el carrito
            final existingIndex = _cartItems.indexWhere(
              (cartItem) =>
                  cartItem.productId == newItem.productId &&
                  cartItem.productVarietyId == newItem.productVarietyId &&
                  cartItem.unitPrice == newItem.unitPrice,
            );

            if (existingIndex >= 0) {
              // Actualizar cantidad
              _cartItems[existingIndex] = _cartItems[existingIndex].copyWith(
                quantity: _cartItems[existingIndex].quantity + quantity,
                subtotal:
                    (_cartItems[existingIndex].quantity + quantity) * unitPrice,
              );
            } else {
              // Agregar nuevo item
              _cartItems.add(newItem);
            }
          });

          Navigator.pop(context);
        },
      ),
    );
  }

  void _removeFromCart(int index) {
    setState(() {
      _cartItems.removeAt(index);
    });
  }

  void _nextStep() {
    switch (_saleStep) {
      case 'products':
        if (_cartItems.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Agrega al menos un producto al carrito'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        setState(() => _saleStep = 'customer');
        break;
      case 'customer':
        setState(() => _saleStep = 'payment');
        break;
      case 'payment':
        setState(() => _saleStep = 'summary');
        break;
      case 'summary':
        _processSale();
        break;
    }
  }

  void _previousStep() {
    switch (_saleStep) {
      case 'customer':
        setState(() => _saleStep = 'products');
        break;
      case 'payment':
        setState(() => _saleStep = 'customer');
        break;
      case 'summary':
        setState(() => _saleStep = 'payment');
        break;
    }
  }

  Future<void> _processSale() async {
    if (_isEditMode) {
      await _updateSale();
    } else {
      await _createSale();
    }
  }

  Future<void> _updateSale() async {
    if (_saleToEdit == null) return;

    try {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Crear la venta actualizada
      final updatedSale = SaleDTO(
        id: _saleToEdit!.id,
        number: _saleToEdit!.number,
        customerId: _selectedCustomer?.id,
        createdBy: _saleToEdit!.createdBy,
        storeId: _saleToEdit!.storeId,
        companyId: _companyId,
        subtotal: _subtotal,
        tax: 0.0,
        total: _subtotal,
        paymentMethod: _paymentMethod,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        saleDate: _saleToEdit!.saleDate,
        status: 'completed',
        createdAt: _saleToEdit!.createdAt,
        updatedAt: DateTime.now(),
      );

      // Crear los items de la venta actualizados
      final saleItems = _cartItems
          .map(
            (cartItem) => SaleItemDTO(
              saleId: _saleToEdit!.id!,
              productId: cartItem.productId,
              productVarietyId: cartItem.productVarietyId,
              quantity: cartItem.quantity,
              unitPrice: cartItem.unitPrice,
              subtotal: cartItem.subtotal,
            ),
          )
          .toList();

      // Actualizar la venta en Firestore
      await _saleService.updateSaleWithItems(
        _companyId,
        _saleToEdit!.id!,
        updatedSale,
        saleItems,
      );

      print('✅ Venta actualizada: ${_saleToEdit!.number}');

      // Cerrar loading
      Navigator.pop(context);

      // Mostrar éxito y regresar con resultado
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Venta ${_saleToEdit!.number} actualizada exitosamente',
          ),
          backgroundColor: _accentColor,
          duration: const Duration(seconds: 3),
        ),
      );

      Navigator.pop(context, true); // true indica que se editó exitosamente
    } catch (e) {
      // Cerrar loading si está abierto
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar venta: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _createSale() async {
    try {
      // Validar creditLimit si es venta a crédito
      if (_paymentMethod == 'credit' && _selectedCustomer != null) {
        final customerCurrentDebt = _selectedCustomer!.currentDebt ?? 0.0;
        final customerCreditLimit = _selectedCustomer!.creditLimit ?? 0.0;

        if (customerCurrentDebt + _subtotal > customerCreditLimit) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'El límite de crédito será excedido. Límite: \$${customerCreditLimit.toStringAsFixed(2)}, '
                'Deuda actual: \$${customerCurrentDebt.toStringAsFixed(2)}, '
                'Total venta: \$${_subtotal.toStringAsFixed(2)}',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
          return;
        }
      }

      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Generar número de venta simple sin consultas complejas
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final saleNumber =
          'V${timestamp.toString().substring(timestamp.toString().length - 8)}';
      final storeId = 'default-store'; // Tienda por defecto

      print('🔢 Generando venta con número: $saleNumber');

      // Crear la venta
      final sale = SaleDTO(
        number: saleNumber,
        customerId: _selectedCustomer?.id,
        createdBy: _authService.currentUserInfo?.userId ?? '',
        storeId: storeId,
        companyId: _companyId,
        subtotal: _subtotal,
        tax: 0.0,
        total: _subtotal,
        paymentMethod: _paymentMethod,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        saleDate: DateTime.now(),
        status: 'completed',
      );

      // Crear los items de la venta
      final saleItems = _cartItems
          .map(
            (cartItem) => SaleItemDTO(
              saleId: '', // Se asignará en el servicio
              productId: cartItem.productId,
              productVarietyId: cartItem.productVarietyId,
              quantity: cartItem.quantity,
              unitPrice: cartItem.unitPrice,
              subtotal: cartItem.subtotal,
            ),
          )
          .toList();

      // Guardar la venta en Firestore
      final saleId = await _saleService.createSaleWithItems(
        _companyId,
        sale,
        saleItems,
      );

      print('✅ Venta creada con ID: $saleId');
      print('📍 Venta guardada en: companies/$_companyId/sales/$saleId');

      // Actualizar deuda del cliente si es venta a crédito
      CustomerDTO? updatedCustomer = _selectedCustomer;
      if (_paymentMethod == 'credit' && _selectedCustomer != null) {
        await _updateCustomerDebt(_selectedCustomer!.id!, _subtotal);
        // Obtener el cliente actualizado para WhatsApp
        updatedCustomer = await _customerService.getById(
          _companyId,
          _selectedCustomer!.id!,
        );
        print(
          '💳 Cliente actualizado - Deuda: \$${updatedCustomer?.currentDebt ?? 0}',
        );
      }

      // Cerrar loading
      Navigator.pop(context);

      // Enviar WhatsApp con datos actualizados
      if (updatedCustomer != null && updatedCustomer.phone != null) {
        await _sendWhatsAppNotification(saleNumber, updatedCustomer);
      }

      // Mostrar éxito y regresar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Venta #$saleNumber creada exitosamente'),
          backgroundColor: _accentColor,
          duration: const Duration(seconds: 3),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      // Cerrar loading si está abierto
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear venta: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _updateCustomerDebt(String customerId, double amount) async {
    try {
      // Obtener el cliente actualizado
      final customer = await _customerService.getById(_companyId, customerId);
      if (customer != null) {
        final updatedCustomer = CustomerDTO(
          id: customer.id,
          name: customer.name,
          email: customer.email,
          phone: customer.phone,
          address: customer.address,
          taxId: customer.taxId,
          creditLimit: customer.creditLimit,
          currentDebt: (customer.currentDebt ?? 0.0) + amount,
          customerType: customer.customerType,
          companyId: customer.companyId,
          isActive: customer.isActive,
          createdAt: customer.createdAt,
        );

        await _customerService.update(_companyId, customerId, updatedCustomer);
        print(
          '✅ Deuda del cliente actualizada: +\$${amount.toStringAsFixed(2)}',
        );
      }
    } catch (e) {
      print('❌ Error al actualizar deuda del cliente: $e');
      // No fallar la venta por esto, solo loguearlo
    }
  }

  Future<void> _sendWhatsAppNotification(
    String saleNumber,
    CustomerDTO customer,
  ) async {
    try {
      if (customer.phone == null || customer.phone!.isEmpty) {
        print('⚠️ Cliente no tiene teléfono registrado');
        return;
      }

      final message = WhatsAppService.buildSaleReceiptMessage(
        saleNumber: saleNumber,
        customer: customer,
        total: _subtotal,
        paymentMethod: _paymentMethod,
        items: _cartItems
            .map(
              (item) => SaleItemInfo(
                name: item.name,
                quantity: item.quantity,
                subtotal: item.subtotal,
              ),
            )
            .toList(),
      );

      final success = await WhatsAppService.sendMessage(
        phoneNumber: customer.phone!,
        message: message,
      );

      if (success) {
        print('✅ WhatsApp enviado exitosamente a ${customer.name}');
      } else {
        print('❌ Error enviando WhatsApp a ${customer.name}');
      }
    } catch (e) {
      print('❌ Error en WhatsApp: $e');
      // No fallar la venta por problemas de WhatsApp
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          _isEditMode ? 'Editar Venta' : 'Nueva Venta',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildStepIndicator('Productos', 'products'),
                _buildStepConnector(),
                _buildStepIndicator('Cliente', 'customer'),
                _buildStepConnector(),
                _buildStepIndicator('Pago', 'payment'),
                _buildStepConnector(),
                _buildStepIndicator('Resumen', 'summary'),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Cargando datos de venta...'),
                ],
              ),
            )
          : _companyId.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'No se pudo cargar la información de la empresa',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _initializeScreen,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(child: _buildStepContent()),
                _buildBottomBar(),
              ],
            ),
    );
  }

  Widget _buildStepIndicator(String title, String step) {
    final isActive = _saleStep == step;
    final isCompleted = _getStepIndex(_saleStep) > _getStepIndex(step);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.white
            : isCompleted
            ? _accentColor
            : Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: isActive
              ? _primaryColor
              : isCompleted
              ? Colors.white
              : Colors.white.withOpacity(0.7),
          fontSize: 12,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildStepConnector() {
    return Expanded(
      child: Container(
        height: 2,
        color: Colors.white.withOpacity(0.3),
        margin: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }

  int _getStepIndex(String step) {
    switch (step) {
      case 'products':
        return 0;
      case 'customer':
        return 1;
      case 'payment':
        return 2;
      case 'summary':
        return 3;
      default:
        return 0;
    }
  }

  Widget _buildStepContent() {
    switch (_saleStep) {
      case 'products':
        return _buildProductsStep();
      case 'customer':
        return _buildCustomerStep();
      case 'payment':
        return _buildPaymentStep();
      case 'summary':
        return _buildSummaryStep();
      default:
        return _buildProductsStep();
    }
  }

  Widget _buildProductsStep() {
    return Column(
      children: [
        // Barra de búsqueda y filtros
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Buscar productos...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildFilterChip('Todos', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Productos', 'products'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Variedades', 'varieties'),
                ],
              ),
            ],
          ),
        ),

        // Lista de productos/variedades
        Expanded(
          child: _filteredItems.isEmpty
              ? const Center(
                  child: Text(
                    'No se encontraron productos',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = _filteredItems[index];
                    final isProduct = item is ProductDTO;
                    final name = isProduct
                        ? item.name
                        : (item as ProductVarietyDTO).name;
                    final price = isProduct
                        ? item.basePrice
                        : (item as ProductVarietyDTO).price;
                    final imageUrl = isProduct
                        ? (item as ProductDTO).imageUrl
                        : null;

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: InkWell(
                        onTap: () => _addToCart(item),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _accentColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  image: imageUrl != null
                                      ? DecorationImage(
                                          image: NetworkImage(imageUrl),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: imageUrl == null
                                    ? Center(
                                        child: Icon(
                                          isProduct
                                              ? Icons.inventory_2
                                              : Icons.style,
                                          color: _accentColor,
                                          size: 20,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                name ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '\$${price?.toStringAsFixed(2) ?? '0.00'}',
                                style: TextStyle(
                                  color: _primaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _primaryColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  '+',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedFilter = value);
      },
      backgroundColor: Colors.white,
      selectedColor: _accentColor.withOpacity(0.2),
      checkmarkColor: _accentColor,
    );
  }

  Widget _buildCustomerStep() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Seleccionar Cliente (Opcional)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Puedes continuar sin seleccionar un cliente para venta de mostrador',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _customers.length + 1, // +1 para "Sin cliente"
            itemBuilder: (context, index) {
              if (index == 0) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey[300],
                      child: const Icon(Icons.person_off, color: Colors.grey),
                    ),
                    title: const Text('Venta de Mostrador'),
                    subtitle: const Text('Sin cliente específico'),
                    trailing: _selectedCustomer == null
                        ? Icon(Icons.check_circle, color: _accentColor)
                        : null,
                    onTap: () {
                      setState(() => _selectedCustomer = null);
                    },
                  ),
                );
              }

              final customer = _customers[index - 1];
              final isSelected = _selectedCustomer?.id == customer.id;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _accentColor,
                    child: Text(
                      customer.name!.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(customer.name ?? ''),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (customer.email != null) Text(customer.email!),
                      if (customer.currentDebt != null &&
                          customer.currentDebt! > 0)
                        Text(
                          'Deuda: \$${customer.currentDebt!.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.orange),
                        ),
                    ],
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_circle, color: _accentColor)
                      : null,
                  onTap: () {
                    setState(() => _selectedCustomer = customer);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentStep() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Método de Pago',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 16),

          Card(
            child: Column(
              children: [
                RadioListTile<String>(
                  title: const Text('Efectivo'),
                  subtitle: const Text('Pago inmediato en efectivo'),
                  value: 'cash',
                  groupValue: _paymentMethod,
                  activeColor: _primaryColor,
                  onChanged: (value) {
                    setState(() => _paymentMethod = value!);
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Tarjeta'),
                  subtitle: const Text('Pago con tarjeta de crédito/débito'),
                  value: 'card',
                  groupValue: _paymentMethod,
                  activeColor: _primaryColor,
                  onChanged: (value) {
                    setState(() => _paymentMethod = value!);
                  },
                ),
                if (_selectedCustomer != null)
                  RadioListTile<String>(
                    title: const Text('Crédito'),
                    subtitle: const Text('Agregar a cuenta del cliente'),
                    value: 'credit',
                    groupValue: _paymentMethod,
                    activeColor: _primaryColor,
                    onChanged: (value) {
                      setState(() => _paymentMethod = value!);
                    },
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'Notas (Opcional)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 8),

          TextField(
            controller: _notesController,
            decoration: InputDecoration(
              hintText: 'Agregar notas sobre la venta...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen de Venta',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 16),

          // Información del cliente
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.person, color: _primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Cliente'),
                        Text(
                          _selectedCustomer?.name ?? 'Venta de mostrador',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Información de pago
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.payment, color: _primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Método de Pago'),
                        Text(
                          _getPaymentMethodName(_paymentMethod),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Productos
          Text(
            'Productos (${_cartItems.length})',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 8),

          ..._cartItems.map(
            (item) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${item.quantity} x \$${item.unitPrice.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '\$${item.subtotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Totales
          Card(
            color: _primaryColor.withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal:'),
                      Text('\$${_subtotal.toStringAsFixed(2)}'),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor,
                        ),
                      ),
                      Text(
                        '\$${_total.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getPaymentMethodName(String method) {
    switch (method) {
      case 'cash':
        return 'Efectivo';
      case 'card':
        return 'Tarjeta';
      case 'credit':
        return 'Crédito';
      default:
        return 'Efectivo';
    }
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Carrito resumen
          if (_saleStep == 'products' && _cartItems.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.shopping_cart, color: _accentColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_cartItems.length} productos - \$${_subtotal.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _accentColor,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.list),
                    color: _accentColor,
                    onPressed: _showCartModal,
                  ),
                ],
              ),
            ),

          // Botones de navegación
          Row(
            children: [
              if (_saleStep != 'products')
                Expanded(
                  child: OutlinedButton(
                    onPressed: _previousStep,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: _primaryColor),
                    ),
                    child: Text(
                      'Anterior',
                      style: TextStyle(color: _primaryColor),
                    ),
                  ),
                ),

              if (_saleStep != 'products') const SizedBox(width: 16),

              Expanded(
                flex: _saleStep == 'products' ? 1 : 1,
                child: ElevatedButton(
                  onPressed: _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(_getNextButtonText()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getNextButtonText() {
    switch (_saleStep) {
      case 'products':
        return 'Continuar';
      case 'customer':
        return 'Método de Pago';
      case 'payment':
        return 'Revisar Venta';
      case 'summary':
        return 'Crear Venta';
      default:
        return 'Continuar';
    }
  }

  void _showCartModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _primaryColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Carrito de Compras',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _cartItems.isEmpty
                  ? const Center(
                      child: Text(
                        'El carrito está vacío',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _cartItems.length,
                      itemBuilder: (context, index) {
                        final item = _cartItems[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '${item.quantity} x \$${item.unitPrice.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '\$${item.subtotal.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    _removeFromCart(index);
                                    Navigator.pop(context);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}

// Modelo para items del carrito
class SaleItemModel {
  final String id;
  final String? productId;
  final String? productVarietyId;
  final String name;
  final double quantity;
  final double unitPrice;
  final double subtotal;

  SaleItemModel({
    required this.id,
    this.productId,
    this.productVarietyId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  SaleItemModel copyWith({
    String? id,
    String? productId,
    String? productVarietyId,
    String? name,
    double? quantity,
    double? unitPrice,
    double? subtotal,
  }) {
    return SaleItemModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productVarietyId: productVarietyId ?? this.productVarietyId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      subtotal: subtotal ?? this.subtotal,
    );
  }
}

// Modal para seleccionar cantidad y precio
class QuantityModal extends StatefulWidget {
  final String itemName;
  final double basePrice;
  final Function(double quantity, double unitPrice) onAddToCart;

  const QuantityModal({
    super.key,
    required this.itemName,
    required this.basePrice,
    required this.onAddToCart,
  });

  @override
  State<QuantityModal> createState() => _QuantityModalState();
}

class _QuantityModalState extends State<QuantityModal> {
  final TextEditingController _customQuantityController =
      TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  String _priceOption = 'base'; // base, custom
  String _quantityOption = 'preset'; // preset, custom
  double _quantity = 1.0;
  double _unitPrice = 0.0;

  final List<double> _presetQuantities = [1, 5, 10, 15, 25, 50];

  @override
  void initState() {
    super.initState();
    _unitPrice = widget.basePrice;
    _priceController.text = widget.basePrice.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF1A237E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.itemName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Cantidad',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // Cantidades predefinidas
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _presetQuantities
                        .map(
                          (qty) => GestureDetector(
                            onTap: () {
                              setState(() {
                                _quantity = qty;
                                _quantityOption = 'preset';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _quantity == qty
                                    ? const Color(0xFF1A237E)
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _quantity == qty
                                      ? const Color(0xFF1A237E)
                                      : Colors.grey[300]!,
                                ),
                              ),
                              child: Text(
                                qty.toString(),
                                style: TextStyle(
                                  color: _quantity == qty
                                      ? Colors.white
                                      : Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),

                  const SizedBox(height: 12),

                  // Opción de cantidad personalizada
                  Row(
                    children: [
                      Checkbox(
                        value: _quantityOption == 'custom',
                        onChanged: (value) {
                          setState(() {
                            _quantityOption = value! ? 'custom' : 'preset';
                            if (_quantityOption == 'custom') {
                              _customQuantityController.text = _quantity
                                  .toString();
                            }
                          });
                        },
                      ),
                      const Text('Cantidad personalizada'),
                    ],
                  ),

                  if (_quantityOption == 'custom') ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: _customQuantityController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Ingresa cantidad',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _quantity = double.tryParse(value) ?? 1.0;
                        });
                      },
                    ),
                  ],

                  const SizedBox(height: 24),

                  const Text(
                    'Precio',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: Text(
                            'Base (\$${widget.basePrice.toStringAsFixed(2)})',
                          ),
                          value: 'base',
                          groupValue: _priceOption,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (value) {
                            setState(() {
                              _priceOption = value!;
                              _unitPrice = widget.basePrice;
                              _priceController.text = widget.basePrice
                                  .toStringAsFixed(2);
                            });
                          },
                        ),
                      ),
                    ],
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Personalizado'),
                          value: 'custom',
                          groupValue: _priceOption,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (value) {
                            setState(() {
                              _priceOption = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),

                  if (_priceOption == 'custom') ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Precio unitario',
                        prefixText: '\$',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _unitPrice =
                              double.tryParse(value) ?? widget.basePrice;
                        });
                      },
                    ),
                  ],

                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00BFA5).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Subtotal:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '\$${(_quantity * _unitPrice).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00BFA5),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () =>
                          widget.onAddToCart(_quantity, _unitPrice),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A237E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Agregar al Carrito'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _customQuantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }
}
