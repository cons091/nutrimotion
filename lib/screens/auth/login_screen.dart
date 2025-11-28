import 'package:flutter/material.dart';
import 'package:nutrimotion/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Estado y Controladores de lógica
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false; // Estado para manejar el indicador de carga

  final _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Lógica de inicio de sesión (MANTENIDA)
  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true); // Iniciar carga

      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      // Validación simple extra
      if (!email.contains("@")) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Correo no válido"),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      try {
        final user = await _authService.loginUser(email, password);

        if (user != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Login exitoso 🎉"),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
          Navigator.pushReplacementNamed(context, "/home");
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Error: credenciales incorrectas"),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          String errorMessage;
          if (e.code == 'user-not-found') {
            errorMessage = "No existe usuario con este correo.";
          } else if (e.code == 'wrong-password') {
            errorMessage = "Contraseña incorrecta.";
          } else {
            errorMessage = e.message ?? "Error desconocido.";
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error de autenticación: $errorMessage"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false); // Detener carga
        }
      }
    }
  }

  // 🔑 NUEVA LÓGICA: Manejar el flujo de restablecimiento de contraseña
  void _handleForgotPassword() async {
    final email = _emailController.text
        .trim(); // Intentar usar el email ya escrito

    // 1. Mostrar diálogo de confirmación/entrada de correo
    final inputEmail = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        // Usaremos un controlador local para el diálogo si el campo principal está vacío
        final dialogEmailController = TextEditingController(
          text: email.isNotEmpty && email.contains("@") ? email : "",
        );
        final dialogFormKey = GlobalKey<FormState>();

        return AlertDialog(
          title: const Text("Restablecer Contraseña"),
          content: Form(
            key: dialogFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Ingresa tu correo para recibir las instrucciones."),
                const SizedBox(height: 16),
                TextFormField(
                  controller: dialogEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: "Correo",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty ||
                        !value.contains("@")) {
                      return "Ingresa un correo válido";
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancelar"),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              child: const Text("Enviar"),
              onPressed: () {
                if (dialogFormKey.currentState!.validate()) {
                  Navigator.of(
                    dialogContext,
                  ).pop(dialogEmailController.text.trim());
                }
              },
            ),
          ],
        );
      },
    );

    // 2. Procesar el resultado del diálogo
    if (inputEmail != null && inputEmail.isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        await _authService.sendPasswordResetEmail(inputEmail);

        if (mounted) {
          // Notificar éxito al usuario
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Instrucciones enviadas a $inputEmail. ¡Revisa tu bandeja!",
              ),
              backgroundColor: Theme.of(context).colorScheme.tertiary,
            ),
          );
        }
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          String errorMessage;
          if (e.code == 'user-not-found') {
            errorMessage = "No se encontró un usuario con ese correo.";
          } else if (e.code == 'invalid-email') {
            errorMessage = "El correo ingresado no es válido.";
          } else {
            errorMessage =
                e.message ?? "Error desconocido al intentar restablecer.";
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // Se utiliza el color de fondo del tema
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth:
                  450, // Ligeramente más ancho para un mejor diseño en tabletas
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 🍏 Logo y Título
                Icon(
                  Icons
                      .local_fire_department_rounded, // Icono representativo (fuerza y energía)
                  size: 80,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  "NutriMotion",
                  style: theme.textTheme.displaySmall!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Bienvenido de nuevo",
                  style: theme.textTheme.titleMedium!.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 40),

                // 📝 Formulario de Inicio de Sesión
                Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Campo de Correo
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: "Correo electrónico",
                              hintText: "ejemplo@correo.com",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(12),
                                ),
                              ),
                              prefixIcon: Icon(Icons.email_rounded),
                            ),
                            validator: (value) {
                              if (value == null ||
                                  value.isEmpty ||
                                  !value.contains("@")) {
                                return "Ingresa un correo válido";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Campo de Contraseña
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            decoration: InputDecoration(
                              labelText: "Contraseña",
                              border: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(12),
                                ),
                              ),
                              prefixIcon: const Icon(Icons.lock_rounded),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility_rounded
                                      : Icons.visibility_off_rounded,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Ingresa tu contraseña";
                              }
                              if (value.length < 6) {
                                return "Mínimo 6 caracteres";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 40),

                          // 🚀 Botón de Iniciar Sesión
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: _isLoading
                                  ? null
                                  : _handleLogin, // Deshabilitar si está cargando
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 5,
                              ),
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.login_rounded),
                              label: Text(
                                _isLoading ? "Iniciando..." : "Iniciar Sesión",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          // 🔑 Enlace a Olvidaste tu Contraseña
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : _handleForgotPassword, // Deshabilitar si está cargando
                              child: Text(
                                "¿Olvidaste tu contraseña?",
                                style: theme.textTheme.bodyMedium!.copyWith(
                                  color: theme.colorScheme.secondary,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Enlace a Registro
                TextButton(
                  onPressed: () {
                    if (!_isLoading) {
                      Navigator.pushNamed(context, "/register");
                    }
                  },
                  child: Text(
                    "¿No tienes cuenta? Regístrate aquí",
                    style: theme.textTheme.bodyLarge!.copyWith(
                      color: theme.colorScheme.secondary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
