import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/product_dto.dart';
import '../../../models/category_dto.dart';
import '../../../services/product_service.dart';
import '../../../services/category_service.dart';
import '../../../services/storage_service.dart';

class AddEditProductScreen extends StatefulWidget {
  final ProductDTO? product;
  final String companyId;

  const AddEditProductScreen({
    super.key,
    this.product,
    required this.companyId,
  });

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProductService _productService = ProductService();
  final CategoryService _categoryService = CategoryService();

  final Color _primaryColor = const Color(0xFF1A237E);
  final Color _backgroundColor = const Color(0xFFF5F7FA);

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _basePriceController = TextEditingController();
  final TextEditingController _skuController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();

  // Category related
  List<CategoryDTO> _categories = [];
  String? _selectedCategoryId;
  bool _isLoadingCategories = true;

  // Image related
  Uint8List? _imageBytes;
  String? _imageUrl;

  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.product != null;
    _loadCategories();
    if (_isEditing) {
      _loadProductData();
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _categoryService.getActiveCategories(
        widget.companyId,
      );
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
    } catch (e) {
      print('Error al cargar categorías: $e');
      setState(() {
        _isLoadingCategories = false;
      });
    }
  }

  void _loadProductData() {
    final product = widget.product!;
    _nameController.text = product.name ?? '';
    _descriptionController.text = product.description ?? '';
    _basePriceController.text = product.basePrice?.toString() ?? '';
    _skuController.text = product.sku ?? '';
    _barcodeController.text = product.barcode ?? '';
    _selectedCategoryId = product.categoryId;
    _skuController.text = product.sku ?? '';
    _barcodeController.text = product.barcode ?? '';
    _imageUrl = product.imageUrl; // Cargar imagen existente
  }

  // Método para seleccionar imagen
  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      print('Error al seleccionar imagen: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al seleccionar imagen'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Subir imagen si se seleccionó una nueva
      String? finalImageUrl = _imageUrl; // Mantener URL existente

      if (_imageBytes != null) {
        try {
          final storageService = StorageService();
          final tempId = _isEditing
              ? widget.product!.id!
              : DateTime.now().millisecondsSinceEpoch.toString();

          finalImageUrl = await storageService.uploadProductImage(
            productId: tempId,
            imageBytes: _imageBytes!,
            fileName: 'product_image.jpg',
          );

          if (finalImageUrl == null) {
            print('⚠️ No se pudo subir la imagen, continuando sin imagen...');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Advertencia: No se pudo subir la imagen (CORS). Producto guardado sin imagen.',
                  ),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 4),
                ),
              );
            }
          }
        } catch (imageError) {
          print('⚠️ Error al subir imagen: $imageError');
          print('⚠️ Continuando sin imagen...');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Advertencia: Error al subir imagen. Producto guardado sin imagen.',
                ),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 4),
              ),
            );
          }
          // No lanzar error, continuar sin imagen
          finalImageUrl = _imageUrl; // Mantener URL existente o null
        }
      }

      final productData = ProductDTO(
        id: _isEditing ? widget.product!.id : null,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        basePrice: double.parse(_basePriceController.text),
        sku: _skuController.text.trim().isEmpty
            ? null
            : _skuController.text.trim(),
        barcode: _barcodeController.text.trim().isEmpty
            ? null
            : _barcodeController.text.trim(),
        companyId: widget.companyId,
        categoryId:
            _selectedCategoryId, // Ahora incluye la categoría seleccionada
        imageUrl: finalImageUrl, // Agregar URL de imagen
        isActive: true,
        createdAt: _isEditing ? widget.product!.createdAt : null,
        updatedAt: _isEditing ? widget.product!.updatedAt : null,
      );

      print('Datos del producto a guardar: ${productData.toJson()}'); // Debug

      if (_isEditing) {
        await _productService.update(
          widget.companyId,
          widget.product!.id!,
          productData,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Producto "${productData.name}" actualizado'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await _productService.insert(widget.companyId, productData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Producto "${productData.name}" creado'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error completo: $e'); // Debug adicional
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        title: Text(
          _isEditing ? 'Editar Producto' : 'Nuevo Producto',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _saveProduct,
              child: Text(
                _isEditing ? 'ACTUALIZAR' : 'GUARDAR',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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

                      // Nombre del producto
                      _buildTextField(
                        controller: _nameController,
                        label: 'Nombre del Producto *',
                        icon: Icons.inventory_2_outlined,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El nombre es obligatorio';
                          }
                          if (value.trim().length < 2) {
                            return 'El nombre debe tener al menos 2 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Descripción
                      _buildTextField(
                        controller: _descriptionController,
                        label: 'Descripción (Opcional)',
                        icon: Icons.description_outlined,
                        maxLines: 3,
                        validator: (value) {
                          if (value != null && value.length > 500) {
                            return 'La descripción no puede exceder 500 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Selector de categoría
                      _buildCategorySelector(),
                      const SizedBox(height: 16),

                      // Precio base
                      _buildTextField(
                        controller: _basePriceController,
                        label: 'Precio Base *',
                        icon: Icons.attach_money,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}'),
                          ),
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El precio es obligatorio';
                          }
                          final price = double.tryParse(value);
                          if (price == null || price < 0) {
                            return 'Ingresa un precio válido';
                          }
                          if (price == 0) {
                            return 'El precio debe ser mayor a 0';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Información adicional
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Información Adicional',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // SKU
                      _buildTextField(
                        controller: _skuController,
                        label: 'SKU (Opcional)',
                        icon: Icons.qr_code,
                        validator: (value) {
                          if (value != null &&
                              value.isNotEmpty &&
                              value.length < 3) {
                            return 'El SKU debe tener al menos 3 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Código de barras
                      _buildTextField(
                        controller: _barcodeController,
                        label: 'Código de Barras (Opcional)',
                        icon: Icons.barcode_reader,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value != null &&
                              value.isNotEmpty &&
                              value.length < 8) {
                            return 'El código de barras debe tener al menos 8 dígitos';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Card de imagen
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Imagen del Producto',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Preview de imagen
                      if (_imageBytes != null || _imageUrl != null)
                        Center(
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: _imageBytes != null
                                  ? Image.memory(
                                      _imageBytes!,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.network(
                                      _imageUrl!,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ),
                        ),

                      if (_imageBytes != null || _imageUrl != null)
                        const SizedBox(height: 16),

                      // Botón seleccionar imagen
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.image),
                          label: Text(
                            _imageBytes != null || _imageUrl != null
                                ? 'Cambiar Imagen'
                                : 'Seleccionar Imagen',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _primaryColor,
                            side: BorderSide(color: _primaryColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Botón de guardar
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _isEditing ? 'ACTUALIZAR PRODUCTO' : 'CREAR PRODUCTO',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.category, color: _primaryColor, size: 20),
            const SizedBox(width: 8),
            Text(
              'Categoría',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_isLoadingCategories)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[50],
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(_primaryColor),
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Cargando categorías...'),
              ],
            ),
          )
        else if (_categories.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[50],
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No hay categorías disponibles. Crea una categoría primero.',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          )
        else
          DropdownButtonFormField<String>(
            value: _selectedCategoryId,
            decoration: InputDecoration(
              labelText: 'Seleccionar categoría (opcional)',
              prefixIcon: Icon(Icons.category_outlined, color: _primaryColor),
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
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('Sin categoría'),
              ),
              ..._categories.map((category) {
                return DropdownMenuItem<String>(
                  value: category.id,
                  child: Row(
                    children: [
                      if (category.color != null && category.icon != null) ...[
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Color(
                              int.parse('0xFF${category.color!.substring(1)}'),
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            _getIconFromString(category.icon!),
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(category.name ?? 'Sin nombre'),
                    ],
                  ),
                );
              }).toList(),
            ],
            onChanged: (value) {
              setState(() {
                _selectedCategoryId = value;
              });
            },
          ),
      ],
    );
  }

  IconData _getIconFromString(String iconString) {
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _primaryColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _basePriceController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }
}
