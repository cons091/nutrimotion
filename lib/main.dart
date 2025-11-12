import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('es_ES', null);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Definimos la semilla de color principal (un verde más brillante y activo)
    const Color primaryColorSeed = Color(0xFF4CAF50); // Verde brillante

    return MaterialApp(
      title: 'NutriMotion',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Generamos un esquema de colores a partir de la semilla
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColorSeed,
          // Un esquema de colores más oscuro (dark scheme) podría ser atractivo para fitness apps,
          // pero mantendremos el claro por defecto.
        ),

        // 🔑 Mejoramos la fuente tipográfica si es necesario (ej: Google Fonts)
        // Por ahora, usaremos la tipografía Material 3 por defecto que es moderna.

        // Estilo de botones elevado (FilledButton)
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),

        // Estilo de campos de texto
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16.0,
            horizontal: 16.0,
          ),
        ),

        useMaterial3: true,
      ),
      initialRoute: "/",
      routes: {
        "/": (context) =>
            const SplashScreen(), // Establecer splash como ruta inicial
        "/login": (context) => const LoginScreen(),
        "/register": (context) => const RegisterScreen(),
        "/home": (context) => const HomeScreen(),
      },
    );
  }
}
