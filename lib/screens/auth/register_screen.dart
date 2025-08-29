import 'package:flutter/material.dart';
import 'package:nutrimotion/services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _pesoController = TextEditingController();
  final _alturaController = TextEditingController();
  String _objetivo = "Mantenimiento"; // valor por defecto

  final _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _pesoController.dispose();
    _alturaController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      final user = await _authService.registerUser(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        peso: double.parse(_pesoController.text.trim()),
        altura: double.parse(_alturaController.text.trim()),
        objetivo: _objetivo,
      );

      if (user != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Registro exitoso 🎉"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, "/home");
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error al registrarse"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Crear cuenta")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: "Correo electrónico",
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) =>
                    value!.contains("@") ? null : "Correo inválido",
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Contraseña",
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (value) =>
                    value!.length >= 6 ? null : "Mínimo 6 caracteres",
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _pesoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Peso (kg)",
                  prefixIcon: Icon(Icons.fitness_center),
                ),
                validator: (value) =>
                    value!.isNotEmpty ? null : "Ingrese su peso",
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _alturaController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Altura (cm)",
                  prefixIcon: Icon(Icons.height),
                ),
                validator: (value) =>
                    value!.isNotEmpty ? null : "Ingrese su altura",
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _objetivo,
                decoration: const InputDecoration(
                  labelText: "Objetivo",
                  prefixIcon: Icon(Icons.flag),
                ),
                items: const [
                  DropdownMenuItem(
                    value: "Déficit",
                    child: Text("Déficit calórico"),
                  ),
                  DropdownMenuItem(
                    value: "Mantenimiento",
                    child: Text("Mantenimiento"),
                  ),
                  DropdownMenuItem(
                    value: "Superávit",
                    child: Text("Superávit calórico"),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _objetivo = value!;
                  });
                },
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _handleRegister,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.green,
                ),
                child: const Text("Registrarse"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
