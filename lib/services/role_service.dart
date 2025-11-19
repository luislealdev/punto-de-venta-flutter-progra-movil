import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/role_dto.dart';

class RoleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Los roles son globales, no por empresa
  CollectionReference get _rolesCollection => 
      _firestore.collection('roles');

  // Convertir desde Firestore
  RoleDTO _fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RoleDTO.fromJson({
      'id': doc.id,
      ...data,
      'createdAt': (data['createdAt'] as Timestamp?)?.toDate().toIso8601String(),
      'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate().toIso8601String(),
    });
  }

  // Convertir a Firestore
  Map<String, dynamic> _toFirestore(RoleDTO role) {
    final json = role.toJson();
    json.remove('id');
    json.remove('createdAt');
    json.remove('updatedAt');
    return json;
  }

  // Crear nuevo rol
  Future<String> createRole(RoleDTO role) async {
    final doc = await _rolesCollection.add({
      ..._toFirestore(role),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  // Obtener rol por ID
  Future<RoleDTO?> getById(String roleId) async {
    final doc = await _rolesCollection.doc(roleId).get();
    if (doc.exists) {
      return _fromFirestore(doc);
    }
    return null;
  }

  // Obtener todos los roles
  Future<List<RoleDTO>> getAllRoles() async {
    final snapshot = await _rolesCollection
        .orderBy('name')
        .get();
    
    return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
  }

  // Obtener roles por nombre
  Future<RoleDTO?> getByName(String roleName) async {
    final snapshot = await _rolesCollection
        .where('name', isEqualTo: roleName)
        .limit(1)
        .get();
    
    if (snapshot.docs.isNotEmpty) {
      return _fromFirestore(snapshot.docs.first);
    }
    return null;
  }

  // Actualizar rol
  Future<void> updateRole(String roleId, RoleDTO role) async {
    await _rolesCollection.doc(roleId).update({
      ..._toFirestore(role),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Eliminar rol
  Future<void> deleteRole(String roleId) async {
    await _rolesCollection.doc(roleId).delete();
  }

  // Agregar permiso a un rol
  Future<void> addPermission(String roleId, String permission) async {
    await _rolesCollection.doc(roleId).update({
      'permissions': FieldValue.arrayUnion([permission]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Remover permiso de un rol
  Future<void> removePermission(String roleId, String permission) async {
    await _rolesCollection.doc(roleId).update({
      'permissions': FieldValue.arrayRemove([permission]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Verificar si un rol tiene un permiso específico
  Future<bool> hasPermission(String roleId, String permission) async {
    final role = await getById(roleId);
    if (role?.permissions != null) {
      return role!.permissions!.contains(permission);
    }
    return false;
  }

  // Obtener roles con un permiso específico
  Future<List<RoleDTO>> getRolesWithPermission(String permission) async {
    final snapshot = await _rolesCollection
        .where('permissions', arrayContains: permission)
        .get();
    
    return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
  }

  // Stream de roles
  Stream<List<RoleDTO>> rolesStream() {
    return _rolesCollection
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => _fromFirestore(doc)).toList());
  }

  // Inicializar roles por defecto
  Future<void> initializeDefaultRoles() async {
    final defaultRoles = [
      RoleDTO(
        name: 'Super Admin',
        description: 'Acceso total al sistema, gestión de suscripciones',
        permissions: [
          'manage_subscriptions',
          'manage_companies',
          'manage_all_data',
          'view_all_reports',
          'manage_users',
          'manage_roles',
        ],
      ),
      RoleDTO(
        name: 'Company Admin',
        description: 'Administrador de empresa',
        permissions: [
          'manage_company_data',
          'manage_stores',
          'manage_users',
          'view_reports',
          'manage_products',
          'manage_sales',
          'manage_purchases',
          'manage_inventory',
        ],
      ),
      RoleDTO(
        name: 'Store Manager',
        description: 'Encargado de tienda',
        permissions: [
          'manage_store_data',
          'view_store_reports',
          'manage_store_products',
          'manage_store_sales',
          'manage_store_inventory',
          'view_store_users',
        ],
      ),
      RoleDTO(
        name: 'Cashier',
        description: 'Cajero/Vendedor',
        permissions: [
          'create_sales',
          'view_products',
          'view_customers',
          'process_payments',
        ],
      ),
      RoleDTO(
        name: 'Employee',
        description: 'Empleado básico',
        permissions: [
          'view_products',
          'view_inventory',
        ],
      ),
    ];

    for (final role in defaultRoles) {
      final existing = await getByName(role.name!);
      if (existing == null) {
        await createRole(role);
      }
    }
  }

  // Verificar si un rol está siendo usado
  Future<bool> isRoleInUse(String roleId) async {
    // Buscar en todas las empresas si hay usuarios con este rol
    final companiesSnapshot = await _firestore.collection('companies').get();
    
    for (final companyDoc in companiesSnapshot.docs) {
      final usersSnapshot = await _firestore
          .collection('companies')
          .doc(companyDoc.id)
          .collection('users')
          .where('roleId', isEqualTo: roleId)
          .limit(1)
          .get();
      
      if (usersSnapshot.docs.isNotEmpty) {
        return true;
      }
    }
    
    return false;
  }

  // Obtener estadísticas de uso de roles
  Future<Map<String, int>> getRoleUsageStats() async {
    final roles = await getAllRoles();
    Map<String, int> stats = {};
    
    for (final role in roles) {
      int count = 0;
      final companiesSnapshot = await _firestore.collection('companies').get();
      
      for (final companyDoc in companiesSnapshot.docs) {
        final usersSnapshot = await _firestore
            .collection('companies')
            .doc(companyDoc.id)
            .collection('users')
            .where('roleId', isEqualTo: role.id)
            .get();
        
        count += usersSnapshot.docs.length;
      }
      
      stats[role.name!] = count;
    }
    
    return stats;
  }
}