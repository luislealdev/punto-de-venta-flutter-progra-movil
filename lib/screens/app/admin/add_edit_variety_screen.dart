import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/product_dto.dart';
import '../../../models/product_variety_dto.dart';
import '../../../services/product_variety_service.dart';

class AddEditVarietyScreen extends StatefulWidget {
  final ProductVarietyDTO? variety;
  final ProductDTO product;
  final String companyId;

  const AddEditVarietyScreen({
    super.key,
    this.variety,
    required this.product,
    required this.companyId,
  });

  @override
  State<AddEditVarietyScreen> createState() => _AddEditVarietyScreenState();
}

class _AddEditVarietyScreenState extends State<AddEditVarietyScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProductVarietyService _varietyService = ProductVarietyService();
  
  final Color _primaryColor = const Color(0xFF1A237E);
  final Color _backgroundColor = const Color(0xFFF5F7FA);

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _skuController = TextEditingController();

  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.variety != null;
    if (_isEditing) {
      _loadVarietyData();
    } else {
      // Si es nueva variedad, inicializar con el precio base del producto
      _priceController.text = widget.product.basePrice?.toString() ?? '';
    }
  }

  void _loadVarietyData() {
    final variety = widget.variety!;
    _nameController.text = variety.name ?? '';
    _descriptionController.text = variety.description ?? '';
    _priceController.text = variety.price?.toString() ?? '';
    _skuController.text = variety.sku ?? '';
  }

  Future<void> _saveVariety() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final varietyData = ProductVarietyDTO(
        id: _isEditing ? widget.variety!.id : null,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        price: double.parse(_priceController.text),
        productId: widget.product.id!,
        sku: _skuController.text.trim().isEmpty 
            ? null 
            : _skuController.text.trim(),
        isActive: true,
      );

      if (_isEditing) {
        await _varietyService.update(widget.companyId, widget.variety!.id!, varietyData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Variedad "${varietyData.name}" actualizada'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await _varietyService.insert(widget.companyId, varietyData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Variedad "${varietyData.name}" creada'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEditing ? 'Editar Variedad' : 'Nueva Variedad',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              widget.product.name ?? '',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _saveVariety,
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
              // Info del producto base
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.inventory_2_outlined, color: _primaryColor, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Producto Base',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.product.name ?? '',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _primaryColor,
                              ),
                            ),
                            Text(
                              'Precio base: \$${widget.product.basePrice?.toStringAsFixed(2) ?? '0.00'}',
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
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
              
              // Información de la variedad
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Información de la Variedad',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Nombre de la variedad
                      _buildTextField(
                        controller: _nameController,
                        label: 'Nombre de la Variedad *',
                        icon: Icons.category_outlined,
                        hint: 'Ej: Fianna, Verde, Grande, etc.',
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
                        hint: 'Características específicas de esta variedad',
                        maxLines: 3,
                        validator: (value) {
                          if (value != null && value.length > 300) {
                            return 'La descripción no puede exceder 300 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Precio de la variedad
                      _buildTextField(
                        controller: _priceController,
                        label: 'Precio de la Variedad *',
                        icon: Icons.attach_money,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))
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
                      
                      // Mostrar diferencia con precio base
                      if (_priceController.text.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildPriceDifferenceIndicator(),
                      ],
                      
                      const SizedBox(height: 16),
                      
                      // SKU de la variedad
                      _buildTextField(
                        controller: _skuController,
                        label: 'SKU de la Variedad (Opcional)',
                        icon: Icons.qr_code,
                        hint: 'Código único para esta variedad',
                        validator: (value) {
                          if (value != null && value.isNotEmpty && value.length < 3) {
                            return 'El SKU debe tener al menos 3 caracteres';
                          }
                          return null;
                        },
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
                  onPressed: _isLoading ? null : _saveVariety,
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
                          _isEditing ? 'ACTUALIZAR VARIEDAD' : 'CREAR VARIEDAD',
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
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
      onChanged: (value) {
        // Actualizar indicador de precio cuando cambie el precio
        if (controller == _priceController) {
          setState(() {});
        }
      },
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: _primaryColor),
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildPriceDifferenceIndicator() {
    final varietyPrice = double.tryParse(_priceController.text) ?? 0;
    final basePrice = widget.product.basePrice ?? 0;
    final difference = varietyPrice - basePrice;
    
    if (difference == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.balance, color: Colors.grey[600], size: 16),
            const SizedBox(width: 8),
            Text(
              'Mismo precio que el producto base',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
    
    final isMore = difference > 0;
    final color = isMore ? Colors.orange : Colors.blue;
    final icon = isMore ? Icons.trending_up : Icons.trending_down;
    final text = isMore 
        ? '+\$${difference.toStringAsFixed(2)} más caro'
        : '\$${difference.abs().toStringAsFixed(2)} más barato';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _skuController.dispose();
    super.dispose();
  }
}