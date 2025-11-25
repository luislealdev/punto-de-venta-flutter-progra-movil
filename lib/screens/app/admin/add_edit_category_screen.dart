import 'package:flutter/material.dart';
import '../../../models/category_dto.dart';
import '../../../services/category_service.dart';
import '../../../services/auth_service.dart';

class AddEditCategoryScreen extends StatefulWidget {
  final CategoryDTO? category;
  final String? parentCategoryId;

  const AddEditCategoryScreen({
    super.key, 
    this.category,
    this.parentCategoryId,
  });

  @override
  State<AddEditCategoryScreen> createState() => _AddEditCategoryScreenState();
}

class _AddEditCategoryScreenState extends State<AddEditCategoryScreen> {
  final CategoryService _categoryService = CategoryService();
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  
  final Color _primaryColor = const Color(0xFF1A237E);
  final Color _accentColor = const Color(0xFF00BFA5);
  final Color _backgroundColor = const Color(0xFFF5F7FA);

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  List<CategoryDTO> _parentCategories = [];
  String? _selectedParentId;
  String? _selectedColor;
  IconData? _selectedIcon;
  bool _isActive = true;
  bool _isLoading = false;
  bool _isLoadingParents = true;

  final List<String> _availableColors = [
    '#FF6B6B', '#4ECDC4', '#45B7D1', '#FFA07A', 
    '#98D8C8', '#F7DC6F', '#BB8FCE', '#85C1E9',
    '#F8C471', '#82E0AA', '#F1948A', '#AED6F1',
  ];

  final List<IconData> _availableIcons = [
    Icons.category,
    Icons.shopping_cart,
    Icons.local_grocery_store,
    Icons.store,
    Icons.inventory,
    Icons.lunch_dining,
    Icons.coffee,
    Icons.wine_bar,
    Icons.devices,
    Icons.sports_esports,
    Icons.book,
    Icons.home,
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _descriptionController = TextEditingController(text: widget.category?.description ?? '');
    _selectedParentId = widget.category?.parentCategoryId ?? widget.parentCategoryId;
    _selectedColor = widget.category?.color ?? _availableColors.first;
    _selectedIcon = _getIconFromString(widget.category?.icon);
    _isActive = widget.category?.isActive ?? true;
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    // Primero verificar si tenemos el contexto cargado
    if (_authService.currentCompanyId == null) {
      print('DEBUG: Company ID es null, intentando recargar contexto...');
      try {
        await _authService.initializeContext();
        print('DEBUG: Contexto inicializado: ${_authService.currentCompanyId}');
      } catch (e) {
        print('DEBUG: Error al inicializar contexto: $e');
      }
    }
    
    _loadParentCategories();
  }

  IconData _getIconFromString(String? iconString) {
    if (iconString == null) return _availableIcons.first;
    
    switch (iconString) {
      case 'category': return Icons.category;
      case 'shopping_cart': return Icons.shopping_cart;
      case 'local_grocery_store': return Icons.local_grocery_store;
      case 'store': return Icons.store;
      case 'inventory': return Icons.inventory;
      case 'lunch_dining': return Icons.lunch_dining;
      case 'coffee': return Icons.coffee;
      case 'wine_bar': return Icons.wine_bar;
      case 'devices': return Icons.devices;
      case 'sports_esports': return Icons.sports_esports;
      case 'book': return Icons.book;
      case 'home': return Icons.home;
      default: return _availableIcons.first;
    }
  }

  String _getStringFromIcon(IconData icon) {
    switch (icon) {
      case Icons.category: return 'category';
      case Icons.shopping_cart: return 'shopping_cart';
      case Icons.local_grocery_store: return 'local_grocery_store';
      case Icons.store: return 'store';
      case Icons.inventory: return 'inventory';
      case Icons.lunch_dining: return 'lunch_dining';
      case Icons.coffee: return 'coffee';
      case Icons.wine_bar: return 'wine_bar';
      case Icons.devices: return 'devices';
      case Icons.sports_esports: return 'sports_esports';
      case Icons.book: return 'book';
      case Icons.home: return 'home';
      default: return 'category';
    }
  }

