import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sale_dto.dart';
import '../models/sale_item_dto.dart';
import 'base_firebase_service.dart';

class SaleService extends BaseFirebaseService<SaleDTO> {
  SaleService() : super('sales');

  @override
  SaleDTO fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SaleDTO.fromJson({
      'id': doc.id,
      ...data,
      'saleDate': (data['saleDate'] as Timestamp?)?.toDate().toIso8601String(),
      'createdAt': (data['createdAt'] as Timestamp?)?.toDate().toIso8601String(),
      'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate().toIso8601String(),
    });
  }

  @override
  Map<String, dynamic> toFirestore(SaleDTO sale) {
    final json = sale.toJson();
    json.remove('id');
    json.remove('createdAt');
    json.remove('updatedAt');
    
    // Convertir DateTime a Timestamp para Firebase
    if (json['saleDate'] != null) {
      json['saleDate'] = Timestamp.fromDate(DateTime.parse(json['saleDate']));
    }
    
    return json;
  }

  // Crear una venta completa con sus items
  Future<String> createSaleWithItems(
    String companyId, 
    SaleDTO sale, 
    List<SaleItemDTO> items
  ) async {
    final batch = firestore.batch();
    
    // Crear la venta
    final saleRef = getCompanyCollection(companyId).doc();
    batch.set(saleRef, {
      ...toFirestore(sale),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    // Crear los items de la venta
    final itemsCollection = saleRef.collection('items');
    for (final item in items) {
      final itemRef = itemsCollection.doc();
      final itemJson = item.toJson();
      itemJson.remove('id');
      itemJson['saleId'] = saleRef.id;
      
      batch.set(itemRef, {
        ...itemJson,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    
    await batch.commit();
    return saleRef.id;
  }

  // Obtener items de una venta
  Future<List<SaleItemDTO>> getSaleItems(String companyId, String saleId) async {
    final itemsSnapshot = await getCompanyCollection(companyId)
        .doc(saleId)
        .collection('items')
        .get();
    
    return itemsSnapshot.docs.map((doc) {
      final data = doc.data();
      return SaleItemDTO.fromJson({
        'id': doc.id,
        ...data,
        'createdAt': (data['createdAt'] as Timestamp?)?.toDate().toIso8601String(),
        'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate().toIso8601String(),
      });
    }).toList();
  }

  // Obtener ventas por cliente
  Future<List<SaleDTO>> getSalesByCustomer(String companyId, String customerId) async {
    return await getWhere(companyId, 'customerId', customerId);
  }

  // Obtener ventas por tienda
  Future<List<SaleDTO>> getSalesByStore(String companyId, String storeId) async {
    return await getWhere(companyId, 'storeId', storeId);
  }

  // Obtener ventas por rango de fechas
  Future<List<SaleDTO>> getSalesByDateRange(
    String companyId, 
    DateTime startDate, 
    DateTime endDate
  ) async {
    final snapshot = await getCompanyCollection(companyId)
        .where('saleDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('saleDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();
    
    return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
  }

  // Obtener total de ventas del día
  Future<double> getDailySalesTotal(String companyId, String storeId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    
    final snapshot = await getCompanyCollection(companyId)
        .where('storeId', isEqualTo: storeId)
        .where('saleDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('saleDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .where('status', isEqualTo: 'completed')
        .get();
    
    double total = 0.0;
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      total += (data['total'] as num?)?.toDouble() ?? 0.0;
    }
    
    return total;
  }

  // Generar número consecutivo de venta
  Future<String> generateSaleNumber(String companyId, String storeId) async {
    final today = DateTime.now();
    final prefix = '${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';
    
    final lastSale = await getCompanyCollection(companyId)
        .where('storeId', isEqualTo: storeId)
        .where('number', isGreaterThanOrEqualTo: prefix)
        .where('number', isLessThan: '${prefix}Z')
        .orderBy('number', descending: true)
        .limit(1)
        .get();
    
    int consecutive = 1;
    if (lastSale.docs.isNotEmpty) {
      // data() can return null or may not contain 'number', so access safely
      final docData = lastSale.docs.first.data() as Map<String, dynamic>?;
      final lastNumber = docData?['number'] as String?;
      if (lastNumber != null && lastNumber.length > prefix.length) {
        final parsed = int.tryParse(lastNumber.substring(prefix.length));
        if (parsed != null) {
          consecutive = parsed + 1;
        }
      }
    }
    
    return '$prefix${consecutive.toString().padLeft(4, '0')}';
  }
}