import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:punto_de_venta/firebase_options.dart';
import 'package:punto_de_venta/screens/app/admin/add_edit_product_screen.dart';
import 'package:punto_de_venta/screens/app/admin/add_edit_variety_screen.dart';
import 'package:punto_de_venta/screens/app/admin/home_screen.dart';
import 'package:punto_de_venta/screens/app/admin/product_varieties_screen.dart';
import 'package:punto_de_venta/screens/app/admin/products_screen.dart';
import 'package:punto_de_venta/screens/auth/login_screen.dart';
import 'package:punto_de_venta/screens/auth/register_screen.dart';
import 'package:punto_de_venta/utils/theme_app.dart';
import 'package:punto_de_venta/utils/value_listener.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: ValueListener.isDark,
      builder: (context, value, _) {
        return MaterialApp(
          theme: value ? ThemeApp.darkTheme() : ThemeApp.lightTheme(),
          routes: {
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/home': (context) => const HomeScreen(),
            '/products': (context) => const ProductsScreen(),
          },
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case '/products/add':
                final args = settings.arguments as Map<String, dynamic>?;
                return MaterialPageRoute(
                  builder: (context) => AddEditProductScreen(
                    companyId: args?['companyId'] ?? '',
                  ),
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
