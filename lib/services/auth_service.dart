import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

/// Excepción de autenticación con mensaje listo para mostrar en la UI.
///
/// Sustituye al patrón anterior de "devolver null ante cualquier error",
/// que no permitía distinguir credenciales incorrectas de un fallo de red.
class AuthException implements Exception {
  final String message;

  /// Código original de FirebaseAuth (útil para depurar), si existe.
  final String? code;

  AuthException(this.message, {this.code});

  @override
  String toString() => message;
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Traduce códigos de FirebaseAuth a mensajes en español para el usuario.
  /// Estática y pura para poder testearla sin Firebase.
  static String messageForCode(String code) {
    switch (code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Correo o contraseña incorrectos';
      case 'invalid-email':
        return 'El correo no es válido';
      case 'user-disabled':
        return 'Esta cuenta está deshabilitada';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con este correo';
      case 'weak-password':
        return 'La contraseña es demasiado débil (mínimo 6 caracteres)';
      case 'network-request-failed':
        return 'Sin conexión. Revisa tu internet e intenta de nuevo';
      case 'too-many-requests':
        return 'Demasiados intentos. Espera un momento e intenta de nuevo';
      default:
        return 'Error de autenticación ($code)';
    }
  }

  /// Registra al usuario en FirebaseAuth y crea su documento de perfil.
  ///
  /// Lanza [AuthException] con mensaje legible si algo falla. Si el perfil
  /// no se puede guardar en Firestore, se elimina la cuenta recién creada
  /// (rollback) para no dejar usuarios sin documento de perfil.
  Future<AppUser> registerUser({
    required String email,
    required String password,
    required double peso,
    required double altura,
    required int edad,
    required String sexo,
    required String actividad,
    required String objetivo,
  }) async {
    final UserCredential credential;
    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(messageForCode(e.code), code: e.code);
    }

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

    try {
      await _db.collection("users").doc(user.uid).set(user.toMap());
    } catch (e) {
      debugPrint('Error guardando perfil, haciendo rollback: $e');
      // Rollback: sin documento de perfil la cuenta quedaría en estado roto.
      try {
        await credential.user?.delete();
      } catch (deleteError) {
        debugPrint('No se pudo hacer rollback del usuario: $deleteError');
      }
      throw AuthException(
        'No se pudo guardar tu perfil. Intenta registrarte de nuevo',
      );
    }

    return user;
  }

  /// 🔑 Login con email y password.
  ///
  /// Lanza [AuthException] con mensaje legible si las credenciales son
  /// incorrectas o hay un problema de red.
  Future<User> loginUser(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return cred.user!;
    } on FirebaseAuthException catch (e) {
      throw AuthException(messageForCode(e.code), code: e.code);
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Stream de sesión activa
  Stream<User?> get userChanges => _auth.authStateChanges();
}
