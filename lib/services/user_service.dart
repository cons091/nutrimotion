import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutrimotion/models/user_model.dart';

class UserService {
  final _db = FirebaseFirestore.instance;

  /// Obtiene un stream de los datos del usuario AppUser.
  Stream<AppUser> getUserData(String userId) {
    return _db.collection('users').doc(userId).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        // Devuelve un AppUser básico si no existe, o maneja el error
        return AppUser(uid: userId, email: '');
      }
      // Combina el UID con los datos para construir el modelo
      final data = snapshot.data()!;
      data['uid'] = userId;
      return AppUser.fromMap(data);
    });
  }

  /// Opcional: Actualiza un campo específico del usuario.
  Future<void> updateUserData(String userId, Map<String, dynamic> data) async {
    await _db.collection('users').doc(userId).update(data);
  }
}
