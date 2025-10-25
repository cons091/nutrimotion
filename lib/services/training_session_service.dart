import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/training_session_model.dart';

class TrainingSessionService {
  final _db = FirebaseFirestore.instance;

  Future<void> addSession(TrainingSession session) async {
    await _db
        .collection('users')
        .doc(session.userId)
        .collection('training_sessions')
        .doc(session.id)
        .set(session.toMap());
  }

  Stream<List<TrainingSession>> getSessions(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('training_sessions')
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TrainingSession.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }
}
