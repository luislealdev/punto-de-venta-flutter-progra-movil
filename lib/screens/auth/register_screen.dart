import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import 'package:punto_de_venta/services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  AuthService? auth;

  // Colors
  final Color _primaryColor = const Color(0xFF1A237E);
  final Color _accentColor = const Color(0xFF00BFA5);
  final Color _backgroundColor = const Color(0xFFF5F7FA);

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    auth = AuthService();
  }

  void _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        print('Iniciando proceso de registro...');

        // Register como manager de empresa (crea empresa, rol y tienda automáticamente)
        var credential = await auth!.createCompanyManagerWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
          _companyNameController.text.trim(),
          displayName: _nameController.text.trim(),
          phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        );

        var user = credential?.user;

        setState(() {
          _isLoading = false;
        });

        // Verificar si el registro fue exitoso
        if (user != null && user.uid.isNotEmpty) {
          print('Usuario registrado exitosamente: ${user.uid}');

          // Registro exitoso
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '¡Empresa ${_companyNameController.text} registrada exitosamente! Bienvenido ${_nameController.text}',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green[600],
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 3),
            ),
          );

          // Navegar a la pantalla de login
          Navigator.pushReplacementNamed(context, '/login');
        } else {
          // Si user es null o uid está vacío, mostrar error genérico
          print('Usuario es null o UID vacío');
          _showErrorMessage(
            'Error en el registro. Por favor intenta nuevamente.',
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        print('Error capturado en registro: $e');
        print('Tipo de error: ${e.runtimeType}');

        // Verificar si a pesar del error, el usuario se registró exitosamente
        try {
          await Future.delayed(Duration(milliseconds: 500));
          if (auth != null && FirebaseAuth.instance.currentUser != null) {
            var currentUser = FirebaseAuth.instance.currentUser!;
            if (currentUser.email?.toLowerCase() ==
                _emailController.text.trim().toLowerCase()) {
              print(
                'Registro exitoso detectado a pesar del error: ${currentUser.uid}',
              );

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '¡Empresa ${_companyNameController.text} registrada exitosamente! Bienvenido ${_nameController.text}',
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.green[600],
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 3),
                ),
              );

              Navigator.pushReplacementNamed(context, '/login');
              return;
            }
          }
        } catch (checkError) {
          print('Error al verificar usuario después del error: $checkError');
        }

        // Manejar errores específicos
        String errorMessage;

        if (e is FirebaseAuthException) {
          errorMessage = _getFirebaseErrorMessage(e.code);
        } else {
          // Para cualquier otro tipo de error (TypeError, PlatformException, etc.)
          errorMessage =
              'Error durante el registro. Por favor intenta nuevamente.';
        }

        _showErrorMessage(errorMessage);
      }
    }
  }

  String _getFirebaseErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'email-already-in-use':
        return '❌ Este correo electrónico ya está registrado.\nPor favor usa otro correo o inicia sesión.';
      case 'weak-password':
        return '🔒 La contraseña es muy débil.\nDebe tener al menos 6 caracteres.';
      case 'invalid-email':
        return '📧 El formato del correo electrónico no es válido.\nVerifica que esté escrito correctamente.';
      case 'network-request-failed':
        return '🌐 Error de conexión.\nVerifica tu conexión a internet.';
      case 'too-many-requests':
        return '⏱️ Demasiados intentos fallidos.\nEspera un momento antes de intentar nuevamente.';
      case 'operation-not-allowed':
        return '🚫 El registro con email no está habilitado.\nContacta al administrador.';
      case 'registration-failed':
        return '⚠️ Error durante el registro.\nPor favor intenta nuevamente en unos momentos.';
      case 'invalid-input':
        return '⚠️ Por favor completa todos los campos correctamente.';
      default:
        return '⚠️ Error en el registro: $errorCode\nPor favor intenta nuevamente.';
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
        duration: Duration(seconds: 5),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _primaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.storefront,
                size: 64,
                color: _primaryColor,
              ),
              const SizedBox(height: 16),
              Text(
                'Crear Cuenta de Empresa',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Registra tu negocio y comienza a vender',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Card(
                  elevation: 8,
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Company Name
                          _buildTextField(
                            controller: _companyNameController,
                            label: 'Nombre de la Empresa',
                            icon: Icons.business,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingresa el nombre de la empresa';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Manager Name
                          _buildTextField(
                            controller: _nameController,
                            label: 'Nombre del Administrador',
                            icon: Icons.person_outline,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingresa tu nombre';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Phone
                          _buildTextField(
                            controller: _phoneController,
                            label: 'Teléfono (Opcional)',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),

                          // Email
                          _buildTextField(
                            controller: _emailController,
                            label: 'Correo Electrónico',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingresa tu correo';
                              }
                              if (!EmailValidator.validate(value)) {
                                return 'Ingresa un correo válido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Password
                          _buildTextField(
                            controller: _passwordController,
                            label: 'Contraseña',
                            icon: Icons.lock_outline,
                            obscureText: _obscurePassword,
                            onToggleVisibility: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingresa una contraseña';
                              }
                              if (value.length < 6) {
                                return 'La contraseña debe tener al menos 6 caracteres';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Confirm Password
                          _buildTextField(
                            controller: _confirmPasswordController,
                            label: 'Confirmar Contraseña',
                            icon: Icons.lock_outline,
                            obscureText: _obscureConfirmPassword,
                            onToggleVisibility: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor confirma tu contraseña';
                              }
                              if (value != _passwordController.text) {
                                return 'Las contraseñas no coinciden';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 32),

                          // Register Button
                          SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'REGISTRAR EMPRESA',
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
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '¿Ya tienes una cuenta? ',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    child: Text(
                      'Inicia sesión',
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    VoidCallback? onToggleVisibility,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _primaryColor),
        suffixIcon: onToggleVisibility != null
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: Colors.grey[600],
                ),
                onPressed: onToggleVisibility,
              )
            : null,
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
