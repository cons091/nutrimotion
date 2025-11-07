import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:nutrimotion/models/user_model.dart';

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

  Future<void> _loadUserData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(currentUser.uid)
        .get();

    if (doc.exists) {
      final data = doc.data(); // obtiene Map<String, dynamic>?
      setState(() {
        _userData = AppUser.fromMap(data!);
        _pesoController.text = _userData?.peso?.toString() ?? '';
        _alturaController.text = _userData?.altura?.toString() ?? '';
        _objetivo = _userData?.objetivo ?? "Mantenimiento";

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

    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(currentUser.uid)
          .update({
            "peso": double.tryParse(_pesoController.text),
            "altura": double.tryParse(_alturaController.text),
            "objetivo": _objetivo,
          });

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error al actualizar los datos"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Mi Perfil"),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
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
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // FOTO DE PERFIL
            Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.green[100],
                  backgroundImage: _photoUrl != null
                      ? NetworkImage(_photoUrl!)
                      : null,
                  child: _photoUrl == null
                      ? const Icon(Icons.person, size: 70, color: Colors.white)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 4,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green,
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 3,
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
                        ? DropdownButtonFormField<String>(
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
                                _objetivo = value;
                              });
                            },
                          )
                        : _buildInfoRow(
                            "Objetivo",
                            _userData!.objetivo ?? '-',
                            icon: Icons.flag,
                          ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            if (_isLoading)
              const CircularProgressIndicator(color: Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {IconData? icon}) {
    return Row(
      children: [
        Icon(icon, color: Colors.green),
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
      keyboardType: TextInputType.number,
    );
  }
}