  Future<void> _loadParentCategories() async {
    final companyId = _authService.currentCompanyId;
    print('Loading parent categories for company: $companyId');
    
    if (companyId == null) {
      print('No company ID found');
      setState(() => _isLoadingParents = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: No se pudo cargar la información de la empresa'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      final categories = await _categoryService.getActiveCategories(companyId);
      print('Loaded ${categories.length} categories');
      setState(() {
        // Filtrar la categoría actual para evitar bucles
        _parentCategories = categories.where((cat) => 
          cat.id != widget.category?.id
        ).toList();
        _isLoadingParents = false;
      });
    } catch (e) {
      print('Error loading parent categories: $e');
      setState(() => _isLoadingParents = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar categorías: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    print('DEBUG: Intentando guardar categoría...');
    print('DEBUG: Usuario actual: ${_authService.currentUser?.uid}');
    print('DEBUG: Company ID: ${_authService.currentCompanyId}');

    final companyId = _authService.currentCompanyId;
    if (companyId == null) {
      print('DEBUG: Company ID es null, intentando recargar contexto...');
      
      // Intentar recargar el contexto del usuario
      if (_authService.currentUser != null) {
        try {
          await _authService.reloadUserContext();
          final newCompanyId = _authService.currentCompanyId;
          print('DEBUG: Nuevo Company ID después de reload: $newCompanyId');
          
          if (newCompanyId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error: No se pudo obtener la información de la empresa. Intenta cerrar sesión y volver a iniciar.'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
        } catch (e) {
          print('DEBUG: Error al recargar contexto: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al recargar información: $e'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Usuario no autenticado'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      // Obtener el companyId final (puede ser el original o el recargado)
      final finalCompanyId = _authService.currentCompanyId!;
      
      final category = CategoryDTO(
        id: widget.category?.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
          ? null 
          : _descriptionController.text.trim(),
        parentCategoryId: _selectedParentId,
        color: _selectedColor,
        icon: _selectedIcon != null ? _getStringFromIcon(_selectedIcon!) : null,
        companyId: finalCompanyId,
        isActive: _isActive,
      );

      if (widget.category != null) {
        await _categoryService.update(finalCompanyId, widget.category!.id!, category);
      } else {
        await _categoryService.insert(finalCompanyId, category);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.category != null 
              ? 'Categoría actualizada correctamente'
              : 'Categoría creada correctamente'),
            backgroundColor: _accentColor,
          ),
        );
        Navigator.pop(context, true);
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.category != null ? 'Editar Categoría' : 'Nueva Categoría',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveCategory,
            ),
        ],
      ),
      body: _isLoadingParents
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Información básica
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Información Básica',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Nombre de la categoría *',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: Icon(Icons.label, color: _primaryColor),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'El nombre es requerido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _descriptionController,
                            decoration: InputDecoration(
                              labelText: 'Descripción (opcional)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: Icon(Icons.description, color: _primaryColor),
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedParentId,
                            decoration: InputDecoration(
                              labelText: 'Categoría padre (opcional)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: Icon(Icons.folder, color: _primaryColor),
                            ),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('Sin categoría padre'),
                              ),
                              ..._parentCategories.map((category) =>
                                DropdownMenuItem<String>(
                                  value: category.id,
                                  child: Text(category.name ?? ''),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedParentId = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Personalización visual
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Personalización Visual',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Selector de color
                          const Text('Color:', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _availableColors.map((color) {
                              final isSelected = _selectedColor == color;
                              return GestureDetector(
                                onTap: () => setState(() => _selectedColor = color),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Color(int.parse('0xFF${color.substring(1)}')),
                                    shape: BoxShape.circle,
                                    border: isSelected 
                                      ? Border.all(color: _primaryColor, width: 3)
                                      : null,
                                  ),
                                  child: isSelected 
                                    ? const Icon(Icons.check, color: Colors.white)
                                    : null,
                                ),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 24),

                          // Selector de icono
                          const Text('Icono:', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _availableIcons.map((icon) {
                              final isSelected = _selectedIcon == icon;
                              return GestureDetector(
                                onTap: () => setState(() => _selectedIcon = icon),
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: isSelected ? _primaryColor : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    icon,
                                    color: isSelected ? Colors.white : _primaryColor,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 16),

                          // Vista previa
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: _selectedColor != null 
                                      ? Color(int.parse('0xFF${_selectedColor!.substring(1)}'))
                                      : Colors.grey,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _selectedIcon ?? Icons.category,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _nameController.text.isNotEmpty 
                                      ? _nameController.text 
                                      : 'Vista previa de la categoría',
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Estado
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Estado',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            title: const Text('Categoría activa'),
                            subtitle: Text(_isActive 
                              ? 'La categoría estará disponible para asignar a productos'
                              : 'La categoría no estará disponible'),
                            value: _isActive,
                            activeColor: _accentColor,
                            onChanged: (value) => setState(() => _isActive = value),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Botones
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: _primaryColor),
                          ),
                          child: Text(
                            'Cancelar',
                            style: TextStyle(color: _primaryColor),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveCategory,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(widget.category != null ? 'Actualizar' : 'Crear'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }
}