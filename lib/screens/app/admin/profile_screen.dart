import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:punto_de_venta/providers/auth_provider.dart' as auth_prov;

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: Consumer<auth_prov.AuthProvider>(
        builder: (context, authProvider, _) {
          final userInfo = authProvider.currentUserInfo;
          final user = authProvider.currentUser;
          final company = authProvider.currentCompany;

          if (userInfo == null || user == null) {
            return const Center(
              child: Text('No hay información de usuario disponible'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 60,
                  backgroundColor: const Color(0xFF00BFA5),
                  backgroundImage:
                      userInfo.photoURL != null && userInfo.photoURL!.isNotEmpty
                      ? NetworkImage(userInfo.photoURL!)
                      : null,
                  child: userInfo.photoURL == null || userInfo.photoURL!.isEmpty
                      ? Text(
                          (userInfo.displayName ?? user.email ?? 'U')[0]
                              .toUpperCase(),
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 16),

                // Nombre
                Text(
                  userInfo.displayName ?? user.email ?? 'Usuario',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Chip de proveedor de autenticación
                Chip(
                  label: Text(
                    userInfo.authProvider == 'google' ? 'Google' : 'Email',
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: userInfo.authProvider == 'google'
                      ? Colors.red
                      : const Color(0xFF1A237E),
                ),
                const SizedBox(height: 32),

                // Información del usuario
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Información Personal',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          Icons.email,
                          'Email',
                          userInfo.email ?? user.email ?? 'No disponible',
                        ),
                        if (userInfo.phone != null &&
                            userInfo.phone!.isNotEmpty)
                          _buildInfoRow(
                            Icons.phone,
                            'Teléfono',
                            userInfo.phone!,
                          ),
                        if (company != null)
                          _buildInfoRow(
                            Icons.business,
                            'Empresa',
                            company.name ?? 'No disponible',
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Botón de cerrar sesión
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () => _showLogoutDialog(context, authProvider),
                    icon: const Icon(Icons.logout),
                    label: const Text('Cerrar Sesión'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1A237E)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(
    BuildContext context,
    auth_prov.AuthProvider authProvider,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Cerrar Sesión'),
          content: const Text('¿Estás seguro que deseas cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await authProvider.signOut();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Cerrar Sesión'),
            ),
          ],
        );
      },
    );
  }
}
