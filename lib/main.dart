import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:punto_de_venta/firebase_options.dart';
import 'package:punto_de_venta/screens/app/admin/home_screen.dart';
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
          },
          debugShowCheckedModeBanner: false,
          home: const LoginScreen(),
        );
      },
    );
  }
}
