import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category_dto.dart';
import 'base_firebase_service.dart';

class CategoryService extends BaseFirebaseService<CategoryDTO> {
  CategoryService() : super('categories');

  @override
  CategoryDTO fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CategoryDTO.fromJson({
      'id': doc.id,
      ...data,
      'createdAt': (data['createdAt'] as Timestamp?)?.toDate().toIso8601String(),
      'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate().toIso8601String(),
    });
  }

  @override
  Map<String, dynamic> toFirestore(CategoryDTO category) {
    final json = category.toJson();
    json.remove('id');
    json.remove('createdAt');
    json.remove('updatedAt');
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
    return await getWhere(companyId, 'isActive', true);
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