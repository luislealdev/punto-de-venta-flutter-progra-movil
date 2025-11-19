import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/purchase_dto.dart';
import '../models/purchase_item_dto.dart';
import 'base_firebase_service.dart';

class PurchaseService extends BaseFirebaseService<PurchaseDTO> {
  PurchaseService() : super('purchases');

  @override
  PurchaseDTO fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PurchaseDTO.fromJson({
      'id': doc.id,
      ...data,
      'date': (data['date'] as Timestamp?)?.toDate().toIso8601String(),
      'createdAt': (data['createdAt'] as Timestamp?)?.toDate().toIso8601String(),
      'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate().toIso8601String(),
    });
  }

  @override
  Map<String, dynamic> toFirestore(PurchaseDTO purchase) {
    final json = purchase.toJson();
    json.remove('id');
    json.remove('createdAt');
    json.remove('updatedAt');
    
    // Convertir DateTime a Timestamp para Firebase
    if (json['date'] != null) {
      json['date'] = Timestamp.fromDate(DateTime.parse(json['date']));
    }
    
    return json;
  }

  // Crear una compra completa con sus items
  Future<String> createPurchaseWithItems(
    String companyId,
    PurchaseDTO purchase,
    List<PurchaseItemDTO> items
  ) async {
    final batch = FirebaseFirestore.instance.batch();
    
    // Crear la compra
    final purchaseRef = getCompanyCollection(companyId).doc();
    batch.set(purchaseRef, {
      ...toFirestore(purchase),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    // Crear los items de la compra
    final itemsCollection = purchaseRef.collection('items');
    for (final item in items) {
      final itemRef = itemsCollection.doc();
      final itemJson = item.toJson();
      itemJson.remove('id');
      itemJson['purchaseId'] = purchaseRef.id;
      
      batch.set(itemRef, {
        ...itemJson,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    
    await batch.commit();
    return purchaseRef.id;
  }

  // Obtener items de una compra
  Future<List<PurchaseItemDTO>> getPurchaseItems(String companyId, String purchaseId) async {
    final itemsSnapshot = await getCompanyCollection(companyId)
        .doc(purchaseId)
        .collection('items')
        .get();
    
    return itemsSnapshot.docs.map((doc) {
      final data = doc.data();
      return PurchaseItemDTO.fromJson({
        'id': doc.id,
        ...data,
        'createdAt': (data['createdAt'] as Timestamp?)?.toDate().toIso8601String(),
        'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate().toIso8601String(),
      });
    }).toList();
  }

  // Obtener compras por proveedor
  Future<List<PurchaseDTO>> getPurchasesByProvider(String companyId, String providerId) async {
    return await getWhere(companyId, 'providerId', providerId);
  }

  // Obtener compras por tienda
  Future<List<PurchaseDTO>> getPurchasesByStore(String companyId, String storeId) async {
    return await getWhere(companyId, 'storeId', storeId);
  }

  // Obtener compras por estado
  Future<List<PurchaseDTO>> getPurchasesByStatus(String companyId, String status) async {
    return await getWhere(companyId, 'status', status);
  }

  // Obtener compras pendientes
  Future<List<PurchaseDTO>> getPendingPurchases(String companyId) async {
    return await getPurchasesByStatus(companyId, 'pending');
  }

  // Obtener compras por rango de fechas
  Future<List<PurchaseDTO>> getPurchasesByDateRange(
    String companyId,
    DateTime startDate,
    DateTime endDate
  ) async {
    final snapshot = await getCompanyCollection(companyId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();
    
    return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
  }

  // Actualizar estado de compra
  Future<void> updatePurchaseStatus(String companyId, String purchaseId, String newStatus) async {
    await getCompanyCollection(companyId).doc(purchaseId).update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Generar número consecutivo de compra
  Future<String> generatePurchaseNumber(String companyId, String storeId) async {
    final today = DateTime.now();
    final prefix = 'PUR-${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';
    
    final lastPurchase = await getCompanyCollection(companyId)
        .where('storeId', isEqualTo: storeId)
        .where('number', isGreaterThanOrEqualTo: prefix)
        .where('number', isLessThan: '${prefix}Z')
        .orderBy('number', descending: true)
        .limit(1)
        .get();
    
    int consecutive = 1;
    if (lastPurchase.docs.isNotEmpty) {
      final data = lastPurchase.docs.first.data() as Map<String, dynamic>;
      final lastNumber = data['number'] as String;
      consecutive = int.parse(lastNumber.substring(prefix.length)) + 1;
    }
    
    return '$prefix${consecutive.toString().padLeft(4, '0')}';
  }

  // Obtener total de compras del día
  Future<double> getDailyPurchasesTotal(String companyId, String storeId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    
    final snapshot = await getCompanyCollection(companyId)
        .where('storeId', isEqualTo: storeId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .where('status', isEqualTo: 'completed')
        .get();
    
    double total = 0.0;
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      total += (data['total'] as num?)?.toDouble() ?? 0.0;
    }
    
    return total;
  }

  // Obtener compras por ciudad
  Future<List<PurchaseDTO>> getPurchasesByCity(String companyId, String city) async {
    return await getWhere(companyId, 'city', city);
  }

  // Buscar compras por número
  Future<PurchaseDTO?> getPurchaseByNumber(String companyId, String number) async {
    final purchases = await getWhere(companyId, 'number', number);
    return purchases.isNotEmpty ? purchases.first : null;
  }

  // Recibir compra (cambiar estado y actualizar inventario)
  Future<void> receivePurchase(String companyId, String purchaseId) async {
    await updatePurchaseStatus(companyId, purchaseId, 'received');
    
    // Aquí podrías agregar lógica para actualizar automáticamente el inventario
    // basado en los items de la compra
  }

  // Cancelar compra
  Future<void> cancelPurchase(String companyId, String purchaseId) async {
    await updatePurchaseStatus(companyId, purchaseId, 'cancelled');
  }

  // Obtener resumen de compras por proveedor
  Future<Map<String, dynamic>> getPurchasesSummaryByProvider(String companyId, String providerId) async {
    final purchases = await getPurchasesByProvider(companyId, providerId);
    
    double totalAmount = 0.0;
    int totalPurchases = purchases.length;
    int pendingPurchases = purchases.where((p) => p.status == 'pending').length;
    int completedPurchases = purchases.where((p) => p.status == 'completed').length;
    
    for (final purchase in purchases.where((p) => p.status == 'completed')) {
      totalAmount += purchase.total ?? 0.0;
    }
    
    return {
      'totalPurchases': totalPurchases,
      'totalAmount': totalAmount,
      'pendingPurchases': pendingPurchases,
      'completedPurchases': completedPurchases,
    };
  }
}