import 'package:flutter/material.dart';
import 'package:punto_de_venta/services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      await _authService.reloadUserContext();
    } catch (e) {
      print('Error al cargar datos del usuario: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final userInfo = _authService.currentUserInfo;
    final company = _authService.currentCompany;

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil'), centerTitle: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Avatar
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: userInfo?.photoURL != null
                              ? NetworkImage(userInfo!.photoURL!)
                              : null,
                          child: userInfo?.photoURL == null
                              ? Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.grey[600],
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(8),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Nombre
                  Text(
                    userInfo?.displayName ?? user?.email ?? 'Usuario',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Proveedor de autenticación
                  Chip(
                    avatar: Icon(
                      userInfo?.authProvider == 'google'
                          ? Icons.g_mobiledata
                          : Icons.email,
                      size: 20,
                    ),
                    label: Text(
                      userInfo?.authProvider == 'google' ? 'Google' : 'Email',
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Información del usuario
                  Card(
                    elevation: 2,
                    child: Column(
                      children: [
                        _buildInfoTile(
                          icon: Icons.email,
                          title: 'Correo Electrónico',
                          subtitle: user?.email ?? 'No disponible',
                        ),
                        const Divider(height: 1),
                        _buildInfoTile(
                          icon: Icons.phone,
                          title: 'Teléfono',
                          subtitle: userInfo?.phone ?? 'No registrado',
                        ),
                        const Divider(height: 1),
                        _buildInfoTile(
                          icon: Icons.business,
                          title: 'Empresa',
                          subtitle: company?.name ?? 'No disponible',
                        ),
                        const Divider(height: 1),
                        _buildInfoTile(
                          icon: Icons.store,
                          title: 'Tienda Actual',
                          subtitle: 'Tienda Principal',
                        ),
                        const Divider(height: 1),
                        _buildInfoTile(
                          icon: Icons.badge,
                          title: 'Rol',
                          subtitle: 'Manager',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Botón de cerrar sesión
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _logout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.logout),
                      label: const Text(
                        'Cerrar Sesión',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(
        title,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    );
  }
}
