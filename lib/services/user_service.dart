import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutrimotion/models/user_model.dart';

class UserService {
  final _db = FirebaseFirestore.instance;

  Stream<AppUser> getUserData(String userId) {
    return _db.collection('users').doc(userId).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return AppUser(uid: userId, email: '');
      }
      final data = snapshot.data()!;
      data['uid'] = userId;
      return AppUser.fromMap(data);
    });
  }

  Future<void> updateUserData(String userId, Map<String, dynamic> data) async {
    await _db.collection('users').doc(userId).update(data);
  }
}
