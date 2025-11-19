import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/provider_dto.dart';
import 'base_firebase_service.dart';

class ProviderService extends BaseFirebaseService<ProviderDTO> {
  ProviderService() : super('providers');

  @override
  ProviderDTO fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProviderDTO.fromJson({
      'id': doc.id,
      ...data,
      'createdAt': (data['createdAt'] as Timestamp?)?.toDate().toIso8601String(),
      'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate().toIso8601String(),
    });
  }

  @override
  Map<String, dynamic> toFirestore(ProviderDTO provider) {
    final json = provider.toJson();
    json.remove('id');
    json.remove('createdAt');
    json.remove('updatedAt');
    return json;
  }

  // Obtener proveedores activos
  Future<List<ProviderDTO>> getActiveProviders(String companyId) async {
    return await getWhere(companyId, 'isActive', true);
  }

  Stream<List<ProviderDTO>> getActiveProvidersStream(String companyId) {
    return getWhereStream(companyId, 'isActive', true);
  }

  // Buscar proveedor por email
  Future<ProviderDTO?> getByEmail(String companyId, String email) async {
    final providers = await getWhere(companyId, 'email', email);
    return providers.isNotEmpty ? providers.first : null;
  }

  // Buscar proveedor por teléfono
  Future<ProviderDTO?> getByPhone(String companyId, String phone) async {
    final providers = await getWhere(companyId, 'phone', phone);
    return providers.isNotEmpty ? providers.first : null;
  }

  // Buscar proveedores por nombre
  Future<List<ProviderDTO>> searchProvidersByName(String companyId, String searchTerm) async {
    return await searchByText(companyId, 'name', searchTerm);
  }

  // Activar/desactivar proveedor
  Future<void> toggleProviderStatus(String companyId, String providerId, bool isActive) async {
    await getCompanyCollection(companyId).doc(providerId).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Obtener proveedores con más compras
  Future<List<Map<String, dynamic>>> getTopProviders(String companyId, {int limit = 10}) async {
    // Esta consulta requeriría una función en la nube o procesamiento local
    // Por ahora, retornamos la lista de proveedores activos
    final providers = await getActiveProviders(companyId);
    
    // En un escenario real, aquí agregarías la lógica para contar compras
    return providers.map((provider) => {
      'provider': provider,
      'totalPurchases': 0, // Se calculará con datos reales
      'totalAmount': 0.0,  // Se calculará con datos reales
    }).toList();
  }

  // Verificar si un proveedor tiene compras asociadas
  Future<bool> hasAssociatedPurchases(String companyId, String providerId) async {
    // Esta verificación se haría consultando la colección de compras
    final purchasesSnapshot = await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('purchases')
        .where('providerId', isEqualTo: providerId)
        .limit(1)
        .get();
    
    return purchasesSnapshot.docs.isNotEmpty;
  }

  // Obtener información de contacto completa
  Future<Map<String, String?>> getContactInfo(String companyId, String providerId) async {
    final provider = await getById(companyId, providerId);
    if (provider != null) {
      return {
        'name': provider.name,
        'email': provider.email,
        'phone': provider.phone,
        'contact': provider.contact,
        'address': provider.address,
      };
    }
    return {};
  }

  // Actualizar información bancaria
  Future<void> updateBankAccount(String companyId, String providerId, String bankAccount) async {
    await getCompanyCollection(companyId).doc(providerId).update({
      'bankAccount': bankAccount,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Obtener proveedores por ciudad/región
  Future<List<ProviderDTO>> getProvidersByLocation(String companyId, String location) async {
    return await searchByText(companyId, 'address', location);
  }
}