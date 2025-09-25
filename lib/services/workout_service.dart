import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutrimotion/models/workout_model.dart';

class WorkoutService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Añadir nueva rutina
  Future<void> addWorkout(String userId, Workout workout) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .doc(workout.id)
        .set(workout.toMap());
  }

  /// Actualizar rutina existente
  Future<void> updateWorkout(String userId, Workout workout) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .doc(workout.id)
        .set(workout.toMap(), SetOptions(merge: true));
  }

  /// Eliminar rutina
  Future<void> deleteWorkout(String userId, String workoutId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .doc(workoutId)
        .delete();
  }

  /// Obtener rutinas como stream en tiempo real
  Stream<List<Workout>> getWorkouts(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Workout.fromMap(doc.data())).toList(),
        );
  }
}
