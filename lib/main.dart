import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:punto_de_venta/config/app_config.dart';
import 'package:punto_de_venta/firebase_options.dart';
import 'package:punto_de_venta/screens/app/admin/add_edit_customer_screen.dart';
import 'package:punto_de_venta/screens/app/admin/add_edit_employee_screen.dart';
import 'package:punto_de_venta/screens/app/admin/add_edit_product_screen.dart';
import 'package:punto_de_venta/screens/app/admin/add_edit_provider_screen.dart';
import 'package:punto_de_venta/screens/app/admin/add_edit_store_screen.dart';
import 'package:punto_de_venta/screens/app/admin/add_edit_variety_screen.dart';
import 'package:punto_de_venta/screens/app/admin/customers_screen.dart';
import 'package:punto_de_venta/screens/app/admin/employees_screen.dart';
import 'package:punto_de_venta/screens/app/admin/home_screen.dart';
import 'package:punto_de_venta/screens/app/admin/new_sale_screen.dart';
import 'package:punto_de_venta/screens/app/admin/sales_management_screen.dart';
import 'package:punto_de_venta/screens/app/admin/stripe_payment_screen.dart';
import 'package:punto_de_venta/screens/app/admin/product_varieties_screen.dart';
import 'package:punto_de_venta/screens/app/admin/products_screen.dart';
import 'package:punto_de_venta/screens/app/admin/profile_screen.dart';
import 'package:punto_de_venta/screens/app/admin/providers_screen.dart';
import 'package:punto_de_venta/screens/app/admin/reports_screen.dart';
import 'package:punto_de_venta/screens/app/admin/stores_screen.dart';
import 'package:punto_de_venta/models/employee_dto.dart';
import 'package:punto_de_venta/screens/auth/login_screen.dart';
import 'package:punto_de_venta/screens/auth/register_screen.dart';
import 'package:punto_de_venta/screens/onboarding/onboarding_screen.dart';
import 'package:punto_de_venta/services/auth_service.dart';
import 'package:punto_de_venta/utils/theme_app.dart';
import 'package:punto_de_venta/utils/value_listener.dart';
import 'package:punto_de_venta/utils/subscription_wrapper.dart';

