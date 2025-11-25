import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category_dto.dart';
import 'base_firebase_service.dart';

class CategoryService extends BaseFirebaseService<CategoryDTO> {
  CategoryService() : super('categories');

  @override
  CategoryDTO fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    print('DEBUG: CategoryService.fromFirestore - Datos desde Firebase: ${doc.id} -> $data');
    
    // Asegurar valores por defecto para campos críticos
    final processedData = {
      'id': doc.id,
      ...data,
      'isActive': data['isActive'] ?? true, // Valor por defecto true
      'createdAt': (data['createdAt'] as Timestamp?)?.toDate().toIso8601String(),
      'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate().toIso8601String(),
    };
    
    print('DEBUG: CategoryService.fromFirestore - Datos procesados: $processedData');
    return CategoryDTO.fromJson(processedData);
  }

  @override
  Map<String, dynamic> toFirestore(CategoryDTO category) {
    final json = category.toJson();
    json.remove('id');
    json.remove('createdAt');
    json.remove('updatedAt');
    
    // Asegurar que isActive tenga un valor por defecto
    if (json['isActive'] == null) {
      json['isActive'] = true;
    }
    
    // Solo filtrar strings vacíos, permitir null para campos opcionales
    json.removeWhere((key, value) => 
      (value is String && value.trim().isEmpty)
    );
    
    print('DEBUG: CategoryService.toFirestore - Datos a guardar: $json');
    return json;
  }

  // Obtener categorías principales (sin padre)
  Future<List<CategoryDTO>> getRootCategories(String companyId) async {
    final snapshot = await getCompanyCollection(companyId)
        .where('parentCategoryId', isNull: true)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .get();
    
    return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
  }

  // Obtener subcategorías de una categoría padre
  Future<List<CategoryDTO>> getSubcategories(String companyId, String parentCategoryId) async {
    return await getWhere(companyId, 'parentCategoryId', parentCategoryId);
  }

  // Obtener categorías activas
  Future<List<CategoryDTO>> getActiveCategories(String companyId) async {
    print('DEBUG: CategoryService.getActiveCategories para company: $companyId');
    
    // Intentar consulta directa con where
    try {
      final result = await getWhere(companyId, 'isActive', true);
      print('DEBUG: CategoryService.getActiveCategories (método getWhere) encontró: ${result.length} categorías');
      for (final category in result) {
        print('DEBUG: - ${category.name} (isActive: ${category.isActive})');
      }
      return result;
    } catch (e) {
      print('DEBUG: Error con getWhere: $e');
      
      // Fallback: obtener todas y filtrar manualmente
      print('DEBUG: Intentando fallback - obtener todas y filtrar...');
      final snapshot = await getCompanyCollection(companyId).get();
      final allCategories = snapshot.docs.map((doc) => fromFirestore(doc)).toList();
      final activeCategories = allCategories.where((cat) => cat.isActive == true).toList();
      
      print('DEBUG: Fallback encontró: ${activeCategories.length} categorías activas de ${allCategories.length} total');
      for (final category in activeCategories) {
        print('DEBUG: - ${category.name} (isActive: ${category.isActive})');
      }
      
      return activeCategories;
    }
  }

  // MÉTODO TEMPORAL: Obtener TODAS las categorías para debug
  Future<List<CategoryDTO>> getAllCategoriesForDebug(String companyId) async {
    print('DEBUG: CategoryService.getAllCategoriesForDebug para company: $companyId');
    final snapshot = await getCompanyCollection(companyId).get();
    final result = snapshot.docs.map((doc) => fromFirestore(doc)).toList();
    print('DEBUG: CategoryService.getAllCategoriesForDebug encontró: ${result.length} categorías TOTALES');
    for (final category in result) {
      print('DEBUG: - ${category.name} (isActive: ${category.isActive}, id: ${category.id})');
    }
    return result;
  }

  Stream<List<CategoryDTO>> getActiveCategoriesStream(String companyId) {
    return getWhereStream(companyId, 'isActive', true);
  }

  // Obtener árbol completo de categorías
  Future<List<CategoryDTO>> getCategoryTree(String companyId) async {
    final allCategories = await getActiveCategories(companyId);
    
    // Organizar en estructura de árbol (padre -> hijos)
    final Map<String?, List<CategoryDTO>> categoryTree = {};
    
    for (final category in allCategories) {
      final parentId = category.parentCategoryId;
      if (categoryTree[parentId] == null) {
        categoryTree[parentId] = [];
      }
      categoryTree[parentId]!.add(category);
    }
    
    return categoryTree[null] ?? []; // Retornar categorías raíz
  }

  // Verificar si una categoría tiene subcategorías
  Future<bool> hasSubcategories(String companyId, String categoryId) async {
    final subcategories = await getSubcategories(companyId, categoryId);
    return subcategories.isNotEmpty;
  }

  // Activar/desactivar categoría
  Future<void> toggleCategoryStatus(String companyId, String categoryId, bool isActive) async {
    await getCompanyCollection(companyId).doc(categoryId).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}