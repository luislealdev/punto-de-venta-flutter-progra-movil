import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/inventory_dto.dart';
import 'base_firebase_service.dart';

class InventoryService extends BaseFirebaseService<InventoryDTO> {
  InventoryService() : super('inventory');

  @override
  InventoryDTO fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InventoryDTO.fromJson({
      'id': doc.id,
      ...data,
      'lastMovementDate': (data['lastMovementDate'] as Timestamp?)?.toDate().toIso8601String(),
      'createdAt': (data['createdAt'] as Timestamp?)?.toDate().toIso8601String(),
      'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate().toIso8601String(),
    });
  }

  @override
  Map<String, dynamic> toFirestore(InventoryDTO inventory) {
    final json = inventory.toJson();
    json.remove('id');
    json.remove('createdAt');
    json.remove('updatedAt');
    
    // Convertir DateTime a Timestamp para Firebase
    if (json['lastMovementDate'] != null) {
      json['lastMovementDate'] = Timestamp.fromDate(DateTime.parse(json['lastMovementDate']));
    }
    
    return json;
  }

  // Obtener inventario por tienda
  Future<List<InventoryDTO>> getInventoryByStore(String companyId, String storeId) async {
    return await getWhere(companyId, 'storeId', storeId);
  }

  Stream<List<InventoryDTO>> getInventoryByStoreStream(String companyId, String storeId) {
    return getWhereStream(companyId, 'storeId', storeId);
  }

  // Obtener inventario por producto
  Future<List<InventoryDTO>> getInventoryByProduct(String companyId, String productId) async {
    return await getWhere(companyId, 'productId', productId);
  }

  // Obtener inventario específico por producto y tienda
  Future<InventoryDTO?> getInventoryByProductAndStore(
    String companyId, 
    String productId, 
    String storeId,
    {String? productVarietyId}
  ) async {
    Query query = getCompanyCollection(companyId)
        .where('productId', isEqualTo: productId)
        .where('storeId', isEqualTo: storeId);
    
    if (productVarietyId != null) {
      query = query.where('productVarietyId', isEqualTo: productVarietyId);
    }
    
    final snapshot = await query.limit(1).get();
    if (snapshot.docs.isNotEmpty) {
      return fromFirestore(snapshot.docs.first);
    }
    return null;
  }

  // Productos con stock bajo
  Future<List<InventoryDTO>> getLowStockItems(String companyId, String storeId) async {
    final snapshot = await getCompanyCollection(companyId)
        .where('storeId', isEqualTo: storeId)
        .get();
    
    final allInventory = snapshot.docs.map((doc) => fromFirestore(doc)).toList();
    
    return allInventory.where((item) => 
        item.currentStock! <= item.minStock!).toList();
  }

  // Productos sin stock
  Future<List<InventoryDTO>> getOutOfStockItems(String companyId, String storeId) async {
    return await getWhere(companyId, 'currentStock', 0);
  }

  // Productos con exceso de stock
  Future<List<InventoryDTO>> getOverStockItems(String companyId, String storeId) async {
    final snapshot = await getCompanyCollection(companyId)
        .where('storeId', isEqualTo: storeId)
        .get();
    
    final allInventory = snapshot.docs.map((doc) => fromFirestore(doc)).toList();
    
    return allInventory.where((item) => 
        item.currentStock! >= item.maxStock!).toList();
  }

  // Actualizar stock
  Future<void> updateStock(
    String companyId, 
    String inventoryId, 
    int newStock,
    {String? movementType = 'adjustment'}
  ) async {
    await getCompanyCollection(companyId).doc(inventoryId).update({
      'currentStock': newStock,
      'lastMovementDate': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Incrementar stock (entrada de mercancía)
  Future<void> incrementStock(String companyId, String inventoryId, int quantity) async {
    final doc = await getCompanyCollection(companyId).doc(inventoryId).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      final currentStock = (data['currentStock'] as int?) ?? 0;
      await updateStock(companyId, inventoryId, currentStock + quantity, movementType: 'entry');
    }
  }

  // Decrementar stock (venta o salida)
  Future<bool> decrementStock(String companyId, String inventoryId, int quantity) async {
    final doc = await getCompanyCollection(companyId).doc(inventoryId).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      final currentStock = (data['currentStock'] as int?) ?? 0;
      if (currentStock >= quantity) {
        await updateStock(companyId, inventoryId, currentStock - quantity, movementType: 'exit');
        return true;
      }
    }
    return false; // Stock insuficiente
  }

  // Verificar disponibilidad de stock
  Future<bool> checkStockAvailability(
    String companyId, 
    String productId, 
    String storeId, 
    int requiredQuantity,
    {String? productVarietyId}
  ) async {
    final inventory = await getInventoryByProductAndStore(
      companyId, 
      productId, 
      storeId, 
      productVarietyId: productVarietyId
    );
    
    if (inventory == null) return false;
    return inventory.currentStock! >= requiredQuantity;
  }

  // Crear o actualizar inventario
  Future<String> createOrUpdateInventory(String companyId, InventoryDTO inventory) async {
    final existing = await getInventoryByProductAndStore(
      companyId, 
      inventory.productId!, 
      inventory.storeId!,
      productVarietyId: inventory.productVarietyId,
    );
    
    if (existing != null) {
      // Actualizar existente
      await update(companyId, existing.id!, inventory);
      return existing.id!;
    } else {
      // Crear nuevo
      return await insert(companyId, inventory);
    }
  }

  // Obtener resumen de inventario por tienda
  Future<Map<String, int>> getInventorySummary(String companyId, String storeId) async {
    final inventory = await getInventoryByStore(companyId, storeId);
    
    int totalItems = inventory.length;
    int lowStockItems = inventory.where((item) => item.isLowStock).length;
    int outOfStockItems = inventory.where((item) => item.isOutOfStock).length;
    int overStockItems = inventory.where((item) => item.isOverStock).length;
    
    return {
      'totalItems': totalItems,
      'lowStock': lowStockItems,
      'outOfStock': outOfStockItems,
      'overStock': overStockItems,
    };
  }
}