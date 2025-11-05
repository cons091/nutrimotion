import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/training_session_model.dart';
import '../models/workout_model.dart';

class TrainingSessionService {
  final _db = FirebaseFirestore.instance;

  /// Guarda la sesión (construye el modelo internamente)
  Future<void> saveSession({
    required String userId,
    required String title,
    required List<Exercise> exercises,
    required Duration duration,
    String? workoutTemplateId,
    String? notes,
  }) async {
    final session = TrainingSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      title: title,
      date: DateTime.now(),
      duration: duration,
      exercises: exercises,
      workoutTemplateId: workoutTemplateId,
      notes: notes,
    );

    await _db
        .collection('users')
        .doc(userId)
        .collection('training_sessions')
        .doc(session.id)
        .set(session.toMap());
  }

  /// Alternativa: agregar una sesión ya construida
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
