import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_dto.dart';
import 'base_firebase_service.dart';

class PaymentService extends BaseFirebaseService<PaymentDTO> {
  PaymentService() : super('payments');

  @override
  PaymentDTO fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PaymentDTO.fromJson({
      'id': doc.id,
      ...data,
      'createdAt': (data['createdAt'] as Timestamp?)?.toDate().toIso8601String(),
      'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate().toIso8601String(),
    });
  }

  @override
  Map<String, dynamic> toFirestore(PaymentDTO payment) {
    final json = payment.toJson();
    json.remove('id');
    json.remove('createdAt');
    json.remove('updatedAt');
    return json;
  }

  // Obtener pagos por cliente
  Future<List<PaymentDTO>> getPaymentsByCustomer(String companyId, String customerId) async {
    return await getWhere(companyId, 'customerId', customerId);
  }

  // Obtener pagos por proveedor
  Future<List<PaymentDTO>> getPaymentsByProvider(String companyId, String providerId) async {
    return await getWhere(companyId, 'providerId', providerId);
  }

  // Obtener pagos por venta
  Future<List<PaymentDTO>> getPaymentsBySale(String companyId, String saleId) async {
    return await getWhere(companyId, 'saleId', saleId);
  }

  // Obtener pagos por compra
  Future<List<PaymentDTO>> getPaymentsByPurchase(String companyId, String purchaseId) async {
    return await getWhere(companyId, 'purchaseId', purchaseId);
  }

  // Obtener pagos por método
  Future<List<PaymentDTO>> getPaymentsByMethod(String companyId, String method) async {
    return await getWhere(companyId, 'method', method);
  }

  // Obtener pagos por estado
  Future<List<PaymentDTO>> getPaymentsByStatus(String companyId, String status) async {
    return await getWhere(companyId, 'status', status);
  }

  // Obtener pagos pendientes
  Future<List<PaymentDTO>> getPendingPayments(String companyId) async {
    return await getPaymentsByStatus(companyId, 'pending');
  }

  // Obtener pagos completados
  Future<List<PaymentDTO>> getCompletedPayments(String companyId) async {
    return await getPaymentsByStatus(companyId, 'completed');
  }

  // Obtener total de pagos por rango de fechas
  Future<double> getPaymentsTotalByDateRange(
    String companyId,
    DateTime startDate,
    DateTime endDate,
    {String? status = 'completed'}
  ) async {
    final snapshot = await getCompanyCollection(companyId)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .where('status', isEqualTo: status)
        .get();
    
    double total = 0.0;
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      total += (data['amount'] as num?)?.toDouble() ?? 0.0;
    }
    
    return total;
  }

  // Procesar pago
  Future<void> processPayment(String companyId, String paymentId) async {
    await getCompanyCollection(companyId).doc(paymentId).update({
      'status': 'completed',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Cancelar pago
  Future<void> cancelPayment(String companyId, String paymentId) async {
    await getCompanyCollection(companyId).doc(paymentId).update({
      'status': 'cancelled',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Obtener resumen de pagos por método
  Future<Map<String, double>> getPaymentsSummaryByMethod(String companyId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    
    final snapshot = await getCompanyCollection(companyId)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .where('status', isEqualTo: 'completed')
        .get();
    
    Map<String, double> summary = {};
    
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final method = data['method'] as String? ?? 'unknown';
      final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
      
      summary[method] = (summary[method] ?? 0.0) + amount;
    }
    
    return summary;
  }
}