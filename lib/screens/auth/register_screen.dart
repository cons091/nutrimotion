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
      // Intentamos parsear los valores numéricos
      final peso = double.tryParse(_pesoController.text.trim());
      final altura = double.tryParse(_alturaController.text.trim());
      final edad = int.tryParse(_edadController.text.trim());

      if (peso == null ||
          altura == null ||
          edad == null ||
          peso <= 0 ||
          altura <= 0 ||
          edad <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Por favor, ingrese valores numéricos válidos (mayores a 0) para Peso, Altura y Edad.",
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Llamada al servicio de autenticación
      final user = await _authService.registerUser(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        peso: peso,
        altura: altura,
        edad: edad,
        sexo: _sexo,
        actividad: _actividad,
        objetivo: _objetivo,
      );

      if (user != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Registro exitoso 🎉. ¡Bienvenido/a a NutriMotion!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, "/home");
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Error al registrarse. Intente con otro correo."),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Lista de opciones para Dropdown (Actividad)
    final List<String> actividadOptions = [
      "Sedentario",
      "Ligero",
      "Moderado",
      "Alto",
      "Muy alto",
    ];

    // Lista de opciones para Dropdown (Objetivo)
    final List<String> objetivoOptions = [
      "Déficit",
      "Mantenimiento",
      "Recomposición",
      "Superávit",
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Completa tu perfil"),
        backgroundColor: theme.colorScheme.surfaceContainer,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            // 🎯 Subtítulo y contexto
            Text(
              "Necesitamos algunos datos para calcular tus requerimientos.",
              style: theme.textTheme.titleMedium!.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // 📧 Credenciales
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: "Correo electrónico",
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) => value != null && value.contains("@")
                  ? null
                  : "Correo inválido",
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Contraseña",
                prefixIcon: Icon(Icons.lock_outlined),
              ),
              validator: (value) => value != null && value.length >= 6
                  ? null
                  : "Mínimo 6 caracteres",
            ),
            const SizedBox(height: 24),

            Divider(color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 16),

            // 📏 Datos Físicos
            Text(
              "Datos Físicos",
              style: theme.textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Fila de Edad y Sexo
            Row(
              children: [
                // Edad
                Expanded(
                  child: TextFormField(
                    controller: _edadController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Edad",
                      prefixIcon: Icon(Icons.cake_outlined),
                    ),
                    validator: (value) =>
                        value != null && int.tryParse(value)! > 0
                        ? null
                        : "Edad inválida",
                  ),
                ),
                const SizedBox(width: 16),
                // Sexo (Usamos Dropdown más limpio)
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _sexo,
                    decoration: const InputDecoration(
                      labelText: "Sexo",
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    items: const [
                      DropdownMenuItem(value: "Hombre", child: Text("Hombre")),
                      DropdownMenuItem(value: "Mujer", child: Text("Mujer")),
                    ],
                    onChanged: (value) => setState(() => _sexo = value!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Fila de Peso y Altura
            Row(
              children: [
                // Peso
                Expanded(
                  child: TextFormField(
                    controller: _pesoController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Peso (kg)",
                      prefixIcon: Icon(Icons.monitor_weight_outlined),
                    ),
                    validator: (value) =>
                        value != null && double.tryParse(value)! > 0
                        ? null
                        : "Peso inválido",
                  ),
                ),
                const SizedBox(width: 16),
                // Altura
                Expanded(
                  child: TextFormField(
                    controller: _alturaController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Altura (cm)",
                      prefixIcon: Icon(Icons.height),
                    ),
                    validator: (value) =>
                        value != null && double.tryParse(value)! > 0
                        ? null
                        : "Altura inválida",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Divider(color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 16),

            // 🎯 Estilo de Vida y Objetivos
            Text(
              "Objetivos y Estilo de Vida",
              style: theme.textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Nivel de Actividad
            DropdownButtonFormField<String>(
              value: _actividad,
              decoration: const InputDecoration(
                labelText: "Nivel de actividad",
                prefixIcon: Icon(Icons.directions_run_outlined),
              ),
              items: actividadOptions.map((String value) {
                String display;
                if (value == "Ligero")
                  display = "Actividad ligera (1-3x/sem)";
                else if (value == "Moderado")
                  display = "Actividad moderada (3-5x/sem)";
                else if (value == "Alto")
                  display = "Actividad alta (6-7x/sem)";
                else if (value == "Muy alto")
                  display = "Actividad muy alta (trabajo físico)";
                else
                  display = value;

                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(display),
                );
              }).toList(),
              onChanged: (value) => setState(() => _actividad = value!),
            ),
            const SizedBox(height: 16),

            // Objetivo
            DropdownButtonFormField<String>(
              value: _objetivo,
              decoration: const InputDecoration(
                labelText: "Objetivo nutricional",
                prefixIcon: Icon(Icons.flag_outlined),
              ),
              items: objetivoOptions.map((String value) {
                String display;
                if (value == "Déficit")
                  display = "Déficit calórico (perder peso)";
                else if (value == "Superávit")
                  display = "Superávit calórico (ganar masa)";
                else if (value == "Recomposición")
                  display = "Recomposición corporal";
                else
                  display = value;

                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(display),
                );
              }).toList(),
              onChanged: (value) => setState(() => _objetivo = value!),
            ),
            const SizedBox(height: 32),

            // 🚀 Botón de Registro (Usa el estilo FilledButton del tema)
            FilledButton.icon(
              onPressed: _handleRegister,
              icon: const Icon(Icons.app_registration),
              label: const Text("CREAR CUENTA"),
            ),
            const SizedBox(height: 20),

            // Enlace a Login
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                '¿Ya tienes una cuenta? Inicia sesión',
                style: TextStyle(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
