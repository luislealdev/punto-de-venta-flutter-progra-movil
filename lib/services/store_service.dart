import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/store_dto.dart';
import 'base_firebase_service.dart';

class StoreService extends BaseFirebaseService<StoreDTO> {
  StoreService() : super('stores');

  @override
  StoreDTO fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StoreDTO.fromJson({
      'id': doc.id,
      ...data,
      'createdAt': (data['createdAt'] as Timestamp?)?.toDate().toIso8601String(),
      'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate().toIso8601String(),
    });
  }

  @override
  Map<String, dynamic> toFirestore(StoreDTO store) {
    final json = store.toJson();
    json.remove('id');
    json.remove('createdAt');
    json.remove('updatedAt');
    return json;
  }

  // Obtener tiendas activas
  Future<List<StoreDTO>> getActiveStores(String companyId) async {
    return await getWhere(companyId, 'isActive', true);
  }

  Stream<List<StoreDTO>> getActiveStoresStream(String companyId) {
    return getWhereStream(companyId, 'isActive', true);
  }

  // Buscar tienda por email
  Future<StoreDTO?> getByEmail(String companyId, String email) async {
    final stores = await getWhere(companyId, 'email', email);
    return stores.isNotEmpty ? stores.first : null;
  }

  // Buscar tienda por teléfono
  Future<StoreDTO?> getByPhone(String companyId, String phone) async {
    final stores = await getWhere(companyId, 'phone', phone);
    return stores.isNotEmpty ? stores.first : null;
  }

  // Buscar tiendas por nombre
  Future<List<StoreDTO>> searchStoresByName(String companyId, String searchTerm) async {
    return await searchByText(companyId, 'name', searchTerm);
  }

  // Activar/desactivar tienda
  Future<void> toggleStoreStatus(String companyId, String storeId, bool isActive) async {
    await getCompanyCollection(companyId).doc(storeId).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Obtener tienda principal (primera activa)
  Future<StoreDTO?> getMainStore(String companyId) async {
    final snapshot = await getCompanyCollection(companyId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt')
        .limit(1)
        .get();
    
    if (snapshot.docs.isNotEmpty) {
      return fromFirestore(snapshot.docs.first);
    }
    return null;
  }

  // Verificar si una tienda tiene usuarios asociados
  Future<bool> hasAssociatedUsers(String companyId, String storeId) async {
    final usersSnapshot = await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('users')
        .where('storeId', isEqualTo: storeId)
        .limit(1)
        .get();
    
    return usersSnapshot.docs.isNotEmpty;
  }

  // Verificar si una tienda tiene ventas asociadas
  Future<bool> hasAssociatedSales(String companyId, String storeId) async {
    final salesSnapshot = await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('sales')
        .where('storeId', isEqualTo: storeId)
        .limit(1)
        .get();
    
    return salesSnapshot.docs.isNotEmpty;
  }

  // Obtener información completa de contacto
  Future<Map<String, String?>> getContactInfo(String companyId, String storeId) async {
    final store = await getById(companyId, storeId);
    if (store != null) {
      return {
        'name': store.name,
        'email': store.email,
        'phone': store.phone,
        'address': store.address,
      };
    }
    return {};
  }

  // Obtener estadísticas básicas de una tienda
  Future<Map<String, int>> getStoreStats(String companyId, String storeId) async {
    final usersSnapshot = await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('users')
        .where('storeId', isEqualTo: storeId)
        .where('isActive', isEqualTo: true)
        .get();

    final salesSnapshot = await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('sales')
        .where('storeId', isEqualTo: storeId)
        .get();

    final inventorySnapshot = await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('inventory')
        .where('storeId', isEqualTo: storeId)
        .get();

    return {
      'totalUsers': usersSnapshot.docs.length,
      'totalSales': salesSnapshot.docs.length,
      'totalProducts': inventorySnapshot.docs.length,
    };
  }

  // Buscar tiendas por dirección/ubicación
  Future<List<StoreDTO>> getStoresByLocation(String companyId, String location) async {
    return await searchByText(companyId, 'address', location);
  }

  // Actualizar información de contacto
  Future<void> updateContactInfo(
    String companyId,
    String storeId,
    {String? email, String? phone, String? address}
  ) async {
    final updateData = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (email != null) updateData['email'] = email;
    if (phone != null) updateData['phone'] = phone;
    if (address != null) updateData['address'] = address;

    await getCompanyCollection(companyId).doc(storeId).update(updateData);
  }
}