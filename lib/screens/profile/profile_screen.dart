import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:nutrimotion/models/user_model.dart'; // Asumiendo que AppUser está aquí

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
  String? _objetivo;
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
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    setState(() => _isLoading = true);

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(currentUser.uid)
        .get();

    if (doc.exists) {
      final data = doc.data();
      if (data != null) {
        setState(() {
          _userData = AppUser.fromMap(data);
          _pesoController.text =
              _userData?.peso?.toStringAsFixed(1) ??
              ''; // Mostrar con 1 decimal
          _alturaController.text =
              _userData?.altura?.toStringAsFixed(0) ??
              ''; // Mostrar sin decimal
          _objetivo = _userData?.objetivo ?? "Mantenimiento";
          _photoUrl = data["photoUrl"];
          _isLoading = false;
        });
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );
    if (pickedFile == null) return;

    setState(() => _isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final storageRef = FirebaseStorage.instance.ref().child(
        'profile_photos/${currentUser!.uid}.jpg',
      );

      // Usar putFile con metadata para mejorar el rendimiento
      await storageRef.putFile(File(pickedFile.path));
      final downloadUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance
          .collection("users")
          .doc(currentUser.uid)
          .update({"photoUrl": downloadUrl});

      setState(() {
        _photoUrl = downloadUrl;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Foto actualizada 📸"),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error al subir la foto"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveChanges() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Validación básica de datos antes de guardar
    final peso = double.tryParse(_pesoController.text);
    final altura = double.tryParse(_alturaController.text);

    if (peso == null || altura == null || peso <= 0 || altura <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Por favor, ingrese valores válidos para Peso y Altura.",
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
          .update({"peso": peso, "altura": altura, "objetivo": _objetivo});

      // Recargar datos para reflejar los cambios guardados
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
          const SnackBar(
            content: Text("Error al actualizar los datos"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Widget auxiliar para construir un ListTile limpio
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

  // Widget auxiliar para construir campos de edición
  Widget _buildEditableTile(
    BuildContext context,
    TextEditingController controller,
    String label,
    IconData icon,
    String unit,
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
              keyboardType: TextInputType.number,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading || _userData == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Mi Perfil"),
          backgroundColor: theme.colorScheme.surfaceContainer,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mi Perfil"),
        backgroundColor: theme.colorScheme.primary, // AppBar con color primario
        foregroundColor: theme.colorScheme.onPrimary, // Iconos y texto blancos
        elevation: 0, // Sin sombra
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 🖼️ HEADER DE PERFIL Y FOTO
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              color: theme.colorScheme.primary,
              child: Column(
                children: [
                  Stack(
                    children: [
                      // Avatar
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
                      // Botón de Carga de Foto
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
                  // Correo
                  Text(
                    _userData!.email ?? "Usuario sin correo",
                    style: theme.textTheme.titleMedium!.copyWith(
                      color: theme.colorScheme.onPrimary.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            // 📊 TARJETA DE DATOS FÍSICOS
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

                    // Fila de Peso
                    _isEditing
                        ? _buildEditableTile(
                            context,
                            _pesoController,
                            "Peso",
                            Icons.monitor_weight_outlined,
                            "kg",
                          )
                        : _buildInfoTile(
                            context,
                            "Peso",
                            "${_userData!.peso?.toStringAsFixed(1) ?? '-'} kg",
                            Icons.monitor_weight_outlined,
                          ),
                    const Divider(indent: 16, endIndent: 16),

                    // Fila de Altura
                    _isEditing
                        ? _buildEditableTile(
                            context,
                            _alturaController,
                            "Altura",
                            Icons.height,
                            "cm",
                          )
                        : _buildInfoTile(
                            context,
                            "Altura",
                            "${_userData!.altura?.toStringAsFixed(0) ?? '-'} cm",
                            Icons.height,
                          ),
                    const Divider(indent: 16, endIndent: 16),

                    // Fila de Objetivo
                    _isEditing
                        ? Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: DropdownButtonFormField<String>(
                              value: _objetivo,
                              decoration: const InputDecoration(
                                labelText: "Objetivo",
                                prefixIcon: Icon(Icons.flag_outlined),
                                border: OutlineInputBorder(),
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
                              onChanged: (value) =>
                                  setState(() => _objetivo = value),
                            ),
                          )
                        : _buildInfoTile(
                            context,
                            "Objetivo",
                            _userData!.objetivo ?? '-',
                            Icons.flag_outlined,
                          ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // ⚙️ OPCIONES ADICIONALES (Cerrar sesión)
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
                  if (mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      "/login",
                      (route) => false,
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),

      // 📝 BOTÓN FLOTANTE (EDITAR / GUARDAR)
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
