import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_dto.dart';
import 'base_firebase_service.dart';

class ProductService extends BaseFirebaseService<ProductDTO> {
  ProductService() : super('products');

  @override
  ProductDTO fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductDTO.fromJson({
      'id': doc.id,
      ...data,
      'createdAt': (data['createdAt'] as Timestamp?)?.toDate().toIso8601String(),
      'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate().toIso8601String(),
    });
  }

  @override
  Map<String, dynamic> toFirestore(ProductDTO product) {
    final json = product.toJson();
    // Removemos el ID y timestamps porque Firebase los maneja
    json.remove('id');
    json.remove('createdAt');
    json.remove('updatedAt');
    
    // Filtrar valores nulos y strings vacíos para evitar errores de Firebase
    final Map<String, dynamic> cleanJson = {};
    json.forEach((key, value) {
      if (value != null) {
        if (value is String && value.isNotEmpty) {
          cleanJson[key] = value;
        } else if (value is! String) {
          cleanJson[key] = value;
        }
      }
    });
    
    return cleanJson;
  }

  // Métodos específicos para productos
  Future<List<ProductDTO>> getProductsByCategory(String companyId, String categoryId) async {
    return await getWhere(companyId, 'categoryId', categoryId);
  }

  Stream<List<ProductDTO>> getProductsByCategoryStream(String companyId, String categoryId) {
    return getWhereStream(companyId, 'categoryId', categoryId);
  }

  Future<List<ProductDTO>> searchProductsByName(String companyId, String searchTerm) async {
    return await searchByText(companyId, 'name', searchTerm);
  }

  Future<List<ProductDTO>> getActiveProducts(String companyId) async {
    return await getWhere(companyId, 'isActive', true);
  }

  Stream<List<ProductDTO>> getActiveProductsStream(String companyId) {
    return getWhereStream(companyId, 'isActive', true);
  }

  Future<ProductDTO?> getByBarcode(String companyId, String barcode) async {
    final products = await getWhere(companyId, 'barcode', barcode);
    return products.isNotEmpty ? products.first : null;
  }

  Future<ProductDTO?> getBySku(String companyId, String sku) async {
    final products = await getWhere(companyId, 'sku', sku);
    return products.isNotEmpty ? products.first : null;
  }

  // Método para activar/desactivar producto
  Future<void> toggleProductStatus(String companyId, String productId, bool isActive) async {
    await getCompanyCollection(companyId).doc(productId).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}