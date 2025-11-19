import 'package:cloud_firestore/cloud_firestore.dart';

abstract class BaseFirebaseService<T> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final String collectionName;
  
  BaseFirebaseService(this.collectionName);

  // Obtener la colección para una empresa específica
  CollectionReference getCompanyCollection(String companyId) {
    return firestore
        .collection('companies')
        .doc(companyId)
        .collection(collectionName);
  }

  // Métodos abstractos que cada servicio debe implementar
  T fromFirestore(DocumentSnapshot doc);
  Map<String, dynamic> toFirestore(T item);

  // CRUD Básico
  Future<String> insert(String companyId, T item) async {
    final doc = await getCompanyCollection(companyId).add({
      ...toFirestore(item),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> update(String companyId, String docId, T item) async {
    await getCompanyCollection(companyId).doc(docId).update({
      ...toFirestore(item),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> delete(String companyId, String docId) async {
    await getCompanyCollection(companyId).doc(docId).delete();
  }

  Future<T?> getById(String companyId, String docId) async {
    final doc = await getCompanyCollection(companyId).doc(docId).get();
    if (doc.exists) {
      return fromFirestore(doc);
    }
    return null;
  }

  // Streams para escuchar cambios
  Stream<QuerySnapshot> getAllStream(String companyId) {
    return getCompanyCollection(companyId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<List<T>> getAllMappedStream(String companyId) {
    return getAllStream(companyId).map((snapshot) => 
        snapshot.docs.map((doc) => fromFirestore(doc)).toList());
  }

  // Buscar con filtros
  Future<List<T>> getWhere(String companyId, String field, dynamic value) async {
    final snapshot = await getCompanyCollection(companyId)
        .where(field, isEqualTo: value)
        .get();
    
    return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
  }

  Stream<List<T>> getWhereStream(String companyId, String field, dynamic value) {
    return getCompanyCollection(companyId)
        .where(field, isEqualTo: value)
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => fromFirestore(doc)).toList());
  }

  // Paginación
  Future<List<T>> getPaginated(
    String companyId, {
    int limit = 20,
    DocumentSnapshot? startAfter,
    String orderBy = 'createdAt',
    bool descending = true,
  }) async {
    Query query = getCompanyCollection(companyId)
        .orderBy(orderBy, descending: descending)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
  }

  // Búsqueda por texto (requiere índices en Firestore)
  Future<List<T>> searchByText(String companyId, String field, String searchTerm) async {
    final snapshot = await getCompanyCollection(companyId)
        .where(field, isGreaterThanOrEqualTo: searchTerm)
        .where(field, isLessThanOrEqualTo: searchTerm + '\uf8ff')
        .get();
    
    return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
  }
}