import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/store_dto.dart';
import '../../../services/store_service.dart';
import '../../../services/auth_service.dart';
import '../../../providers/store_provider.dart';
import 'add_edit_store_screen.dart';

class StoresScreen extends StatefulWidget {
  const StoresScreen({super.key});

  @override
  State<StoresScreen> createState() => _StoresScreenState();
}

class _StoresScreenState extends State<StoresScreen> {
  final StoreService _storeService = StoreService();
  final AuthService _authService = AuthService();
  
  final Color _primaryColor = const Color(0xFF1A237E);
  final Color _accentColor = const Color(0xFF00BFA5);
  final Color _backgroundColor = const Color(0xFFF5F7FA);

  List<StoreDTO> _stores = [];
  List<StoreDTO> _filteredStores = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _companyId = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreen();
    });
  }

  Future<void> _initializeScreen() async {
    try {
      print('🔄 Inicializando pantalla de tiendas...');
      
      // Inicializar contexto del AuthService
      await _authService.initializeContext();
      print('✅ AuthService inicializado');
      
      final userInfo = _authService.currentUserInfo;
      print('👤 Usuario actual: ${userInfo?.displayName ?? userInfo?.userId}');
      print('🏢 Company ID: ${userInfo?.companyId}');
      
      if (userInfo != null && userInfo.companyId != null) {
        setState(() => _companyId = userInfo.companyId!);
        await _loadStores();
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

  Future<void> _loadStores() async {
    if (_companyId.isEmpty) return;
    
    final storeProvider = Provider.of<StoreProvider>(context, listen: false);
    
    if (storeProvider.stores.isNotEmpty) {
      var stores = storeProvider.stores.where((s) => s.isActive == true).toList();
      setState(() {
        _stores = stores;
        _filteredStores = stores;
        _isLoading = false;
      });
      return;
    }

    try {
      setState(() => _isLoading = true);
      await storeProvider.loadStores(_companyId);
      
      var stores = storeProvider.stores.where((s) => s.isActive == true).toList();
      
      if (stores.isEmpty) {
        print('🏪 No hay tiendas, creando tienda por defecto...');
        try {
          await _createDefaultStore();
          await storeProvider.loadStores(_companyId);
          stores = storeProvider.stores.where((s) => s.isActive == true).toList();
        } catch (e) {
          print('❌ Error creando tienda por defecto: $e');
        }
      }
      
      if (mounted) {
        setState(() {
          _stores = stores;
          _filteredStores = stores;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error cargando tiendas: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createDefaultStore() async {
    try {
      final defaultStore = StoreDTO(
        name: 'Tienda Principal',
        address: 'Dirección por definir',
        phone: 'Teléfono por definir',
        email: 'tienda@empresa.com',
        companyId: _companyId,
        isActive: true,
      );
      
      await _storeService.insert(_companyId, defaultStore);
      print('✅ Tienda por defecto creada exitosamente');
    } catch (e) {
      print('❌ Error creando tienda por defecto: $e');
      throw e;
    }
  }

  void _filterStores(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredStores = _stores;
      } else {
        _filteredStores = _stores.where((store) {
          return store.name!.toLowerCase().contains(query.toLowerCase()) ||
                 (store.address?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
                 (store.email?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
                 (store.phone?.contains(query) ?? false);
        }).toList();
      }
    });
  }

  Future<void> _navigateToAddEditStore({StoreDTO? store}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditStoreScreen(
          companyId: _companyId,
          store: store,
        ),
      ),
    );

    if (result == true) {
      _loadStores();
    }
  }

  Future<void> _toggleStoreStatus(StoreDTO store) async {
    try {
      await _storeService.toggleStoreStatus(_companyId, store.id!, !store.isActive!);
      _loadStores();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              store.isActive! 
                ? 'Tienda "${store.name}" desactivada'
                : 'Tienda "${store.name}" activada',
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

  Future<void> _confirmDeleteStore(StoreDTO store) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text('¿Estás seguro de que deseas eliminar la tienda "${store.name}"?'),
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
        await _storeService.delete(_companyId, store.id!);
        _loadStores();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tienda "${store.name}" eliminada'),
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
          'Tiendas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStores,
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
                      hintText: 'Buscar tiendas...',
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
                                _filterStores('');
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
                    onChanged: _filterStores,
                  ),
                ),
              ],
            ),
          ),
          
          // Lista de tiendas
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredStores.isEmpty
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
                                  ? 'No hay tiendas registradas'
                                  : 'No se encontraron tiendas',
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadStores,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredStores.length,
                          itemBuilder: (context, index) {
                            final store = _filteredStores[index];
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
                                    Icons.storefront,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        store.name ?? '',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    if (!store.isActive!)
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
                                          'INACTIVA',
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
                                    if (store.address != null) ...[
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
                                              store.address!,
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
                                    if (store.phone != null) ...[
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
                                            store.phone!,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    if (store.email != null) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.email,
                                            size: 16,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              store.email!,
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
                                        _navigateToAddEditStore(store: store);
                                        break;
                                      case 'toggle':
                                        _toggleStoreStatus(store);
                                        break;
                                      case 'delete':
                                        _confirmDeleteStore(store);
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
                                            store.isActive! 
                                              ? Icons.visibility_off 
                                              : Icons.visibility,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            store.isActive! 
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
                                onTap: () => _navigateToAddEditStore(store: store),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddEditStore(),
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