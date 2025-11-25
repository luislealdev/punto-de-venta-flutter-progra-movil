import 'package:flutter/material.dart';
import '../../../models/product_dto.dart';
import '../../../models/product_variety_dto.dart';
import '../../../services/product_variety_service.dart';

class ProductVarietiesScreen extends StatefulWidget {
  final ProductDTO product;
  final String companyId;

  const ProductVarietiesScreen({
    super.key,
    required this.product,
    required this.companyId,
  });

  @override
  State<ProductVarietiesScreen> createState() => _ProductVarietiesScreenState();
}

class _ProductVarietiesScreenState extends State<ProductVarietiesScreen> {
  final ProductVarietyService _varietyService = ProductVarietyService();
  final Color _primaryColor = const Color(0xFF1A237E);
  final Color _accentColor = const Color(0xFF00BFA5);
  final Color _backgroundColor = const Color(0xFFF5F7FA);
  
  final TextEditingController _searchController = TextEditingController();
  List<ProductVarietyDTO> _varieties = [];
  List<ProductVarietyDTO> _filteredVarieties = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVarieties();
  }

  Future<void> _loadVarieties() async {
    setState(() => _isLoading = true);
    try {
      final varieties = await _varietyService.getVarietiesByProduct(
        widget.companyId, 
        widget.product.id!
      );
      setState(() {
        _varieties = varieties;
        _filteredVarieties = varieties;
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar variedades: $e');
      setState(() => _isLoading = false);
    }
  }

  void _filterVarieties(String searchTerm) {
    setState(() {
      if (searchTerm.isEmpty) {
        _filteredVarieties = _varieties;
      } else {
        _filteredVarieties = _varieties.where((variety) =>
          (variety.name?.toLowerCase().contains(searchTerm.toLowerCase()) ?? false) ||
          (variety.description?.toLowerCase().contains(searchTerm.toLowerCase()) ?? false) ||
          (variety.sku?.toLowerCase().contains(searchTerm.toLowerCase()) ?? false)
        ).toList();
      }
    });
  }

  void _navigateToAddVariety() {
    Navigator.pushNamed(
      context, 
      '/products/varieties/add',
      arguments: {
        'product': widget.product,
        'companyId': widget.companyId,
      }
    ).then((_) => _loadVarieties());
  }

  void _navigateToEditVariety(ProductVarietyDTO variety) {
    Navigator.pushNamed(
      context, 
      '/products/varieties/edit',
      arguments: {
        'variety': variety,
        'product': widget.product,
        'companyId': widget.companyId,
      }
    ).then((_) => _loadVarieties());
  }

  Future<void> _deleteVariety(ProductVarietyDTO variety) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Variedad'),
        content: Text('¿Estás seguro de que deseas eliminar la variedad "${variety.name}"?'),
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
        await _varietyService.toggleVarietyStatus(
          widget.companyId, 
          variety.id!, 
          false
        );
        _loadVarieties();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Variedad "${variety.name}" eliminada')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar variedad: $e'),
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Variedades',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              widget.product.name ?? '',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _accentColor,
        onPressed: _navigateToAddVariety,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Info del producto
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
            child: Row(
              children: [
                Icon(Icons.inventory_2_outlined, color: _primaryColor, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.name ?? '',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor,
                        ),
                      ),
                      if (widget.product.description?.isNotEmpty ?? false)
                        Text(
                          widget.product.description!,
                          style: TextStyle(color: Colors.grey[600]),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 4),
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
          
          // Barra de búsqueda
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: _filterVarieties,
              decoration: InputDecoration(
                hintText: 'Buscar variedades...',
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
          
          // Lista de variedades
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: _primaryColor),
                  )
                : _filteredVarieties.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.category_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _varieties.isEmpty 
                                  ? 'No hay variedades registradas'
                                  : 'No se encontraron variedades',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (_varieties.isEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Agrega tu primera variedad para este producto',
                                style: TextStyle(color: Colors.grey[500]),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadVarieties,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _filteredVarieties.length,
                          itemBuilder: (context, index) {
                            final variety = _filteredVarieties[index];
                            final priceDifference = (variety.price ?? 0) - (widget.product.basePrice ?? 0);
                            
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 12.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16.0),
                                leading: CircleAvatar(
                                  backgroundColor: _accentColor.withOpacity(0.1),
                                  child: Icon(
                                    Icons.category_outlined,
                                    color: _accentColor,
                                  ),
                                ),
                                title: Text(
                                  variety.name ?? 'Sin nombre',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (variety.description?.isNotEmpty ?? false) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        variety.description!,
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
                                            '\$${variety.price?.toStringAsFixed(2) ?? '0.00'}',
                                            style: const TextStyle(
                                              color: Colors.green,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        if (priceDifference != 0) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: priceDifference > 0 
                                                  ? Colors.orange.withOpacity(0.1)
                                                  : Colors.blue.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '${priceDifference > 0 ? '+' : ''}\$${priceDifference.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                color: priceDifference > 0 
                                                    ? Colors.orange
                                                    : Colors.blue,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                        if (variety.sku?.isNotEmpty ?? false) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.purple.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'SKU: ${variety.sku}',
                                              style: const TextStyle(
                                                color: Colors.purple,
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
                                      case 'edit':
                                        _navigateToEditVariety(variety);
                                        break;
                                      case 'delete':
                                        _deleteVariety(variety);
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