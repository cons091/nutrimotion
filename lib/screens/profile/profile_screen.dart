import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:nutrimotion/models/user_model.dart';
import 'package:nutrimotion/services/auth_service.dart';
import 'package:nutrimotion/utils/validators.dart';
import 'package:nutrimotion/utils/user_options.dart';

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
  String? _sexo;
  String? _actividad;
  String? _objetivo;
  String? _photoUrl;

  final picker = ImagePicker();
  final _authService = AuthService();

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

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(currentUser.uid)
        .get();

    if (!mounted) return;
    if (doc.exists) {
      final data = doc.data(); // obtiene Map<String, dynamic>?
      setState(() {
        _userData = AppUser.fromMap(data!);
        _pesoController.text = _userData?.peso?.toString() ?? '';
        _alturaController.text = _userData?.altura?.toString() ?? '';
        _edadController.text = _userData?.edad?.toString() ?? '';

        // validOrNull evita que un valor antiguo/desconocido en Firestore
        // rompa los dropdowns (su initialValue debe existir en los items).
        _sexo = UserOptions.validOrNull(_userData?.sexo, UserOptions.sexos);
        _actividad = UserOptions.validOrNull(
          _userData?.actividad,
          UserOptions.actividades.keys,
        );
        _objetivo =
            UserOptions.validOrNull(
              _userData?.objetivo,
              UserOptions.objetivos.keys,
            ) ??
            "Mantenimiento";

        // Acceso seguro a photoUrl
        if (data.containsKey("photoUrl")) {
          _photoUrl = data["photoUrl"];
        } else {
          _photoUrl = null;
        }
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() => _isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final storageRef = FirebaseStorage.instance.ref().child(
        'profile_photos/${currentUser!.uid}.jpg',
      );

      await storageRef.putFile(File(pickedFile.path));
      final downloadUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance
          .collection("users")
          .doc(currentUser.uid)
          .update({"photoUrl": downloadUrl});

      if (!mounted) return;
      setState(() {
        _photoUrl = downloadUrl;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Foto actualizada 📸"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error al subir la foto"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveChanges() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Validar antes de guardar: antes un texto inválido guardaba null y
    // borraba el dato bueno que ya existía en Firestore.
    final error =
        Validators.peso(_pesoController.text) ??
        Validators.altura(_alturaController.text) ??
        Validators.edad(_edadController.text);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(currentUser.uid)
          .update({
            "peso": Validators.parseDouble(_pesoController.text),
            "altura": Validators.parseDouble(_alturaController.text),
            "edad": Validators.parseInt(_edadController.text),
            "sexo": _sexo,
            "actividad": _actividad,
            "objetivo": _objetivo,
          });

      if (!mounted) return;
      setState(() {
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Datos actualizados correctamente ✅"),
          backgroundColor: Colors.green,
        ),
      );

      _loadUserData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error al actualizar los datos"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cerrar sesión"),
        content: const Text("¿Seguro que quieres cerrar sesión?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Cerrar sesión"),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    await _authService.signOut();
    if (!mounted) return;

    // Limpia todo el stack de navegación: no debe poder volverse atrás
    // a pantallas con datos del usuario anterior.
    Navigator.of(context).pushNamedAndRemoveUntil("/login", (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    if (_userData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mi Perfil"),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            tooltip: _isEditing ? "Guardar cambios" : "Editar perfil",
            onPressed: () {
              if (_isEditing) {
                _saveChanges();
              } else {
                setState(() {
                  _isEditing = true;
                });
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Cerrar sesión",
            onPressed: _signOut,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // FOTO DE PERFIL
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2.5,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 56,
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    backgroundImage: _photoUrl != null
                        ? NetworkImage(_photoUrl!)
                        : null,
                    child: _photoUrl == null
                        ? Icon(
                            Icons.person,
                            size: 64,
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                          )
                        : null,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 4,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      padding: const EdgeInsets.all(6),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            // TARJETA DE INFORMACIÓN
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildInfoRow(
                      "Correo",
                      _userData!.email,
                      icon: Icons.email_outlined,
                    ),
                    const Divider(),
                    _isEditing
                        ? _buildEditableField(
                            controller: _pesoController,
                            label: "Peso (kg)",
                            icon: Icons.fitness_center,
                          )
                        : _buildInfoRow(
                            "Peso",
                            "${_userData!.peso ?? '-'} kg",
                            icon: Icons.fitness_center,
                          ),
                    const Divider(),
                    _isEditing
                        ? _buildEditableField(
                            controller: _alturaController,
                            label: "Altura (cm)",
                            icon: Icons.height,
                          )
                        : _buildInfoRow(
                            "Altura",
                            "${_userData!.altura ?? '-'} cm",
                            icon: Icons.height,
                          ),
                    const Divider(),
                    _isEditing
                        ? _buildEditableField(
                            controller: _edadController,
                            label: "Edad",
                            icon: Icons.cake,
                          )
                        : _buildInfoRow(
                            "Edad",
                            "${_userData!.edad ?? '-'} años",
                            icon: Icons.cake,
                          ),
                    const Divider(),
                    _isEditing
                        ? DropdownButtonFormField<String>(
                            initialValue: _sexo,
                            decoration: const InputDecoration(
                              labelText: "Sexo",
                              prefixIcon: Icon(Icons.person),
                            ),
                            items: UserOptions.sexoItems(),
                            onChanged: (value) {
                              setState(() => _sexo = value);
                            },
                          )
                        : _buildInfoRow(
                            "Sexo",
                            _userData!.sexo ?? '-',
                            icon: Icons.person,
                          ),
                    const Divider(),
                    _isEditing
                        ? DropdownButtonFormField<String>(
                            initialValue: _actividad,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: "Nivel de actividad",
                              prefixIcon: Icon(Icons.directions_run),
                            ),
                            items: UserOptions.items(UserOptions.actividades),
                            onChanged: (value) {
                              setState(() => _actividad = value);
                            },
                          )
                        : _buildInfoRow(
                            "Actividad",
                            UserOptions.actividades[_userData!.actividad] ??
                                _userData!.actividad ??
                                '-',
                            icon: Icons.directions_run,
                          ),
                    const Divider(),
                    _isEditing
                        ? DropdownButtonFormField<String>(
                            initialValue: _objetivo,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: "Objetivo",
                              prefixIcon: Icon(Icons.flag),
                            ),
                            items: UserOptions.items(UserOptions.objetivos),
                            onChanged: (value) {
                              setState(() => _objetivo = value);
                            },
                          )
                        : _buildInfoRow(
                            "Objetivo",
                            UserOptions.objetivos[_userData!.objetivo] ??
                                _userData!.objetivo ??
                                '-',
                            icon: Icons.flag,
                          ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            if (_isLoading) const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {IconData? icon}) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 10),
        Text("$label:", style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildEditableField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
    );
  }
}
