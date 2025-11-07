import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Registro
  Future<AppUser?> registerUser({
    required String email,
    required String password,
    required double peso,
    required double altura,
    required int edad,
    required String sexo,
    required String actividad,
    required String objetivo,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = AppUser(
        uid: credential.user!.uid,
        email: email,
        peso: peso,
        altura: altura,
        edad: edad,
        sexo: sexo,
        actividad: actividad,
        objetivo: objetivo,
      );

      await _db.collection("users").doc(user.uid).set(user.toMap());
      return user;
    } catch (e) {
      print("Error al registrar usuario: $e");
      return null;
    }
  }

  // 🔑 Login con email y password
  Future<User?> loginUser(String email, String password) async {
    try {
      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return cred.user;
    } catch (e) {
      print("Error en login: $e");
      return null;
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Stream de sesión activa
  Stream<User?> get userChanges => _auth.authStateChanges();
}
