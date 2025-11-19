import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_info_dto.dart';
import '../models/company_dto.dart';
import '../models/role_dto.dart';
import '../models/store_dto.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Estado actual del usuario
  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;
  
  // Información del contexto actual
  String? _currentCompanyId;
  String? _currentStoreId;
  UserInfoDTO? _currentUserInfo;
  CompanyDTO? _currentCompany;

  // Getters para el contexto actual
  String? get currentCompanyId => _currentCompanyId;
  String? get currentStoreId => _currentStoreId;
  UserInfoDTO? get currentUserInfo => _currentUserInfo;
  CompanyDTO? get currentCompany => _currentCompany;

  // Stream del estado de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Iniciar sesión
  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user != null) {
        await _loadUserContext(credential.user!.uid);
      }
      
      return credential;
    } catch (e) {
      print('Error al iniciar sesión: $e');
      rethrow;
    }
  }

  // Registrar nuevo usuario
  Future<UserCredential?> createUserWithEmailAndPassword(
    String email, 
    String password, 
    String companyId, 
    String roleId,
    {String? storeId, String? displayName, String? phone}
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user != null) {
        // Crear el documento de información del usuario
        final userInfo = UserInfoDTO(
          userId: credential.user!.uid,
          displayName: displayName ?? credential.user!.email,
          phone: phone,
          roleId: roleId,
          companyId: companyId,
          storeId: storeId,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _firestore
            .collection('companies')
            .doc(companyId)
            .collection('users')
            .doc(credential.user!.uid)
            .set(userInfo.toJson());

        await _loadUserContext(credential.user!.uid);
      }
      
      return credential;
    } catch (e) {
      print('Error al registrar usuario: $e');
      rethrow;
    }
  }

  // Registrar nuevo manager de empresa (crea empresa, rol y tienda automáticamente)
  Future<UserCredential?> createCompanyManagerWithEmailAndPassword(
    String email, 
    String password,
    String companyName,
    {String? displayName, String? phone, String? companyEmail, String? companyPhone, String? companyAddress}
  ) async {
    UserCredential? credential;
    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user != null) {
        final batch = _firestore.batch();
        final now = DateTime.now();
        
        // 1. Crear la empresa
        final companyRef = _firestore.collection('companies').doc();
        final company = CompanyDTO(
          id: companyRef.id,
          name: companyName,
          email: companyEmail,
          phone: companyPhone,
          address: companyAddress,
          subscriptionPlan: 'basic',
          subscriptionExpiresAt: now.add(const Duration(days: 30)), // 30 días gratis
          isActive: true,
          createdAt: now,
          updatedAt: now,
        );
        batch.set(companyRef, company.toJson());

        // 2. Crear el rol de Manager
        final roleRef = companyRef.collection('roles').doc();
        final managerRole = RoleDTO(
          id: roleRef.id,
          name: 'Manager',
          description: 'Administrador de la empresa con todos los permisos',
          permissions: [
            'users.read', 'users.write', 'users.delete',
            'products.read', 'products.write', 'products.delete',
            'inventory.read', 'inventory.write', 'inventory.delete',
            'sales.read', 'sales.write', 'sales.delete',
            'purchases.read', 'purchases.write', 'purchases.delete',
            'providers.read', 'providers.write', 'providers.delete',
            'customers.read', 'customers.write', 'customers.delete',
            'categories.read', 'categories.write', 'categories.delete',
            'payments.read', 'payments.write', 'payments.delete',
            'stores.read', 'stores.write', 'stores.delete',
            'reports.read',
          ],
          createdAt: now,
          updatedAt: now,
        );
        batch.set(roleRef, managerRole.toJson());

        // 3. Crear la tienda por defecto
        final storeRef = companyRef.collection('stores').doc();
        final defaultStore = StoreDTO(
          id: storeRef.id,
          name: '$companyName - Principal',
          address: companyAddress,
          phone: companyPhone,
          email: companyEmail,
          companyId: companyRef.id,
          isActive: true,
          createdAt: now,
          updatedAt: now,
        );
        batch.set(storeRef, defaultStore.toJson());

        // 4. Crear el usuario manager
        final userRef = companyRef.collection('users').doc(credential.user!.uid);
        final userInfo = UserInfoDTO(
          userId: credential.user!.uid,
          displayName: displayName ?? credential.user!.email,
          phone: phone,
          roleId: roleRef.id,
          companyId: companyRef.id,
          storeId: storeRef.id,
          isActive: true,
          createdAt: now,
          updatedAt: now,
        );
        batch.set(userRef, userInfo.toJson());

        // Ejecutar todas las operaciones
        await batch.commit();
        
        // Cargar el contexto del usuario
        await _loadUserContext(credential.user!.uid);
      }
      
      return credential;
    } catch (e) {
      print('Error al registrar manager de empresa: $e');
      // Si hay error, eliminar el usuario de Firebase Auth
      if (credential?.user != null) {
        try {
          await credential!.user!.delete();
        } catch (deleteError) {
          print('Error al eliminar usuario tras fallo: $deleteError');
        }
      }
      rethrow;
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    await _auth.signOut();
    _clearContext();
  }

  // Cargar el contexto del usuario (empresa, tienda, info)
  Future<void> _loadUserContext(String userId) async {
    try {
      // Buscar la información del usuario en todas las empresas
      // (En un escenario real, podrías almacenar esto en un documento separado)
      final companiesSnapshot = await _firestore.collection('companies').get();
      
      for (final companyDoc in companiesSnapshot.docs) {
        final userDoc = await _firestore
            .collection('companies')
            .doc(companyDoc.id)
            .collection('users')
            .doc(userId)
            .get();
        
        if (userDoc.exists) {
          _currentCompanyId = companyDoc.id;
          _currentUserInfo = UserInfoDTO.fromJson({
            'userId': userDoc.id,
            ...userDoc.data()!,
          });
          _currentStoreId = _currentUserInfo?.storeId;
          
          // Cargar información de la empresa
          _currentCompany = CompanyDTO.fromJson({
            'id': companyDoc.id,
            ...companyDoc.data(),
          });
          
          break;
        }
      }
    } catch (e) {
      print('Error al cargar contexto del usuario: $e');
      rethrow;
    }
  }

  // Limpiar contexto
  void _clearContext() {
    _currentCompanyId = null;
    _currentStoreId = null;
    _currentUserInfo = null;
    _currentCompany = null;
  }

  // Cambiar tienda activa (para usuarios que pueden trabajar en múltiples tiendas)
  Future<void> switchStore(String storeId) async {
    if (_currentCompanyId != null && currentUserId != null) {
      await _firestore
          .collection('companies')
          .doc(_currentCompanyId)
          .collection('users')
          .doc(currentUserId)
          .update({
        'storeId': storeId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      _currentStoreId = storeId;
      if (_currentUserInfo != null) {
        _currentUserInfo = UserInfoDTO(
          userId: _currentUserInfo!.userId,
          displayName: _currentUserInfo!.displayName,
          phone: _currentUserInfo!.phone,
          roleId: _currentUserInfo!.roleId,
          companyId: _currentUserInfo!.companyId,
          storeId: storeId,
          address: _currentUserInfo!.address,
          isActive: _currentUserInfo!.isActive,
          createdAt: _currentUserInfo!.createdAt,
          updatedAt: DateTime.now(),
        );
      }
    }
  }

  // Verificar si el usuario tiene permisos para una acción específica
  Future<bool> hasPermission(String permission) async {
    if (_currentUserInfo?.roleId == null) return false;
    
    // Aquí implementarías la lógica de permisos basada en roles
    // Por ahora, asumimos que todos los usuarios tienen permisos básicos
    return true;
  }

  // Verificar si la suscripción de la empresa está activa
  bool get isSubscriptionActive {
    if (_currentCompany?.subscriptionExpiresAt == null) return true;
    return _currentCompany!.subscriptionExpiresAt!.isAfter(DateTime.now());
  }

  // Método para inicializar el contexto cuando la app se inicia
  Future<void> initializeContext() async {
    final user = currentUser;
    if (user != null) {
      await _loadUserContext(user.uid);
    }
  }

  // Método para superusuarios: cambiar empresa activa
  Future<void> switchCompany(String companyId) async {
    if (currentUserId != null) {
      _currentCompanyId = companyId;
      
      // Cargar nueva información de la empresa
      final companyDoc = await _firestore.collection('companies').doc(companyId).get();
      if (companyDoc.exists) {
        _currentCompany = CompanyDTO.fromJson({
          'id': companyDoc.id,
          ...companyDoc.data()!,
        });
      }
      
      // Cargar información del usuario en esta empresa
      final userDoc = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('users')
          .doc(currentUserId)
          .get();
      
      if (userDoc.exists) {
        _currentUserInfo = UserInfoDTO.fromJson({
          'userId': userDoc.id,
          ...userDoc.data()!,
        });
        _currentStoreId = _currentUserInfo?.storeId;
      }
    }
  }
}