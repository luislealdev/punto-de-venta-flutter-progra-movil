import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/sale_dto.dart';
import '../../../models/customer_dto.dart';
import '../../../services/sale_service.dart';
import '../../../services/customer_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/whatsapp_service.dart';
import '../../../config/app_config.dart';
import '../../../providers/sale_provider.dart';
import '../../../providers/customer_provider.dart';

class SalesManagementScreen extends StatefulWidget {
  const SalesManagementScreen({super.key});

  @override
  State<SalesManagementScreen> createState() => _SalesManagementScreenState();
}

class _SalesManagementScreenState extends State<SalesManagementScreen> {
  final SaleService _saleService = SaleService();
  final CustomerService _customerService = CustomerService();
  final AuthService _authService = AuthService();

  final Color _primaryColor = const Color(0xFF1A237E);
  final Color _accentColor = const Color(0xFF00BFA5);
  final Color _backgroundColor = const Color(0xFFF5F7FA);

  List<SaleDTO> _sales = [];
  List<SaleDTO> _filteredSales = [];
  Map<String, CustomerDTO> _customersCache = {};
  bool _isLoading = true;
  String _searchQuery = '';
  String _companyId = '';
  String _selectedPaymentFilter = 'all';
  DateTime? _startDate;
  DateTime? _endDate;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreen();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeScreen() async {
    try {
      print('🔄 Inicializando pantalla de gestión de ventas...');
      
      // Inicializar contexto del AuthService
      await _authService.initializeContext();
      print('✅ AuthService inicializado');
      
      final userInfo = _authService.currentUserInfo;
      print('👤 Usuario actual: ${userInfo?.displayName ?? userInfo?.userId}');
      print('🏢 Company ID: ${userInfo?.companyId}');
      
      if (userInfo != null && userInfo.companyId != null) {
        setState(() => _companyId = userInfo.companyId!);
        await _loadSales();
        await _loadCustomers();
      } else {
        setState(() => _isLoading = false);
        print('❌ No se pudo obtener companyId del usuario');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo obtener información de la empresa'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      setState(() => _isLoading = false);
      print('❌ Error al inicializar: $e');
      print('🔍 Stack trace: $stackTrace');
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

  Future<void> _loadSales() async {
    if (_companyId.isEmpty) return;
    
    final saleProvider = Provider.of<SaleProvider>(context, listen: false);
    
    if (saleProvider.sales.isNotEmpty) {
      setState(() {
        _sales = saleProvider.sales;
        _filteredSales = _sales;
        _isLoading = false;
      });
      _applyFilters();
      return;
    }

    try {
      setState(() => _isLoading = true);
      
      await saleProvider.loadSales(_companyId);
      
      if (mounted) {
        setState(() {
          _sales = saleProvider.sales;
          _filteredSales = _sales;
          _isLoading = false;
        });
        _applyFilters();
      }
    } catch (e) {
      print('❌ Error al cargar ventas: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCustomers() async {
    try {
      final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
      if (customerProvider.customers.isEmpty) {
        await customerProvider.loadCustomers(_companyId);
      }
      
      if (mounted) {
        setState(() {
          _customersCache = {for (var customer in customerProvider.customers) customer.id!: customer};
        });
      }
    } catch (e) {
      print('❌ Error cargando clientes: $e');
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredSales = _sales.where((sale) {
        // Filtro de búsqueda por texto
        final customerName = _getCustomerName(sale.customerId);
        bool matchesSearch = _searchQuery.isEmpty ||
            sale.number!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            customerName.toLowerCase().contains(_searchQuery.toLowerCase());

        // Filtro por método de pago
        bool matchesPayment = _selectedPaymentFilter == 'all' ||
            sale.paymentMethod == _selectedPaymentFilter;

        // Filtro por fechas
        bool matchesDate = true;
        if (_startDate != null || _endDate != null) {
          final saleDate = sale.saleDate;
          if (saleDate != null) {
            if (_startDate != null && saleDate.isBefore(_startDate!)) {
              matchesDate = false;
            }
            if (_endDate != null && saleDate.isAfter(_endDate!.add(const Duration(days: 1)))) {
              matchesDate = false;
            }
          }
        }

        return matchesSearch && matchesPayment && matchesDate;
      }).toList();

      // Ordenar por fecha más reciente primero
      _filteredSales.sort((a, b) => (b.saleDate ?? DateTime(1970)).compareTo(a.saleDate ?? DateTime(1970)));
    });
  }

  void _filterSales(String query) {
    setState(() {
      _searchQuery = query;
    });
    _applyFilters();
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _applyFilters();
    }
  }

  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _applyFilters();
  }

  // Helper para obtener el nombre del cliente
  String _getCustomerName(String? customerId) {
    if (customerId == null) return 'Cliente General';
    final customer = _customersCache[customerId];
    return customer?.name ?? 'Cliente General';
  }

  Future<void> _editSale(SaleDTO sale) async {
    // Navegar a la pantalla de nueva venta en modo edición
    final result = await Navigator.pushNamed(
      context,
      '/new-sale',
      arguments: {
        'editMode': true,
        'saleToEdit': sale,
        'companyId': _companyId,
      },
    );

    if (result == true) {
      // Recargar ventas si se editó exitosamente
      await _loadSales();
    }
  }

  Future<void> _deleteSale(SaleDTO sale) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Estás seguro de que deseas eliminar la venta?'),
            const SizedBox(height: 8),
            Text('Número: ${sale.number}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Cliente: ${_getCustomerName(sale.customerId)}'),
            Text('Total: \$${sale.total?.toStringAsFixed(2) ?? '0.00'}'),
            const SizedBox(height: 8),
            const Text('Esta acción no se puede deshacer y se actualizará el balance del cliente.',
                style: TextStyle(color: Colors.red, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Mostrar loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        await _saleService.deleteSaleWithItems(_companyId, sale.id!, sale);
        
        // Cerrar loading
        Navigator.pop(context);

        // Enviar notificación WhatsApp si está configurado
        if (AppConfig.isWhatsappConfigured && 
            sale.customerId != null && 
            _customersCache[sale.customerId] != null) {
          final customer = _customersCache[sale.customerId]!;
          if (customer.phone != null && customer.phone!.isNotEmpty) {
            try {
              // Obtener cliente actualizado (con deuda actualizada)
              final updatedCustomer = await _customerService.getById(_companyId, sale.customerId!);
              if (updatedCustomer != null) {
                final message = WhatsAppService.buildSaleDeletedMessage(
                  customer: updatedCustomer,
                  saleNumber: sale.number!,
                  deletedAmount: sale.total ?? 0.0,
                );
                
                final success = await WhatsAppService.sendMessage(
                  phoneNumber: updatedCustomer.phone!,
                  message: message,
                );
                
                if (success) {
                  print('✅ WhatsApp de eliminación enviado a ${updatedCustomer.name}');
                } else {
                  print('❌ Error enviando WhatsApp a ${updatedCustomer.name}');
                }
              }
            } catch (e) {
              print('❌ Error enviando WhatsApp: $e');
            }
          }
        }

        // Recargar ventas
        await _loadSales();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Venta ${sale.number} eliminada exitosamente'),
              backgroundColor: _accentColor,
            ),
          );
        }
      } catch (e) {
        // Cerrar loading si está abierto
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar venta: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildFilterChip(String label, String value, String currentValue) {
    final isSelected = currentValue == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedPaymentFilter = value;
        });
        _applyFilters();
      },
      backgroundColor: isSelected ? _primaryColor.withOpacity(0.1) : null,
      selectedColor: _primaryColor.withOpacity(0.2),
    );
  }

  Widget _buildSaleCard(SaleDTO sale) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getPaymentMethodColor(sale.paymentMethod ?? 'cash'),
          child: Icon(
            _getPaymentMethodIcon(sale.paymentMethod ?? 'cash'),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          'Venta ${sale.number}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cliente: ${_getCustomerName(sale.customerId)}'),
            Text('Fecha: ${sale.saleDate != null ? dateFormat.format(sale.saleDate!) : 'N/A'}'),
            Text(
              'Total: \$${sale.total?.toStringAsFixed(2) ?? '0.00'}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _primaryColor,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _editSale(sale);
                break;
              case 'delete':
                _deleteSale(sale);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Editar'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Eliminar', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        onTap: () => _showSaleDetails(sale),
      ),
    );
  }

  Color _getPaymentMethodColor(String method) {
    switch (method) {
      case 'cash':
        return Colors.green;
      case 'card':
        return Colors.blue;
      case 'credit':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getPaymentMethodIcon(String method) {
    switch (method) {
      case 'cash':
        return Icons.money;
      case 'card':
        return Icons.credit_card;
      case 'credit':
        return Icons.credit_score;
      default:
        return Icons.payment;
    }
  }

  void _showSaleDetails(SaleDTO sale) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Venta ${sale.number}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Cliente', _getCustomerName(sale.customerId)),
              _buildDetailRow('Fecha', sale.saleDate != null ? dateFormat.format(sale.saleDate!) : 'N/A'),
              _buildDetailRow('Método de pago', _getPaymentMethodLabel(sale.paymentMethod ?? 'cash')),
              _buildDetailRow('Subtotal', '\$${sale.subtotal?.toStringAsFixed(2) ?? '0.00'}'),
              _buildDetailRow('Total', '\$${sale.total?.toStringAsFixed(2) ?? '0.00'}'),
              if (sale.notes != null && sale.notes!.isNotEmpty)
                _buildDetailRow('Notas', sale.notes!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _editSale(sale);
            },
            child: const Text('Editar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _getPaymentMethodLabel(String method) {
    switch (method) {
      case 'cash':
        return 'Efectivo';
      case 'card':
        return 'Tarjeta';
      case 'credit':
        return 'Crédito';
      default:
        return method;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Gestión de Ventas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Barra de búsqueda y filtros
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _primaryColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                // Búsqueda
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por número de venta o cliente...',
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                    ),
                    prefixIcon: const Icon(Icons.search, color: Colors.white),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white),
                            onPressed: () {
                              _searchController.clear();
                              _filterSales('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.2),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: _filterSales,
                ),
                
                const SizedBox(height: 16),
                
                // Filtros
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Todos', 'all', _selectedPaymentFilter),
                      const SizedBox(width: 8),
                      _buildFilterChip('Efectivo', 'cash', _selectedPaymentFilter),
                      const SizedBox(width: 8),
                      _buildFilterChip('Tarjeta', 'card', _selectedPaymentFilter),
                      const SizedBox(width: 8),
                      _buildFilterChip('Crédito', 'credit', _selectedPaymentFilter),
                      const SizedBox(width: 16),
                      // Filtro de fechas
                      ElevatedButton.icon(
                        onPressed: _selectDateRange,
                        icon: const Icon(Icons.date_range),
                        label: Text(_startDate != null && _endDate != null
                            ? '${DateFormat('dd/MM').format(_startDate!)} - ${DateFormat('dd/MM').format(_endDate!)}'
                            : 'Fechas'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          foregroundColor: Colors.white,
                        ),
                      ),
                      if (_startDate != null || _endDate != null) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _clearDateFilter,
                          icon: const Icon(Icons.clear, color: Colors.white),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Lista de ventas
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredSales.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _searchQuery.isNotEmpty || _selectedPaymentFilter != 'all' || _startDate != null
                                  ? Icons.search_off
                                  : Icons.receipt_long,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty || _selectedPaymentFilter != 'all' || _startDate != null
                                  ? 'No se encontraron ventas con los filtros aplicados'
                                  : 'No hay ventas registradas',
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadSales,
                        child: ListView.builder(
                          itemCount: _filteredSales.length,
                          itemBuilder: (context, index) {
                            return _buildSaleCard(_filteredSales[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}