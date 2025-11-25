import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_variety_dto.dart';
import 'base_firebase_service.dart';

class ProductVarietyService extends BaseFirebaseService<ProductVarietyDTO> {
  ProductVarietyService() : super('product_varieties');

  @override
  ProductVarietyDTO fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductVarietyDTO.fromJson({
      'id': doc.id,
      ...data,
      'createdAt': (data['createdAt'] as Timestamp?)?.toDate().toIso8601String(),
      'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate().toIso8601String(),
    });
  }

  @override
  Map<String, dynamic> toFirestore(ProductVarietyDTO variety) {
    final json = variety.toJson();
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

  // Obtener variedades por producto
  Future<List<ProductVarietyDTO>> getVarietiesByProduct(String companyId, String productId) async {
    return await getWhere(companyId, 'productId', productId);
  }

  Stream<List<ProductVarietyDTO>> getVarietiesByProductStream(String companyId, String productId) {
    return getWhereStream(companyId, 'productId', productId);
  }

  // Obtener variedades activas por producto
  Future<List<ProductVarietyDTO>> getActiveVarietiesByProduct(String companyId, String productId) async {
    final snapshot = await getCompanyCollection(companyId)
        .where('productId', isEqualTo: productId)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .get();
    
    return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
  }

  // Obtener variedad por SKU
  Future<ProductVarietyDTO?> getBySku(String companyId, String sku) async {
    final varieties = await getWhere(companyId, 'sku', sku);
    return varieties.isNotEmpty ? varieties.first : null;
  }

  // Obtener todas las variedades activas
  Future<List<ProductVarietyDTO>> getActiveVarieties(String companyId) async {
    return await getWhere(companyId, 'isActive', true);
  }

  Stream<List<ProductVarietyDTO>> getActiveVarietiesStream(String companyId) {
    return getWhereStream(companyId, 'isActive', true);
  }

  // Activar/desactivar variedad
  Future<void> toggleVarietyStatus(String companyId, String varietyId, bool isActive) async {
    await getCompanyCollection(companyId).doc(varietyId).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Actualizar precio de variedad
  Future<void> updatePrice(String companyId, String varietyId, double newPrice) async {
    await getCompanyCollection(companyId).doc(varietyId).update({
      'price': newPrice,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Verificar si un producto tiene variedades
  Future<bool> productHasVarieties(String companyId, String productId) async {
    final varieties = await getVarietiesByProduct(companyId, productId);
    return varieties.isNotEmpty;
  }

  // Obtener variedad más barata de un producto
  Future<ProductVarietyDTO?> getCheapestVariety(String companyId, String productId) async {
    final snapshot = await getCompanyCollection(companyId)
        .where('productId', isEqualTo: productId)
        .where('isActive', isEqualTo: true)
        .orderBy('price')
        .limit(1)
        .get();
    
    if (snapshot.docs.isNotEmpty) {
      return fromFirestore(snapshot.docs.first);
    }
    return null;
  }

  // Obtener variedad más cara de un producto
  Future<ProductVarietyDTO?> getMostExpensiveVariety(String companyId, String productId) async {
    final snapshot = await getCompanyCollection(companyId)
        .where('productId', isEqualTo: productId)
        .where('isActive', isEqualTo: true)
        .orderBy('price', descending: true)
        .limit(1)
        .get();
    
    if (snapshot.docs.isNotEmpty) {
      return fromFirestore(snapshot.docs.first);
    }
    return null;
  }

  // Buscar variedades por nombre
  Future<List<ProductVarietyDTO>> searchVarietiesByName(String companyId, String searchTerm) async {
    return await searchByText(companyId, 'name', searchTerm);
  }

  // Clonar variedad (crear una copia con diferente nombre/precio)
  Future<String> cloneVariety(String companyId, String varietyId, String newName, double? newPrice) async {
    final original = await getById(companyId, varietyId);
    if (original != null) {
      final clone = ProductVarietyDTO(
        name: newName,
        description: original.description,
        price: newPrice ?? original.price,
        productId: original.productId,
        sku: null, // Se generará uno nuevo si es necesario
        isActive: true,
      );
      
      return await insert(companyId, clone);
    }
    throw Exception('Variedad original no encontrada');
  }
}