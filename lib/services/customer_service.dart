import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer_dto.dart';
import 'base_firebase_service.dart';

class CustomerService extends BaseFirebaseService<CustomerDTO> {
  CustomerService() : super('customers');

  @override
  CustomerDTO fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CustomerDTO.fromJson({
      'id': doc.id,
      ...data,
      'createdAt': (data['createdAt'] as Timestamp?)?.toDate().toIso8601String(),
      'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate().toIso8601String(),
    });
  }

  @override
  Map<String, dynamic> toFirestore(CustomerDTO customer) {
    final json = customer.toJson();
    json.remove('id');
    json.remove('createdAt');
    json.remove('updatedAt');
    return json;
  }

  // Buscar cliente por email
  Future<CustomerDTO?> getByEmail(String companyId, String email) async {
    final customers = await getWhere(companyId, 'email', email);
    return customers.isNotEmpty ? customers.first : null;
  }

  // Buscar cliente por teléfono
  Future<CustomerDTO?> getByPhone(String companyId, String phone) async {
    final customers = await getWhere(companyId, 'phone', phone);
    return customers.isNotEmpty ? customers.first : null;
  }

  // Obtener clientes activos
  Future<List<CustomerDTO>> getActiveCustomers(String companyId) async {
    return await getWhere(companyId, 'isActive', true);
  }

  // Actualizar deuda del cliente
  Future<void> updateDebt(String companyId, String customerId, double newDebt) async {
    await getCompanyCollection(companyId).doc(customerId).update({
      'currentDebt': newDebt,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Obtener clientes con deuda pendiente
  Future<List<CustomerDTO>> getCustomersWithDebt(String companyId) async {
    final snapshot = await getCompanyCollection(companyId)
        .where('currentDebt', isGreaterThan: 0)
        .where('isActive', isEqualTo: true)
        .get();
    
    return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
  }
}