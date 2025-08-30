import 'package:flutter/material.dart';
import 'package:nutrimotion/services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mi Perfil")),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await AuthService().signOut();
            if (context.mounted) {
              Navigator.pushReplacementNamed(context, "/login");
            }
          },
          child: const Text("Cerrar sesión"),
        ),
      ),
    );
  }
}
