import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:nutrimotion/models/user_model.dart';
import 'package:nutrimotion/services/nutrition_calculator.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  AppUser? _userData;
  bool _isEditing = false;
  bool _isLoading = false;

  final _pesoController = TextEditingController();
  final _alturaController = TextEditingController();
  final _edadController = TextEditingController();

  String? _objetivo;
  String? _sexo;
  String? _photoUrl;

  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _pesoController.dispose();
    _alturaController.dispose();
    _edadController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(currentUser.uid)
          .get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          setState(() {
            _userData = AppUser.fromMap(data);
            _pesoController.text = _userData?.peso?.toStringAsFixed(1) ?? '';
            _alturaController.text =
                _userData?.altura?.toStringAsFixed(0) ?? '';

            _edadController.text = _userData?.edad?.toString() ?? '';
            _sexo = _userData?.sexo;

            _objetivo = _userData?.objetivo ?? "Mantenimiento";
            _photoUrl = data["photoUrl"];
            _isLoading = false;
          });
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Error cargando perfil: $e");
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
        maxWidth: 800,
      );

      if (pickedFile == null) return;

      setState(() => _isLoading = true);

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception("Usuario no autenticado");

      final storageRef = FirebaseStorage.instance.ref().child(
        'profile_photos/${currentUser.uid}.jpg',
      );

      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        await storageRef.putData(
          bytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else {
        await storageRef.putFile(File(pickedFile.path));
      }
      final downloadUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance
          .collection("users")
          .doc(currentUser.uid)
          .update({"photoUrl": downloadUrl});

      if (mounted) {
        setState(() {
          _photoUrl = downloadUrl;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Foto actualizada correctamente 📸"),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);

        String message = "Error al subir la foto.";
        if (e is FirebaseException) {
          message += "\nCódigo: ${e.code}";
          if (e.code == 'permission-denied') {
            message += "\nPermiso denegado: Revisa las reglas de Storage.";
          }
        } else {
          message += "\n$e";
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _saveChanges() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final peso = double.tryParse(_pesoController.text);
    final altura = double.tryParse(_alturaController.text);
    final edad = int.tryParse(_edadController.text);

    if (peso == null ||
        altura == null ||
        edad == null ||
        peso <= 0 ||
        altura <= 0 ||
        edad < 10 ||
        _sexo == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Por favor, ingrese valores válidos para Peso, Altura, Edad y Sexo.",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(currentUser.uid)
          .update({
            "peso": peso,
            "altura": altura,
            "objetivo": _objetivo,
            "edad": edad,
            "sexo": _sexo,
          });

      await _loadUserData();

      setState(() {
        _isEditing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Datos actualizados correctamente ✅"),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al actualizar los datos: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildInfoTile(
    BuildContext context,
    String title,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.secondary),
      title: Text(
        title,
        style: theme.textTheme.bodyMedium!.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      trailing: Text(value, style: theme.textTheme.titleMedium),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildEditableTile(
    BuildContext context,
    TextEditingController controller,
    String label,
    IconData icon,
    String unit,
    TextInputType keyboardType,
    List<TextInputFormatter>? formatters,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: label,
                suffixText: unit,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 12,
                ),
              ),
              keyboardType: keyboardType,
              inputFormatters: formatters,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSexoEditableTile(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: DropdownButtonFormField<String>(
        initialValue: _sexo,
        decoration: const InputDecoration(
          labelText: "Sexo Biológico",
          prefixIcon: Icon(Icons.transgender_outlined),
          border: OutlineInputBorder(),
        ),
        items: const [
          DropdownMenuItem(value: "Hombre", child: Text("Hombre")),
          DropdownMenuItem(value: "Mujer", child: Text("Mujer")),
        ],
        onChanged: (value) => setState(() => _sexo = value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Mi Perfil"),
          backgroundColor: theme.colorScheme.surfaceContainer,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final email =
        _userData?.email ??
        FirebaseAuth.instance.currentUser?.email ??
        "Usuario";
    final peso = _userData?.peso?.toStringAsFixed(1) ?? '-';
    final altura = _userData?.altura?.toStringAsFixed(0) ?? '-';
    final edad = _userData?.edad?.toString() ?? '-';
    final sexo = _userData?.sexo ?? '-';
    final objetivo = _userData?.objetivo ?? '-';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mi Perfil"),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              color: theme.colorScheme.primary,
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        backgroundImage: _photoUrl != null
                            ? NetworkImage(_photoUrl!)
                            : null,
                        child: _photoUrl == null
                            ? Icon(
                                Icons.person,
                                size: 60,
                                color: theme.colorScheme.onPrimaryContainer,
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: _pickImage,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: theme.colorScheme.secondary,
                            child: Icon(
                              Icons.camera_alt_rounded,
                              size: 18,
                              color: theme.colorScheme.onSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    email,
                    style: theme.textTheme.titleMedium!.copyWith(
                      color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: Text(
                        "Métricas",
                        style: theme.textTheme.titleLarge!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Divider(height: 1),

                    _isEditing
                        ? _buildEditableTile(
                            context,
                            _pesoController,
                            "Peso",
                            Icons.monitor_weight_outlined,
                            "kg",
                            TextInputType.number,
                            null,
                          )
                        : _buildInfoTile(
                            context,
                            "Peso",
                            "$peso kg",
                            Icons.monitor_weight_outlined,
                          ),
                    const Divider(indent: 16, endIndent: 16),

                    _isEditing
                        ? _buildEditableTile(
                            context,
                            _alturaController,
                            "Altura",
                            Icons.height,
                            "cm",
                            TextInputType.number,
                            null,
                          )
                        : _buildInfoTile(
                            context,
                            "Altura",
                            "$altura cm",
                            Icons.height,
                          ),
                    const Divider(indent: 16, endIndent: 16),

                    _isEditing
                        ? _buildEditableTile(
                            context,
                            _edadController,
                            "Edad",
                            Icons.cake_outlined,
                            "años",
                            TextInputType.number,
                            [FilteringTextInputFormatter.digitsOnly],
                          )
                        : _buildInfoTile(
                            context,
                            "Edad",
                            "$edad años",
                            Icons.cake_outlined,
                          ),
                    const Divider(indent: 16, endIndent: 16),

                    _isEditing
                        ? _buildSexoEditableTile(context)
                        : _buildInfoTile(
                            context,
                            "Sexo Biológico",
                            sexo,
                            Icons.transgender_outlined,
                          ),
                    const Divider(indent: 16, endIndent: 16),

                    _isEditing
                        ? Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: DropdownButtonFormField<String>(
                              initialValue:
                                  NutritionCalculator.goalAdjustments.keys
                                      .contains(_objetivo)
                                  ? _objetivo
                                  : 'Mantener peso',
                              decoration: const InputDecoration(
                                labelText: "Objetivo",
                                prefixIcon: Icon(Icons.flag_outlined),
                                border: OutlineInputBorder(),
                              ),
                              items: NutritionCalculator.goalAdjustments.keys
                                  .map((String goalKey) {
                                    return DropdownMenuItem<String>(
                                      value: goalKey,
                                      child: Text(goalKey),
                                    );
                                  })
                                  .toList(),
                              onChanged: (value) =>
                                  setState(() => _objetivo = value),
                            ),
                          )
                        : _buildInfoTile(
                            context,
                            "Objetivo",
                            objetivo,
                            Icons.flag_outlined,
                          ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ListTile(
                leading: Icon(
                  Icons.logout_rounded,
                  color: theme.colorScheme.error,
                ),
                title: Text(
                  "Cerrar Sesión",
                  style: theme.textTheme.titleMedium!.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  if (!context.mounted) return;

                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    "/login",
                    (route) => false,
                  );
                },
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_isEditing) {
            _saveChanges();
          } else {
            setState(() => _isEditing = true);
          }
        },
        icon: Icon(_isEditing ? Icons.save_rounded : Icons.edit_rounded),
        label: Text(_isEditing ? "Guardar Cambios" : "Editar Perfil"),
        backgroundColor: _isEditing
            ? theme.colorScheme.secondary
            : theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
    );
  }
}
