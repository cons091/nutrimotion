import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nutrimotion/screens/home/home_screen.dart';
import 'package:nutrimotion/screens/auth/login_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // 1. Estado de espera
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 🏆 Branding: NutriMotion (Consistente con Login)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.directions_run_rounded,
                        size: 60, // Tamaño más grande para Splash
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'NutriMotion',
                        style: theme.textTheme.displayMedium!.copyWith(
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.onBackground,
                          letterSpacing: -1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  CircularProgressIndicator(
                    color:
                        theme.colorScheme.primary, // Usamos el color principal
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            );
          }
          // 2. Usuario logueado
          else if (snapshot.hasData) {
            return const HomeScreen();
          }
          // 3. No hay usuario logueado
          else {
            return const LoginScreen();
          }
        },
      ),
    );
  }
}
