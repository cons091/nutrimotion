import 'package:flutter/material.dart';
import 'package:nutrimotion/services/auth_service.dart';
import 'package:nutrimotion/utils/validators.dart';
import 'package:nutrimotion/utils/user_options.dart';

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
    if (!_formKey.currentState!.validate()) return;

    // Parse seguro: los validadores ya garantizan que son números válidos,
    // pero tryParse evita cualquier crash si el estado cambia.
    final peso = Validators.parseDouble(_pesoController.text);
    final altura = Validators.parseDouble(_alturaController.text);
    final edad = Validators.parseInt(_edadController.text);
    if (peso == null || altura == null || edad == null) return;

    try {
      await _authService.registerUser(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        peso: peso,
        altura: altura,
        edad: edad,
        sexo: _sexo,
        actividad: _actividad,
        objetivo: _objetivo,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Registro exitoso 🎉"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushReplacementNamed(context, "/home");
    } on AuthException catch (e) {
      // Mensaje ya traducido por AuthService (correo en uso, red, etc.).
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
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
                validator: Validators.email,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Contraseña",
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: Validators.password,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _edadController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Edad",
                  prefixIcon: Icon(Icons.cake),
                ),
                validator: Validators.edad,
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                initialValue: _sexo,
                decoration: const InputDecoration(
                  labelText: "Sexo",
                  prefixIcon: Icon(Icons.person),
                ),
                items: UserOptions.sexoItems(),
                onChanged: (value) => setState(() => _sexo = value!),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _pesoController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: "Peso (kg)",
                  prefixIcon: Icon(Icons.fitness_center),
                ),
                validator: Validators.peso,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _alturaController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: "Altura (cm)",
                  prefixIcon: Icon(Icons.height),
                ),
                validator: Validators.altura,
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                initialValue: _actividad,
                decoration: const InputDecoration(
                  labelText: "Nivel de actividad",
                  prefixIcon: Icon(Icons.directions_run),
                ),
                items: UserOptions.items(UserOptions.actividades),
                onChanged: (value) => setState(() => _actividad = value!),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                initialValue: _objetivo,
                decoration: const InputDecoration(
                  labelText: "Objetivo",
                  prefixIcon: Icon(Icons.flag),
                ),
                items: UserOptions.items(UserOptions.objetivos),
                onChanged: (value) => setState(() => _objetivo = value!),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _handleRegister,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
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
