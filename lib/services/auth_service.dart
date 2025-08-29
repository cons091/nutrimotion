import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Registro
  Future<User?> registerUser({
    required String email,
    required String password,
    required double peso,
    required double altura,
    required String objetivo,
  }) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = cred.user;

      if (user != null) {
        AppUser appUser = AppUser(
          uid: user.uid,
          email: user.email!,
          peso: peso,
          altura: altura,
          objetivo: objetivo,
        );

        await _db.collection("users").doc(user.uid).set(appUser.toMap());
      }

      return user;
    } catch (e) {
      print("Error en register: $e");
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
