import 'package:flutter/material.dart';
import '../../../models/product_dto.dart';
import '../../../models/category_dto.dart';
import '../../../services/product_service.dart';
import '../../../services/category_service.dart';
import '../../../services/auth_service.dart';
import 'add_edit_category_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final ProductService _productService = ProductService();
  final CategoryService _categoryService = CategoryService();
  final AuthService _authService = AuthService();
  final Color _primaryColor = const Color(0xFF1A237E);
  final Color _accentColor = const Color(0xFF00BFA5);
  final Color _backgroundColor = const Color(0xFFF5F7FA);

  final TextEditingController _searchController = TextEditingController();
  List<ProductDTO> _products = [];
  List<ProductDTO> _filteredProducts = [];
  List<CategoryDTO> _categories = [];
  bool _isLoading = true;
  bool _showCategoryFilter = false;
  String? _companyId;
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    // Primero asegurar que el contexto del usuario esté cargado
    if (_authService.currentCompanyId == null) {
      print('DEBUG: Company ID es null, inicializando contexto...');
      await _authService.initializeContext();
    }

    _companyId = _authService.currentCompanyId;
    print('DEBUG: Company ID después de inicializar: $_companyId');

    if (_companyId != null) {
      await Future.wait([_loadProducts(), _loadCategories()]);
    } else {
      print(
        'DEBUG: Company ID sigue siendo null después de inicializar contexto',
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadProducts() async {
    if (_companyId == null) return;

    setState(() => _isLoading = true);
    try {
      final products = await _productService.getActiveProducts(_companyId!);
      setState(() {
        _products = products;
        _filteredProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar productos: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCategories() async {
    if (_companyId == null) return;

    try {
      // Obtener solo las activas
      final categories = await _categoryService.getActiveCategories(
        _companyId!,
      );
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      print('Error al cargar categorías: $e');
    }
  }

  void _filterProducts(String searchTerm) {
    setState(() {
      List<ProductDTO> filtered = _products;

      // Filtro por texto de búsqueda
      if (searchTerm.isNotEmpty) {
        filtered = filtered
            .where(
              (product) =>
                  (product.name?.toLowerCase().contains(
                        searchTerm.toLowerCase(),
                      ) ??
                      false) ||
                  (product.description?.toLowerCase().contains(
                        searchTerm.toLowerCase(),
                      ) ??
                      false) ||
                  (product.sku?.toLowerCase().contains(
                        searchTerm.toLowerCase(),
                      ) ??
                      false) ||
                  (product.barcode?.toLowerCase().contains(
                        searchTerm.toLowerCase(),
                      ) ??
                      false),
            )
            .toList();
      }

      // Filtro por categoría
      if (_selectedCategoryId != null) {
        filtered = filtered
            .where((product) => product.categoryId == _selectedCategoryId)
            .toList();
      }

      _filteredProducts = filtered;
    });
  }

  void _clearCategoryFilter() {
    setState(() {
      _selectedCategoryId = null;
    });
    _filterProducts(_searchController.text);
  }

  IconData _getIconFromString(String? iconString) {
    if (iconString == null) return Icons.category;

    switch (iconString) {
      case 'category':
        return Icons.category;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'local_grocery_store':
        return Icons.local_grocery_store;
      case 'store':
        return Icons.store;
      case 'inventory':
        return Icons.inventory;
      case 'lunch_dining':
        return Icons.lunch_dining;
      case 'coffee':
        return Icons.coffee;
      case 'wine_bar':
        return Icons.wine_bar;
      case 'devices':
        return Icons.devices;
      case 'sports_esports':
        return Icons.sports_esports;
      case 'book':
        return Icons.book;
      case 'home':
        return Icons.home;
      default:
        return Icons.category;
    }
  }

  CategoryDTO? _getCategoryById(String? categoryId) {
    if (categoryId == null) return null;
    return _categories.firstWhere(
      (category) => category.id == categoryId,
      orElse: () => CategoryDTO(
        id: categoryId,
        name: 'Categoría no encontrada',
        companyId: _companyId ?? '',
      ),
    );
  }

  Future<void> _showCategoryManagementDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Gestionar Categorías',
            style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: Column(
              children: [
                // Botón para crear nueva categoría
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _navigateToAddCategory();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Nueva Categoría'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                // Lista de categorías existentes
                Expanded(
                  child: _categories.isEmpty
                      ? const Center(
                          child: Text(
                            'No hay categorías creadas',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _categories.length,
                          itemBuilder: (context, index) {
                            final category = _categories[index];
                            return ListTile(
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: category.color != null
                                      ? Color(
                                          int.parse(
                                            '0xFF${category.color!.substring(1)}',
                                          ),
                                        )
                                      : Colors.grey,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _getIconFromString(category.icon),
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              title: Text(category.name ?? 'Sin nombre'),
                              subtitle: category.description != null
                                  ? Text(category.description!)
                                  : null,
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  Navigator.pop(context);
                                  if (value == 'edit') {
                                    _navigateToEditCategory(category);
                                  } else if (value == 'delete') {
                                    _deleteCategory(category);
                                  }
                                },
                                itemBuilder: (BuildContext context) => [
                                  const PopupMenuItem<String>(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, size: 16),
                                        SizedBox(width: 8),
                                        Text('Editar'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem<String>(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.delete,
                                          size: 16,
                                          color: Colors.red,
                                        ),
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
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cerrar', style: TextStyle(color: _primaryColor)),
            ),
          ],
        );
      },
    );
  }

  void _navigateToAddCategory() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddEditCategoryScreen()),
    );
    if (result == true) {
      // Refrescar el companyId y recargar categorías
      _companyId = _authService.currentCompanyId;
      if (_companyId != null) {
        await _loadCategories();
      }
    }
  }

  void _navigateToEditCategory(CategoryDTO category) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditCategoryScreen(category: category),
      ),
    );
    if (result == true) {
      // Refrescar el companyId y recargar categorías
      _companyId = _authService.currentCompanyId;
      if (_companyId != null) {
        await _loadCategories();
      }
    }
  }

  Future<void> _deleteCategory(CategoryDTO category) async {
    if (_companyId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Categoría'),
        content: Text(
          '¿Estás seguro de que deseas eliminar "${category.name}"?',
        ),
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
        await _categoryService.toggleCategoryStatus(
          _companyId!,
          category.id!,
          false,
        );
        _loadCategories();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Categoría "${category.name}" eliminada')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar categoría: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _navigateToAddProduct() {
    Navigator.pushNamed(
      context,
      '/products/add',
      arguments: {'companyId': _companyId},
    ).then((_) => _loadProducts());
  }

  void _navigateToEditProduct(ProductDTO product) {
    Navigator.pushNamed(
      context,
      '/products/edit',
      arguments: {'product': product, 'companyId': _companyId},
    ).then((_) => _loadProducts());
  }

  void _navigateToProductVarieties(ProductDTO product) {
    Navigator.pushNamed(
      context,
      '/products/varieties',
      arguments: {'product': product, 'companyId': _companyId},
    );
  }

  Future<void> _deleteProduct(ProductDTO product) async {
    if (_companyId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Producto'),
        content: Text(
          '¿Estás seguro de que deseas eliminar "${product.name}"?',
        ),
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
        await _productService.toggleProductStatus(
          _companyId!,
          product.id!,
          false,
        );
        _loadProducts();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Producto "${product.name}" eliminado')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar producto: $e'),
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
        backgroundColor: _primaryColor,
        title: const Text(
          'Productos',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _accentColor,
        onPressed: _navigateToAddProduct,
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
              onChanged: _filterProducts,
              decoration: InputDecoration(
                hintText: 'Buscar productos...',
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

          // Filtros y gestión de categorías
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.filter_list,
                            color: _primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Filtros',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Botón para gestionar categorías
                    OutlinedButton.icon(
                      onPressed: () => _showCategoryManagementDialog(),
                      icon: const Icon(Icons.category, size: 16),
                      label: const Text('Categorías'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _accentColor,
                        side: BorderSide(color: _accentColor),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Chips de categorías
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length + 1, // +1 para "Todas"
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        // Chip "Todas las categorías"
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: const Text('Todas'),
                            selected: _selectedCategoryId == null,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedCategoryId = null);
                                _filterProducts(_searchController.text);
                              }
                            },
                            selectedColor: _primaryColor,
                            labelStyle: TextStyle(
                              color: _selectedCategoryId == null
                                  ? Colors.white
                                  : _primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }

                      final category = _categories[index - 1];
                      final isSelected = _selectedCategoryId == category.id;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          avatar:
                              category.color != null && category.icon != null
                              ? Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: Color(
                                      int.parse(
                                        '0xFF${category.color!.substring(1)}',
                                      ),
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _getIconFromString(category.icon),
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                          label: Text(category.name ?? 'Sin nombre'),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategoryId = selected
                                  ? category.id
                                  : null;
                            });
                            _filterProducts(_searchController.text);
                          },
                          selectedColor: _accentColor,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Lista de productos
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: _primaryColor))
                : _filteredProducts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _products.isEmpty
                              ? 'No hay productos registrados'
                              : 'No se encontraron productos',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (_products.isEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Agrega tu primer producto para comenzar',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadProducts,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = _filteredProducts[index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16.0),
                            leading: CircleAvatar(
                              radius: 30,
                              backgroundColor: _primaryColor.withOpacity(0.1),
                              backgroundImage: product.imageUrl != null
                                  ? NetworkImage(product.imageUrl!)
                                  : null,
                              child: product.imageUrl == null
                                  ? Icon(
                                      Icons.inventory_2_outlined,
                                      color: _primaryColor,
                                    )
                                  : null,
                            ),
                            title: Text(
                              product.name ?? 'Sin nombre',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Mostrar categoría si existe
                                if (product.categoryId != null) ...[
                                  const SizedBox(height: 4),
                                  Builder(
                                    builder: (context) {
                                      final category = _getCategoryById(
                                        product.categoryId,
                                      );
                                      if (category != null) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: category.color != null
                                                ? Color(
                                                    int.parse(
                                                      '0xFF${category.color!.substring(1)}',
                                                    ),
                                                  ).withOpacity(0.1)
                                                : Colors.grey.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (category.icon != null)
                                                Container(
                                                  width: 16,
                                                  height: 16,
                                                  decoration: BoxDecoration(
                                                    color:
                                                        category.color != null
                                                        ? Color(
                                                            int.parse(
                                                              '0xFF${category.color!.substring(1)}',
                                                            ),
                                                          )
                                                        : Colors.grey,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                  child: Icon(
                                                    _getIconFromString(
                                                      category.icon,
                                                    ),
                                                    size: 10,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              if (category.icon != null)
                                                const SizedBox(width: 6),
                                              Text(
                                                category.name ?? 'Sin nombre',
                                                style: TextStyle(
                                                  color: category.color != null
                                                      ? Color(
                                                          int.parse(
                                                            '0xFF${category.color!.substring(1)}',
                                                          ),
                                                        )
                                                      : Colors.grey[700],
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                      return Container();
                                    },
                                  ),
                                ],
                                if (product.description?.isNotEmpty ??
                                    false) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    product.description!,
                                    style: TextStyle(color: Colors.grey[600]),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
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
                                        color: Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '\$${product.basePrice?.toStringAsFixed(2) ?? '0.00'}',
                                        style: const TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (product.sku?.isNotEmpty ?? false) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          'SKU: ${product.sku}',
                                          style: const TextStyle(
                                            color: Colors.blue,
                                            fontSize: 12,
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
                                  case 'varieties':
                                    _navigateToProductVarieties(product);
                                    break;
                                  case 'edit':
                                    _navigateToEditProduct(product);
                                    break;
                                  case 'delete':
                                    _deleteProduct(product);
                                    break;
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'varieties',
                                  child: Row(
                                    children: [
                                      Icon(Icons.category_outlined),
                                      SizedBox(width: 8),
                                      Text('Variedades'),
                                    ],
                                  ),
                                ),
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
                                      Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                      ),
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
                          ),
                        );
                      },
                    ),
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
