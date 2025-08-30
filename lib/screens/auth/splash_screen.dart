import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nutrimotion/screens/home/home_screen.dart';
import 'package:nutrimotion/screens/auth/login_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Mientras espera la respuesta
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasData) {
            // ✅ Usuario logueado
            return const HomeScreen();
          } else {
            // ❌ No hay usuario logueado
            return const LoginScreen();
          }
        },
      ),
    );
  }
}
