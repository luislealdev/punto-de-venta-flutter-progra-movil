import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/provider_dto.dart';
import '../../../services/provider_service.dart';
import '../../../services/auth_service.dart';
import '../../../providers/supplier_provider.dart';
import 'add_edit_provider_screen.dart';

class ProvidersScreen extends StatefulWidget {
  const ProvidersScreen({super.key});

  @override
  State<ProvidersScreen> createState() => _ProvidersScreenState();
}

class _ProvidersScreenState extends State<ProvidersScreen> {
  final ProviderService _providerService = ProviderService();
  final AuthService _authService = AuthService();
  
  final Color _primaryColor = const Color(0xFF1A237E);
  final Color _accentColor = const Color(0xFF00BFA5);
  final Color _backgroundColor = const Color(0xFFF5F7FA);

  List<ProviderDTO> _providers = [];
  List<ProviderDTO> _filteredProviders = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  String? _companyId;

  @override
  void initState() {
    super.initState();
    // Usar addPostFrameCallback para evitar errores de construcción
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
      await _loadProviders();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadProviders() async {
    if (_companyId == null) return;
    
    final supplierProvider = Provider.of<SupplierProvider>(context, listen: false);
    
    if (supplierProvider.providers.isNotEmpty) {
      setState(() {
        _providers = supplierProvider.providers.where((p) => p.isActive == true).toList();
        _filteredProviders = _providers;
        _isLoading = false;
      });
      return;
    }

    try {
      setState(() => _isLoading = true);
      await supplierProvider.loadProviders(_companyId!);
      
      if (mounted) {
        setState(() {
          _providers = supplierProvider.providers.where((p) => p.isActive == true).toList();
          _filteredProviders = _providers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar proveedores: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterProviders(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredProviders = _providers;
      } else {
        _filteredProviders = _providers.where((provider) {
          return provider.name!.toLowerCase().contains(query.toLowerCase()) ||
                 (provider.email?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
                 (provider.phone?.contains(query) ?? false);
        }).toList();
      }
    });
  }

  Future<void> _navigateToAddEditProvider({ProviderDTO? provider}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditProviderScreen(
          companyId: _companyId ?? '',
          provider: provider,
        ),
      ),
    );

    if (result == true) {
      _loadProviders();
    }
  }

  Future<void> _toggleProviderStatus(ProviderDTO provider) async {
    if (_companyId == null) return;
    
    try {
      await _providerService.toggleProviderStatus(_companyId!, provider.id!, !provider.isActive!);
      _loadProviders();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              provider.isActive! 
                ? 'Proveedor "${provider.name}" desactivado'
                : 'Proveedor "${provider.name}" activado',
            ),
            backgroundColor: _accentColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteProvider(ProviderDTO provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text('¿Estás seguro de que deseas eliminar el proveedor "${provider.name}"?'),
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
      if (_companyId == null) return;
      
      try {
        await _providerService.delete(_companyId!, provider.id!);
        _loadProviders();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Proveedor "${provider.name}" eliminado'),
              backgroundColor: _accentColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Proveedores',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProviders,
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _primaryColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Buscar proveedores...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.white.withOpacity(0.7),
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.white),
                              onPressed: () {
                                _searchController.clear();
                                _filterProviders('');
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
                    onChanged: _filterProviders,
                  ),
                ),
              ],
            ),
          ),
          
          // Lista de proveedores
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProviders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _searchQuery.isEmpty ? Icons.store : Icons.search_off,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'No hay proveedores registrados'
                                  : 'No se encontraron proveedores',
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadProviders,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredProviders.length,
                          itemBuilder: (context, index) {
                            final provider = _filteredProviders[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: CircleAvatar(
                                  backgroundColor: _accentColor,
                                  child: Icon(
                                    Icons.store,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        provider.name ?? '',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    if (!provider.isActive!)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Colors.red.withOpacity(0.3),
                                          ),
                                        ),
                                        child: const Text(
                                          'INACTIVO',
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (provider.email != null) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.email,
                                            size: 16,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            provider.email!,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    if (provider.phone != null) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.phone,
                                            size: 16,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            provider.phone!,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    if (provider.address != null) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.location_on,
                                            size: 16,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              provider.address!,
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 14,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    switch (value) {
                                      case 'edit':
                                        _navigateToAddEditProvider(provider: provider);
                                        break;
                                      case 'toggle':
                                        _toggleProviderStatus(provider);
                                        break;
                                      case 'delete':
                                        _confirmDeleteProvider(provider);
                                        break;
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit),
                                          SizedBox(width: 8),
                                          Text('Editar'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'toggle',
                                      child: Row(
                                        children: [
                                          Icon(
                                            provider.isActive! 
                                              ? Icons.visibility_off 
                                              : Icons.visibility,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            provider.isActive! 
                                              ? 'Desactivar' 
                                              : 'Activar',
                                          ),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text(
                                            'Eliminar',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () => _navigateToAddEditProvider(provider: provider),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddEditProvider(),
        backgroundColor: _accentColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}