import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:punto_de_venta/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController conUser = TextEditingController();
  final TextEditingController conPwd = TextEditingController();
  bool isValidating = false;
  bool _obscurePassword = true;
  AuthService? auth;

  // Colors
  final Color _primaryColor = const Color(0xFF1A237E);
  final Color _accentColor = const Color(0xFF00BFA5);
  final Color _backgroundColor = const Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();
    auth = AuthService();
  }

  void _login() async {
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

    setState(() {
      isValidating = true;
    });

    try {
      // Intentar iniciar sesión con Firebase Auth
      var credential = await auth!.signInWithEmailAndPassword(
        conUser.text.trim(),
        conPwd.text,
      );

      var user = credential?.user;

      setState(() {
        isValidating = false;
      });

      if (user != null && user.uid.isNotEmpty) {
        // Login exitoso
        print('Login exitoso: ${user.uid}');

        _showSuccessMessage('¡Bienvenido de vuelta!');

        // Navegar a la pantalla principal
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        _showErrorMessage('Error al iniciar sesión. Intenta nuevamente.');
      }
    } catch (e) {
      setState(() {
        isValidating = false;
      });

      print('Error capturado en login: $e');
      print('Tipo de error: ${e.runtimeType}');

      // Manejar todos los tipos de error de manera uniforme
      String errorMessage;

      if (e is FirebaseAuthException) {
        errorMessage = _getFirebaseErrorMessage(e.code);
      } else {
        // Para cualquier otro tipo de error (PlatformException, TypeError, etc.)
        errorMessage =
            '❌ Credenciales incorrectas.\nVerifica tu correo electrónico y contraseña.';
      }

      _showErrorMessage(errorMessage);
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
              Icon(
                Icons.point_of_sale,
                size: 80,
                color: _primaryColor,
              ),
              const SizedBox(height: 16),
              Text(
                'Punto de Venta',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Inicia sesión para continuar',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),

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
                            prefixIcon: Icon(Icons.email_outlined, color: _primaryColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: _primaryColor, width: 2),
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
                            prefixIcon: Icon(Icons.lock_outline, color: _primaryColor),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
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
                              borderSide: BorderSide(color: _primaryColor, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Login Button
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: isValidating ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: isValidating
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
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

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
