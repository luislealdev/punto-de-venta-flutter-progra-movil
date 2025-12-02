import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/subscription_service.dart';

class SubscriptionWrapper extends StatefulWidget {
  final Widget child;

  const SubscriptionWrapper({super.key, required this.child});

  @override
  State<SubscriptionWrapper> createState() => _SubscriptionWrapperState();
}

class _SubscriptionWrapperState extends State<SubscriptionWrapper> {
  final AuthService _authService = AuthService();
  final SubscriptionService _subscriptionService = SubscriptionService();
  
  bool _isLoading = true;
  bool _hasActiveSubscription = false;

  @override
  void initState() {
    super.initState();
    _checkSubscription();
  }

  Future<void> _checkSubscription() async {
    try {
      final companyId = _authService.currentCompanyId;
      if (companyId == null) {
        // Si no hay companyId, probablemente no está logueado o hubo un error.
        // Dejamos pasar para que el AuthGuard (si existe) lo maneje, o mostramos error.
        // Asumiremos que si está aquí es porque pasó el login.
        setState(() {
          _isLoading = false;
          _hasActiveSubscription = false;
        });
        return;
      }

      final subscription = await _subscriptionService.getByCompany(companyId);
      
      if (mounted) {
        setState(() {
          _hasActiveSubscription = subscription != null && subscription.isActive;
          _isLoading = false;
        });

        if (!_hasActiveSubscription) {
          // Redirigir a pago si no hay suscripción activa
          // Usamos addPostFrameCallback para evitar errores de construcción
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/stripe-payment', 
              (route) => false
            );
          });
        }
      }
    } catch (e) {
      debugPrint("Error checking subscription: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Si no tiene suscripción, mostramos un Scaffold vacío mientras redirige
    // o podríamos mostrar una pantalla de "Acceso Denegado"
    if (!_hasActiveSubscription) {
      return const Scaffold(
        body: Center(
          child: Text("Verificando suscripción..."),
        ),
      );
    }

    return widget.child;
  }
}
