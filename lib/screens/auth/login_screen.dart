import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:punto_de_venta/providers/auth_provider.dart' as auth_prov;

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LoginScreenContent();
  }
}

class _LoginScreenContent extends StatefulWidget {
  const _LoginScreenContent();

  @override
  State<_LoginScreenContent> createState() => _LoginScreenContentState();
}

class _LoginScreenContentState extends State<_LoginScreenContent> {
  final TextEditingController conUser = TextEditingController();
  final TextEditingController conPwd = TextEditingController();
  bool _obscurePassword = true;

  // Colors
  final Color _primaryColor = const Color(0xFF1A237E);
  final Color _accentColor = const Color(0xFF00BFA5);
  final Color _backgroundColor = const Color(0xFFF5F7FA);

  @override
  void dispose() {
    conUser.dispose();
    conPwd.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    // Obtener el provider
    final authProvider = context.read<auth_prov.AuthProvider>();

    // Validar que los campos no estén vacíos
    if (conUser.text.trim().isEmpty || conPwd.text.trim().isEmpty) {
      _showErrorMessage('❌ Por favor completa todos los campos');
      return;
    }

    // Validar formato de email básico
    if (!conUser.text.contains('@') || !conUser.text.contains('.')) {
      _showErrorMessage('📧 Por favor ingresa un correo electrónico válido');
      return;
    }

    try {
      // Usar AuthProvider en lugar de AuthService directamente
      final success = await authProvider.signInWithEmailAndPassword(
        conUser.text.trim(),
        conPwd.text,
      );

      if (!mounted) return;

      if (success) {
        // Login exitoso
        _showSuccessMessage('¡Bienvenido de vuelta!');

        // Navegar a la pantalla principal
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // Mostrar error del provider
        final errorMessage =
            authProvider.errorMessage ??
            'Error al iniciar sesión. Intenta nuevamente.';
        _showErrorMessage(errorMessage);
      }
    } catch (e) {
      if (!mounted) return;

      print('Error capturado en login: $e');
      print('Tipo de error: ${e.runtimeType}');

      // Manejar todos los tipos de error de manera uniforme
      String errorMessage;

      if (e is FirebaseAuthException) {
        errorMessage = _getFirebaseErrorMessage(e.code);
      } else {
        errorMessage =
            '❌ Credenciales incorrectas.\nVerifica tu correo electrónico y contraseña.';
      }

      _showErrorMessage(errorMessage);
    }
  }

  Future<void> _signInWithGoogle() async {
    final authProvider = context.read<auth_prov.AuthProvider>();

    try {
      final success = await authProvider.signInWithGoogle();

      if (success && mounted) {
        _showSuccessMessage('¡Bienvenido! Inicio de sesión exitoso con Google');
        Navigator.pushReplacementNamed(context, '/home');
      } else if (!success && mounted) {
        // El usuario canceló el login o hubo un error
        if (authProvider.errorMessage != null) {
          _showErrorMessage(authProvider.errorMessage!);
        }
      }
    } catch (e) {
      print('Error en Google Sign-In: $e');

      if (e.toString().contains('popup_closed_by_user')) {
        // Usuario canceló - no mostrar error
        return;
      }

      _showErrorMessage(
        'Error al iniciar sesión con Google. Por favor intenta nuevamente.',
      );
    }
  }

  String _getFirebaseErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return '❌ No existe una cuenta con este correo electrónico.\n¿Quieres registrarte?';
      case 'wrong-password':
        return '🔒 Contraseña incorrecta.\nRevisa tu contraseña e intenta nuevamente.';
      case 'invalid-email':
        return '📧 El formato del correo electrónico no es válido.\nVerifica que esté escrito correctamente.';
      case 'invalid-credential':
        return '❌ Credenciales incorrectas.\nVerifica tu correo electrónico y contraseña.';
      case 'user-disabled':
        return '🚫 Esta cuenta ha sido deshabilitada.\nContacta al administrador.';
      case 'too-many-requests':
        return '⏱️ Demasiados intentos fallidos.\nEspera un momento antes de intentar nuevamente.';
      case 'network-request-failed':
        return '🌐 Error de conexión.\nVerifica tu conexión a internet.';
      case 'invalid-input':
        return '⚠️ Por favor completa todos los campos correctamente.';
      case 'unknown-error':
        return '⚠️ Error inesperado.\nPor favor intenta nuevamente.';
      default:
        return '⚠️ Error al iniciar sesión: $errorCode\nPor favor intenta nuevamente.';
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 4),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo or Icon
              Icon(Icons.point_of_sale, size: 64, color: _primaryColor),
              const SizedBox(height: 12),
              Text(
                'Punto de Venta',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Inicia sesión para continuar',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),

              // Login Card
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Card(
                  elevation: 8,
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Email Field
                        TextFormField(
                          controller: conUser,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Correo Electrónico',
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color: _primaryColor,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: _primaryColor,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Password Field
                        TextFormField(
                          controller: conPwd,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: _primaryColor,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: Colors.grey[600],
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: _primaryColor,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Login Button
                        Consumer<auth_prov.AuthProvider>(
                          builder: (context, authProvider, _) {
                            return SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                onPressed: authProvider.isLoading
                                    ? null
                                    : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                                child: authProvider.isLoading
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'INICIAR SESIÓN',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                        ),
                                      ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Divider "O"
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'O',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Google Sign-In Button
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Consumer<auth_prov.AuthProvider>(
                  builder: (context, authProvider, _) {
                    return SizedBox(
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: authProvider.isLoading
                            ? null
                            : _signInWithGoogle,
                        icon: Image.network(
                          'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                          height: 24,
                          width: 24,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.g_mobiledata, size: 24);
                          },
                        ),
                        label: const Text(
                          'Continuar con Google',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[800],
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Register Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '¿No tienes una cuenta? ',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/register');
                    },
                    child: Text(
                      'Regístrate aquí',
                      style: TextStyle(
                        color: _accentColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
