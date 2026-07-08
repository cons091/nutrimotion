import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'firebase_options.dart'; // 👈 archivo generado por flutterfire configure

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform, // 👈 importante
    );
  } catch (e) {
    // Sin Firebase la app no puede funcionar: mejor una pantalla clara
    // que un crash en frío al arrancar.
    runApp(StartupErrorApp(details: e.toString()));
    return;
  }
  runApp(const MyApp());
}

/// Pantalla mínima que se muestra si Firebase no pudo inicializarse
/// (p. ej. sin Google Play Services o configuración corrupta).
class StartupErrorApp extends StatelessWidget {
  final String details;

  const StartupErrorApp({super.key, required this.details});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NutriMotion',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'No se pudo iniciar la aplicación',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Revisa tu conexión e intenta abrir la app de nuevo.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  details,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Verde bosque como semilla: genera una paleta M3 más elegante que el
    // verde puro, manteniendo la identidad verdosa de la app.
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2E7D32),
    );

    // "Cama verdosa": fondo global con un tinte verde muy suave.
    const fondoVerdoso = Color(0xFFF3F8F2);

    return MaterialApp(
      title: 'NutriMotion',
      debugShowCheckedModeBanner: false,
      // Tema centralizado: los colores de marca viven aquí, no en las
      // pantallas. Para acentos puntuales usar Theme.of(context).colorScheme.
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: fondoVerdoso,

        // AppBar ligera, integrada al fondo (estilo M3 moderno).
        appBarTheme: AppBarTheme(
          backgroundColor: fondoVerdoso,
          foregroundColor: const Color(0xFF1B3B1F),
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1B3B1F),
            letterSpacing: -0.5,
          ),
        ),

        // Tarjetas planas, muy redondeadas, con borde sutil verdoso.
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFE1ECDF)),
          ),
          margin: const EdgeInsets.symmetric(vertical: 6),
        ),

        // Inputs rellenos y redondeados (aplica a TextFields y Dropdowns).
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFD5E5D2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFD5E5D2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
          ),
          prefixIconColor: colorScheme.primary,
        ),

        // Botones sólidos verdes, redondeados y sin sombra.
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),

        // Barra de navegación M3 (píldora de selección verdosa).
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: colorScheme.primaryContainer,
          elevation: 0,
          height: 68,
          labelTextStyle: WidgetStatePropertyAll(
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),

        // Diálogos y SnackBars redondeados.
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),

        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Color(0xFFD5E5D2)),
          ),
          backgroundColor: Colors.white,
          selectedColor: colorScheme.primaryContainer,
        ),

        progressIndicatorTheme: ProgressIndicatorThemeData(
          color: colorScheme.primary,
        ),
      ),
      home: const SplashScreen(), // 👈 punto de inicio
      routes: {
        "/login": (context) => const LoginScreen(),
        "/register": (context) => const RegisterScreen(),
        "/home": (context) => const HomeScreen(),
      },
    );
  }
}
