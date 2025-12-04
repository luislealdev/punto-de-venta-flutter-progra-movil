import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/customer_dto.dart';
import '../../../services/customer_service.dart';
import '../../../services/auth_service.dart';
import '../../../providers/customer_provider.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final CustomerService _customerService = CustomerService();
  final AuthService _authService = AuthService();
  final Color _primaryColor = const Color(0xFF1A237E);
  final Color _accentColor = const Color(0xFF00BFA5);
  final Color _backgroundColor = const Color(0xFFF5F7FA);
  
  final TextEditingController _searchController = TextEditingController();
  String? _companyId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    // Asegurar que el contexto del usuario esté cargado
    if (_authService.currentCompanyId == null) {
      await _authService.initializeContext();
    }
    
    _companyId = _authService.currentCompanyId;
    
    if (_companyId != null) {
      // Cargar clientes solo si la lista está vacía para evitar recargas innecesarias
      final provider = Provider.of<CustomerProvider>(context, listen: false);
      if (provider.customers.isEmpty) {
        // Usar addPostFrameCallback para evitar errores de construcción si se llama desde initState
        WidgetsBinding.instance.addPostFrameCallback((_) {
          provider.loadCustomers(_companyId!);
        });
      }
    }
  }

  Future<void> _refreshCustomers() async {
    if (_companyId != null) {
      await Provider.of<CustomerProvider>(context, listen: false).loadCustomers(_companyId!);
    }
  }

  void _filterCustomers(String searchTerm) {
    Provider.of<CustomerProvider>(context, listen: false).filterCustomers(searchTerm);
  }

  void _navigateToAddCustomer() {
    Navigator.pushNamed(
      context, 
      '/customers/add',
      arguments: {'companyId': _companyId}
    ).then((_) => _refreshCustomers());
  }

  void _navigateToEditCustomer(CustomerDTO customer) {
    Navigator.pushNamed(
      context, 
      '/customers/edit',
      arguments: {'customer': customer, 'companyId': _companyId}
    ).then((_) => _refreshCustomers());
  }

  Future<void> _deleteCustomer(CustomerDTO customer) async {
    if (_companyId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Cliente'),
        content: Text('¿Estás seguro de que deseas eliminar a "${customer.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _customerService.toggleCustomerStatus(_companyId!, customer.id!, false);
        _refreshCustomers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cliente "${customer.name}" eliminado')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar cliente: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _getCustomerTypeText(String? customerType) {
    switch (customerType) {
      case 'individual':
        return 'Persona Física';
      case 'business':
        return 'Empresa';
      default:
        return 'Persona Física';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        title: const Text(
          'Clientes',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _accentColor,
        onPressed: _navigateToAddCustomer,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: _filterCustomers,
              decoration: InputDecoration(
                hintText: 'Buscar clientes...',
                prefixIcon: Icon(Icons.search, color: _primaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _primaryColor, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ),
          
          // Lista de clientes
          Expanded(
            child: Consumer<CustomerProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return Center(
                    child: CircularProgressIndicator(color: _primaryColor),
                  );
                }

                if (provider.filteredCustomers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          provider.customers.isEmpty 
                              ? 'No hay clientes registrados'
                              : 'No se encontraron clientes',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (provider.customers.isEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Agrega tu primer cliente para comenzar',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refreshCustomers,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: provider.filteredCustomers.length,
                    itemBuilder: (context, index) {
                      final customer = provider.filteredCustomers[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16.0),
                          leading: CircleAvatar(
                            backgroundColor: _primaryColor.withOpacity(0.1),
                            child: Icon(
                              customer.customerType == 'business' 
                                ? Icons.business
                                : Icons.person,
                              color: _primaryColor,
                            ),
                          ),
                          title: Text(
                            customer.name ?? 'Sin nombre',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (customer.email?.isNotEmpty ?? false) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.email, size: 16, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        customer.email!,
                                        style: TextStyle(color: Colors.grey[600]),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (customer.phone?.isNotEmpty ?? false) ...[
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text(
                                      customer.phone!,
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: customer.customerType == 'business' 
                                        ? Colors.blue.withOpacity(0.1)
                                        : Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _getCustomerTypeText(customer.customerType),
                                      style: TextStyle(
                                        color: customer.customerType == 'business' 
                                          ? Colors.blue
                                          : Colors.green,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  if ((customer.currentDebt ?? 0) > 0) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Deuda: \$${customer.currentDebt!.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          color: Colors.orange,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              switch (value) {
                                case 'edit':
                                  _navigateToEditCustomer(customer);
                                  break;
                                case 'delete':
                                  _deleteCustomer(customer);
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_outlined),
                                    SizedBox(width: 8),
                                    Text('Editar'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Eliminar', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}