Future<void> _backgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cargar variables de entorno
  await dotenv.load(fileName: ".env");

  // Configurar Stripe
  Stripe.publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY_TEST'] ?? '';

  // Validar configuración
  AppConfig.validateConfiguration();
  AppConfig.printConfiguration();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(_backgroundHandler);

  // Inicializar contexto del usuario si ya está autenticado
  final authService = AuthService();
  await authService.initializeContext();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  @override
  void initState() {
    super.initState();
    _setupNotifications();
  }

  void _setupNotifications() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('User granted permission: ${settings.authorizationStatus}');

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Message data: ${message.data}');
      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Message clicked! ${message.messageId}');
    });
    
    // Imprimir token para pruebas
    // En iOS, necesitamos esperar a que el token APNS esté disponible antes de obtener el token FCM
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      String? apnsToken = await _firebaseMessaging.getAPNSToken();
      if (apnsToken != null) {
        final token = await _firebaseMessaging.getToken();
        debugPrint("FCM Token: $token");
      } else {
        debugPrint("APNS Token not available yet");
        // Reintentar después de un breve retraso si es necesario
        Future.delayed(const Duration(seconds: 3), () async {
          apnsToken = await _firebaseMessaging.getAPNSToken();
          if (apnsToken != null) {
            final token = await _firebaseMessaging.getToken();
            debugPrint("FCM Token (retry): $token");
          } else {
            debugPrint("APNS Token still not available");
          }
        });
      }
    } else {
      final token = await _firebaseMessaging.getToken();
      debugPrint("FCM Token: $token");
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: ValueListener.isDark,
      builder: (context, value, _) {
        return MaterialApp(
          theme: value ? ThemeApp.darkTheme() : ThemeApp.lightTheme(),
          initialRoute: '/login',
          routes: {
            '/onboarding': (context) => const OnboardingScreen(),
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/home': (context) => const SubscriptionWrapper(child: HomeScreen()),
            '/profile': (context) => const SubscriptionWrapper(child: ProfileScreen()),
            '/products': (context) => const SubscriptionWrapper(child: ProductsScreen()),
            '/customers': (context) => const SubscriptionWrapper(child: CustomersScreen()),
            '/providers': (context) => const SubscriptionWrapper(child: ProvidersScreen()),
            '/stores': (context) => const SubscriptionWrapper(child: StoresScreen()),
            '/employees': (context) => const SubscriptionWrapper(child: EmployeesScreen()),
            '/reports': (context) => const SubscriptionWrapper(child: ReportsScreen()),
            '/new-sale': (context) => const SubscriptionWrapper(child: NewSaleScreen()),
            '/sales-management': (context) => const SubscriptionWrapper(child: SalesManagementScreen()),
            '/stripe-payment': (context) => const StripePaymentScreen(),
          },
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case '/products/add':
                final args = settings.arguments as Map<String, dynamic>?;
                return MaterialPageRoute(
                  builder: (context) => SubscriptionWrapper(
                    child: AddEditProductScreen(companyId: args?['companyId'] ?? ''),
                  ),
                );
              case '/products/edit':
                final args = settings.arguments as Map<String, dynamic>?;
                return MaterialPageRoute(
                  builder: (context) => SubscriptionWrapper(
                    child: AddEditProductScreen(
                      product: args?['product'],
                      companyId: args?['companyId'] ?? '',
                    ),
                  ),
                );
              case '/products/varieties':
                final args = settings.arguments as Map<String, dynamic>?;
                return MaterialPageRoute(
                  builder: (context) => SubscriptionWrapper(
                    child: ProductVarietiesScreen(
                      product: args?['product'],
                      companyId: args?['companyId'] ?? '',
                    ),
                  ),
                );
              case '/products/varieties/add':
                final args = settings.arguments as Map<String, dynamic>?;
                return MaterialPageRoute(
                  builder: (context) => SubscriptionWrapper(
                    child: AddEditVarietyScreen(
                      product: args?['product'],
                      companyId: args?['companyId'] ?? '',
                    ),
                  ),
                );
              case '/products/varieties/edit':
                final args = settings.arguments as Map<String, dynamic>?;
                return MaterialPageRoute(
                  builder: (context) => SubscriptionWrapper(
                    child: AddEditVarietyScreen(
                      variety: args?['variety'],
                      product: args?['product'],
                      companyId: args?['companyId'] ?? '',
                    ),
                  ),
                );
              case '/customers':
                return MaterialPageRoute(
                  builder: (context) => const SubscriptionWrapper(child: CustomersScreen()),
                );
              case '/customers/add':
                final args = settings.arguments as Map<String, dynamic>?;
                return MaterialPageRoute(
                  builder: (context) => SubscriptionWrapper(
                    child: AddEditCustomerScreen(
                      companyId: args?['companyId'] ?? '',
                    ),
                  ),
                );
              case '/customers/edit':
                final args = settings.arguments as Map<String, dynamic>?;
                return MaterialPageRoute(
                  builder: (context) => SubscriptionWrapper(
                    child: AddEditCustomerScreen(
                      customer: args?['customer'],
                      companyId: args?['companyId'] ?? '',
                    ),
                  ),
                );
              case '/providers':
                return MaterialPageRoute(
                  builder: (context) => const SubscriptionWrapper(child: ProvidersScreen()),
                );
              case '/providers/add':
                final args = settings.arguments as Map<String, dynamic>?;
                return MaterialPageRoute(
                  builder: (context) => SubscriptionWrapper(
                    child: AddEditProviderScreen(
                      companyId: args?['companyId'] ?? '',
                    ),
                  ),
                );
              case '/providers/edit':
                final args = settings.arguments as Map<String, dynamic>?;
                return MaterialPageRoute(
                  builder: (context) => SubscriptionWrapper(
                    child: AddEditProviderScreen(
                      provider: args?['provider'],
                      companyId: args?['companyId'] ?? '',
                    ),
                  ),
                );
              case '/stores/add':
                final args = settings.arguments as Map<String, dynamic>?;
                return MaterialPageRoute(
                  builder: (context) => SubscriptionWrapper(
                    child: AddEditStoreScreen(companyId: args?['companyId'] ?? ''),
                  ),
                );
              case '/stores/edit':
                final args = settings.arguments as Map<String, dynamic>?;
                return MaterialPageRoute(
                  builder: (context) => SubscriptionWrapper(
                    child: AddEditStoreScreen(
                      store: args?['store'],
                      companyId: args?['companyId'] ?? '',
                    ),
                  ),
                );
              case '/add-employee':
                return MaterialPageRoute(
                  builder: (context) => const SubscriptionWrapper(child: AddEditEmployeeScreen()),
                );
              case '/edit-employee':
                final employee = settings.arguments as EmployeeDTO?;
                return MaterialPageRoute(
                  builder: (context) => SubscriptionWrapper(child: AddEditEmployeeScreen(employee: employee)),
                );
              default:
                return null;
            }
          },
          debugShowCheckedModeBanner: false,
          home: const LoginScreen(),
        );
      },
    );
  }
}
