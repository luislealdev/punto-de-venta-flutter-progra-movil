import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subscription_dto.dart';

class SubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Las suscripciones son globales, no por empresa
  CollectionReference get _subscriptionsCollection => 
      _firestore.collection('subscriptions');

  // Convertir desde Firestore
  SubscriptionDTO _fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SubscriptionDTO.fromJson({
      'id': doc.id,
      ...data,
      'startDate': (data['startDate'] as Timestamp?)?.toDate().toIso8601String(),
      'endDate': (data['endDate'] as Timestamp?)?.toDate().toIso8601String(),
      'nextBillingDate': (data['nextBillingDate'] as Timestamp?)?.toDate().toIso8601String(),
      'createdAt': (data['createdAt'] as Timestamp?)?.toDate().toIso8601String(),
      'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate().toIso8601String(),
    });
  }

  // Convertir a Firestore
  Map<String, dynamic> _toFirestore(SubscriptionDTO subscription) {
    final json = subscription.toJson();
    json.remove('id');
    json.remove('createdAt');
    json.remove('updatedAt');
    
    // Convertir DateTime a Timestamp para Firebase
    if (json['startDate'] != null) {
      json['startDate'] = Timestamp.fromDate(DateTime.parse(json['startDate']));
    }
    if (json['endDate'] != null) {
      json['endDate'] = Timestamp.fromDate(DateTime.parse(json['endDate']));
    }
    if (json['nextBillingDate'] != null) {
      json['nextBillingDate'] = Timestamp.fromDate(DateTime.parse(json['nextBillingDate']));
    }
    
    return json;
  }

  // Crear nueva suscripción
  Future<String> createSubscription(SubscriptionDTO subscription) async {
    final doc = await _subscriptionsCollection.add({
      ..._toFirestore(subscription),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  // Obtener suscripción por empresa
  Future<SubscriptionDTO?> getByCompany(String companyId) async {
    final snapshot = await _subscriptionsCollection
        .where('companyId', isEqualTo: companyId)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();
    
    if (snapshot.docs.isNotEmpty) {
      return _fromFirestore(snapshot.docs.first);
    }
    return null;
  }

  // Obtener todas las suscripciones
  Future<List<SubscriptionDTO>> getAllSubscriptions() async {
    final snapshot = await _subscriptionsCollection
        .orderBy('createdAt', descending: true)
        .get();
    
    return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
  }

  // Obtener suscripciones activas
  Future<List<SubscriptionDTO>> getActiveSubscriptions() async {
    final snapshot = await _subscriptionsCollection
        .where('status', isEqualTo: 'active')
        .get();
    
    return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
  }

  // Obtener suscripciones expiradas
  Future<List<SubscriptionDTO>> getExpiredSubscriptions() async {
    final now = Timestamp.now();
    final snapshot = await _subscriptionsCollection
        .where('endDate', isLessThan: now)
        .where('status', isEqualTo: 'active')
        .get();
    
    return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
  }

  // Obtener suscripciones que expiran pronto
  Future<List<SubscriptionDTO>> getExpiringSoonSubscriptions({int daysAhead = 7}) async {
    final now = DateTime.now();
    final futureDate = now.add(Duration(days: daysAhead));
    
    final snapshot = await _subscriptionsCollection
        .where('endDate', isGreaterThan: Timestamp.fromDate(now))
        .where('endDate', isLessThanOrEqualTo: Timestamp.fromDate(futureDate))
        .where('status', isEqualTo: 'active')
        .get();
    
    return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
  }

  // Actualizar suscripción
  Future<void> updateSubscription(String subscriptionId, SubscriptionDTO subscription) async {
    await _subscriptionsCollection.doc(subscriptionId).update({
      ..._toFirestore(subscription),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Renovar suscripción
  Future<void> renewSubscription(String subscriptionId, DateTime newEndDate) async {
    final newBillingDate = newEndDate.subtract(Duration(days: 7)); // 7 días antes
    
    await _subscriptionsCollection.doc(subscriptionId).update({
      'endDate': Timestamp.fromDate(newEndDate),
      'nextBillingDate': Timestamp.fromDate(newBillingDate),
      'status': 'active',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Cancelar suscripción
  Future<void> cancelSubscription(String subscriptionId) async {
    await _subscriptionsCollection.doc(subscriptionId).update({
      'status': 'cancelled',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Suspender suscripción
  Future<void> suspendSubscription(String subscriptionId) async {
    await _subscriptionsCollection.doc(subscriptionId).update({
      'status': 'suspended',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Reactivar suscripción
  Future<void> reactivateSubscription(String subscriptionId) async {
    await _subscriptionsCollection.doc(subscriptionId).update({
      'status': 'active',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Actualizar método de pago
  Future<void> updatePaymentMethod(String subscriptionId, String paymentMethod) async {
    await _subscriptionsCollection.doc(subscriptionId).update({
      'paymentMethod': paymentMethod,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Actualizar ID de Stripe
  Future<void> updateStripeSubscriptionId(String subscriptionId, String stripeSubscriptionId) async {
    await _subscriptionsCollection.doc(subscriptionId).update({
      'stripeSubscriptionId': stripeSubscriptionId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Cambiar plan
  Future<void> changePlan(
    String subscriptionId, 
    String newPlan, 
    double newPrice,
    {int? maxStores, int? maxUsers, int? maxProducts}
  ) async {
    final updateData = <String, dynamic>{
      'plan': newPlan,
      'monthlyPrice': newPrice,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (maxStores != null) updateData['maxStores'] = maxStores;
    if (maxUsers != null) updateData['maxUsers'] = maxUsers;
    if (maxProducts != null) updateData['maxProducts'] = maxProducts;

    await _subscriptionsCollection.doc(subscriptionId).update(updateData);
  }

  // Verificar límites de suscripción
  Future<Map<String, bool>> checkSubscriptionLimits(String companyId) async {
    final subscription = await getByCompany(companyId);
    if (subscription == null) {
      return {
        'storesLimitReached': true,
        'usersLimitReached': true,
        'productsLimitReached': true,
      };
    }

    // Contar recursos actuales
    final storesCount = await _countStores(companyId);
    final usersCount = await _countUsers(companyId);
    final productsCount = await _countProducts(companyId);

    return {
      'storesLimitReached': storesCount >= (subscription.maxStores ?? 1),
      'usersLimitReached': usersCount >= (subscription.maxUsers ?? 3),
      'productsLimitReached': productsCount >= (subscription.maxProducts ?? 100),
    };
  }

  // Contar tiendas de una empresa
  Future<int> _countStores(String companyId) async {
    final snapshot = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('stores')
        .where('isActive', isEqualTo: true)
        .get();
    return snapshot.docs.length;
  }

  // Contar usuarios de una empresa
  Future<int> _countUsers(String companyId) async {
    final snapshot = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('users')
        .where('isActive', isEqualTo: true)
        .get();
    return snapshot.docs.length;
  }

  // Contar productos de una empresa
  Future<int> _countProducts(String companyId) async {
    final snapshot = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('products')
        .where('isActive', isEqualTo: true)
        .get();
    return snapshot.docs.length;
  }

  // Stream de suscripción por empresa
  Stream<SubscriptionDTO?> subscriptionStream(String companyId) {
    return _subscriptionsCollection
        .where('companyId', isEqualTo: companyId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return _fromFirestore(snapshot.docs.first);
      }
      return null;
    });
  }
}