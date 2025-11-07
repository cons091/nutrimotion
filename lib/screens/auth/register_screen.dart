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
  final _edadController = TextEditingController();
  String _sexo = "Mujer";
  String _actividad = "Sedentario";
  String _objetivo = "Mantenimiento";

  final _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _pesoController.dispose();
    _alturaController.dispose();
    _edadController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      final user = await _authService.registerUser(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        peso: double.parse(_pesoController.text.trim()),
        altura: double.parse(_alturaController.text.trim()),
        edad: int.parse(_edadController.text.trim()),
        sexo: _sexo,
        actividad: _actividad,
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
                controller: _edadController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Edad",
                  prefixIcon: Icon(Icons.cake),
                ),
                validator: (value) =>
                    value!.isNotEmpty ? null : "Ingrese su edad",
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _sexo,
                decoration: const InputDecoration(
                  labelText: "Sexo",
                  prefixIcon: Icon(Icons.person),
                ),
                items: const [
                  DropdownMenuItem(value: "Hombre", child: Text("Hombre")),
                  DropdownMenuItem(value: "Mujer", child: Text("Mujer")),
                ],
                onChanged: (value) => setState(() => _sexo = value!),
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
                value: _actividad,
                decoration: const InputDecoration(
                  labelText: "Nivel de actividad",
                  prefixIcon: Icon(Icons.directions_run),
                ),
                items: const [
                  DropdownMenuItem(
                    value: "Sedentario",
                    child: Text("Sedentario"),
                  ),
                  DropdownMenuItem(
                    value: "Ligero",
                    child: Text("Actividad ligera (1-3x/sem)"),
                  ),
                  DropdownMenuItem(
                    value: "Moderado",
                    child: Text("Actividad moderada (3-5x/sem)"),
                  ),
                  DropdownMenuItem(
                    value: "Alto",
                    child: Text("Actividad alta (6-7x/sem)"),
                  ),
                  DropdownMenuItem(
                    value: "Muy alto",
                    child: Text("Actividad muy alta (trabajo físico)"),
                  ),
                ],
                onChanged: (value) => setState(() => _actividad = value!),
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
                    value: "Recomposición",
                    child: Text("Recomposición corporal"),
                  ),
                  DropdownMenuItem(
                    value: "Superávit",
                    child: Text("Superávit calórico"),
                  ),
                ],
                onChanged: (value) => setState(() => _objetivo = value!),
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
