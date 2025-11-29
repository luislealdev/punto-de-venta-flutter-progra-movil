import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:punto_de_venta/config/app_config.dart';
import 'package:punto_de_venta/firebase_options.dart';
import 'package:punto_de_venta/screens/app/admin/add_edit_customer_screen.dart';
import 'package:punto_de_venta/screens/app/admin/add_edit_product_screen.dart';
import 'package:punto_de_venta/screens/app/admin/add_edit_provider_screen.dart';
import 'package:punto_de_venta/screens/app/admin/add_edit_store_screen.dart';
import 'package:punto_de_venta/screens/app/admin/add_edit_variety_screen.dart';
import 'package:punto_de_venta/screens/app/admin/customers_screen.dart';
import 'package:punto_de_venta/screens/app/admin/home_screen.dart';
import 'package:punto_de_venta/screens/app/admin/new_sale_screen.dart';
import 'package:punto_de_venta/screens/app/admin/sales_management_screen.dart';
import 'package:punto_de_venta/screens/app/admin/product_varieties_screen.dart';
import 'package:punto_de_venta/screens/app/admin/products_screen.dart';
import 'package:punto_de_venta/screens/app/admin/providers_screen.dart';
import 'package:punto_de_venta/screens/app/admin/stores_screen.dart';
import 'package:punto_de_venta/screens/auth/login_screen.dart';
import 'package:punto_de_venta/screens/auth/register_screen.dart';
import 'package:punto_de_venta/utils/theme_app.dart';

// Provider imports
import 'package:provider/provider.dart';
import 'package:punto_de_venta/providers/auth_provider.dart';
import 'package:punto_de_venta/providers/theme_provider.dart';
import 'package:punto_de_venta/providers/product_provider.dart';
import 'package:punto_de_venta/providers/customer_provider.dart';
import 'package:punto_de_venta/providers/supplier_provider.dart';
import 'package:punto_de_venta/providers/sale_provider.dart';
import 'package:punto_de_venta/providers/store_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cargar variables de entorno
  await dotenv.load(fileName: ".env");

  // Validar configuración
  AppConfig.validateConfiguration();
  AppConfig.printConfiguration();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Ejecutar app con MultiProvider
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => SupplierProvider()),
        ChangeNotifierProvider(create: (_) => SaleProvider()),
        ChangeNotifierProvider(create: (_) => StoreProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Usar Provider para el tema en lugar de ValueListenableBuilder
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          theme: themeProvider.isDarkMode
              ? ThemeApp.darkTheme()
              : ThemeApp.lightTheme(),
          themeMode: themeProvider.themeMode,
          routes: {
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/home': (context) => const HomeScreen(),
            '/products': (context) => const ProductsScreen(),
            '/customers': (context) => const CustomersScreen(),
            '/providers': (context) => const ProvidersScreen(),
            '/stores': (context) => const StoresScreen(),
            '/new-sale': (context) => const NewSaleScreen(),
            '/sales-management': (context) => const SalesManagementScreen(),
          },
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case '/products/add':
                final args = settings.arguments as Map<String, dynamic>?;
                return MaterialPageRoute(
                  builder: (context) =>
                      AddEditProductScreen(companyId: args?['companyId'] ?? ''),
                );
              case '/products/edit':
                final args = settings.arguments as Map<String, dynamic>?;
                return MaterialPageRoute(
                  builder: (context) => AddEditProductScreen(
                    product: args?['product'],
                    companyId: args?['companyId'] ?? '',
                  ),
                );
              case '/products/varieties':
                final args = settings.arguments as Map<String, dynamic>?;
                return MaterialPageRoute(
                  builder: (context) => ProductVarietiesScreen(
                    product: args?['product'],
                    companyId: args?['companyId'] ?? '',
                  ),
                );
              case '/products/varieties/add':
                final args = settings.arguments as Map<String, dynamic>?;
                return MaterialPageRoute(
                  builder: (context) => AddEditVarietyScreen(
                    product: args?['product'],
                    companyId: args?['companyId'] ?? '',
                  ),
                );
              case '/products/varieties/edit':
                final args = settings.arguments as Map<String, dynamic>?;
                return MaterialPageRoute(
                  builder: (context) => AddEditVarietyScreen(
                    variety: args?['variety'],
                    product: args?['product'],
                    companyId: args?['companyId'] ?? '',
                  ),
                );
              case '/customers':
                return MaterialPageRoute(
                  builder: (context) => const CustomersScreen(),
                );
              case '/customers/add':
                final args = settings.arguments as Map<String, dynamic>?;
                return MaterialPageRoute(
                  builder: (context) => AddEditCustomerScreen(
                    companyId: args?['companyId'] ?? '',
                  ),
                );
              case '/customers/edit':
                final args = settings.arguments as Map<String, dynamic>?;
                return MaterialPageRoute(
                  builder: (context) => AddEditCustomerScreen(
                    customer: args?['customer'],
                    companyId: args?['companyId'] ?? '',
                  ),
                );
              case '/providers':
                return MaterialPageRoute(
                  builder: (context) => const ProvidersScreen(),
                );
              case '/providers/add':
                final args = settings.arguments as Map<String, dynamic>?;
                return MaterialPageRoute(
                  builder: (context) => AddEditProviderScreen(
                    companyId: args?['companyId'] ?? '',
                  ),
                );
              case '/providers/edit':
                final args = settings.arguments as Map<String, dynamic>?;
                return MaterialPageRoute(
                  builder: (context) => AddEditProviderScreen(
                    provider: args?['provider'],
                    companyId: args?['companyId'] ?? '',
                  ),
                );
              case '/stores/add':
                final args = settings.arguments as Map<String, dynamic>?;
                return MaterialPageRoute(
                  builder: (context) =>
                      AddEditStoreScreen(companyId: args?['companyId'] ?? ''),
                );
              case '/stores/edit':
                final args = settings.arguments as Map<String, dynamic>?;
                return MaterialPageRoute(
                  builder: (context) => AddEditStoreScreen(
                    store: args?['store'],
                    companyId: args?['companyId'] ?? '',
                  ),
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
