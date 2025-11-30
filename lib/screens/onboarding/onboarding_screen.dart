import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:punto_de_venta/services/onboarding_service.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return IntroductionScreen(
      pages: _getPages(context),
      onDone: () => _onDone(context),
      onSkip: () => _onDone(context),
      showSkipButton: true,
      skip: const Text(
        'Saltar',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      next: const Icon(Icons.arrow_forward, size: 28),
      done: const Text(
        'Comenzar',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      dotsDecorator: DotsDecorator(
        size: const Size.square(10.0),
        activeSize: const Size(20.0, 10.0),
        activeColor: Theme.of(context).primaryColor,
        color: Colors.grey.shade300,
        spacing: const EdgeInsets.symmetric(horizontal: 3.0),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25.0),
        ),
      ),
      globalBackgroundColor: Colors.white,
      animationDuration: 300,
      curve: Curves.easeInOut,
    );
  }

  List<PageViewModel> _getPages(BuildContext context) {
    return [
      // Slide 1: Bienvenida
      PageViewModel(
        title: "Bienvenido a Punto de Venta",
        body:
            "La solución completa para gestionar tu negocio de forma fácil y profesional",
        image: _buildImage(
          context,
          Icons.store,
          const Color(0xFF2196F3), // Azul
        ),
        decoration: _getPageDecoration(
          const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE3F2FD), Colors.white],
          ),
        ),
      ),

      // Slide 2: Ventas Rápidas
      PageViewModel(
        title: "Ventas en Segundos",
        body:
            "Registra ventas rápidamente, genera tickets y cobra de forma eficiente",
        image: _buildImage(
          context,
          Icons.point_of_sale,
          const Color(0xFF4CAF50), // Verde
        ),
        decoration: _getPageDecoration(
          const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8F5E9), Colors.white],
          ),
        ),
      ),

      // Slide 3: Control de Inventario
      PageViewModel(
        title: "Inventario Inteligente",
        body:
            "Controla tu stock, recibe alertas y gestiona productos en tiempo real",
        image: _buildImage(
          context,
          Icons.inventory_2,
          const Color(0xFFFF9800), // Naranja
        ),
        decoration: _getPageDecoration(
          const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF3E0), Colors.white],
          ),
        ),
      ),

      // Slide 4: Reportes
      PageViewModel(
        title: "Reportes Detallados",
        body:
            "Visualiza ventas, ganancias y estadísticas de tu negocio al instante",
        image: _buildImage(
          context,
          Icons.analytics,
          const Color(0xFF9C27B0), // Morado
        ),
        decoration: _getPageDecoration(
          const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF3E5F5), Colors.white],
          ),
        ),
      ),

      // Slide 5: Multitenant
      PageViewModel(
        title: "Múltiples Tiendas",
        body: "Gestiona todas tus sucursales desde una sola plataforma",
        image: _buildImage(
          context,
          Icons.business,
          const Color(0xFF1976D2), // Azul oscuro
        ),
        decoration: _getPageDecoration(
          const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE1F5FE), Colors.white],
          ),
        ),
      ),
    ];
  }

  Widget _buildImage(BuildContext context, IconData icon, Color color) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.1),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Icon(icon, size: 120, color: color),
      ),
    );
  }

  PageDecoration _getPageDecoration(Gradient gradient) {
    return PageDecoration(
      titleTextStyle: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1A237E),
      ),
      bodyTextStyle: const TextStyle(
        fontSize: 18,
        color: Color(0xFF424242),
        height: 1.5,
      ),
      imagePadding: const EdgeInsets.only(top: 80, bottom: 40),
      bodyPadding: const EdgeInsets.symmetric(horizontal: 24),
      titlePadding: const EdgeInsets.only(top: 20, bottom: 16),
      contentMargin: const EdgeInsets.symmetric(horizontal: 16),
      // Removed pageColor to fix null assertion error
      // Using boxDecoration with gradient instead
      boxDecoration: BoxDecoration(gradient: gradient),
    );
  }

  Future<void> _onDone(BuildContext context) async {
    // Marcar onboarding como completado
    await OnboardingService.completeOnboarding();

    // Navegar al home (ya está logueado)
    if (context.mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }
}
