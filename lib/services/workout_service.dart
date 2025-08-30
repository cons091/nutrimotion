import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/workout_model.dart';

class WorkoutService {
  final _db = FirebaseFirestore.instance;

  // Guardar rutina
  Future<void> addWorkout(String userId, Workout workout) async {
    await _db
        .collection("users")
        .doc(userId)
        .collection("workouts")
        .doc(workout.id)
        .set(workout.toMap());
  }

  // Obtener rutinas en tiempo real
  Stream<List<Workout>> getWorkouts(String userId) {
    return _db
        .collection("users")
        .doc(userId)
        .collection("workouts")
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Workout.fromMap(doc.data())).toList(),
        );
  }

  // Eliminar rutina
  Future<void> deleteWorkout(String userId, String workoutId) async {
    await _db
        .collection("users")
        .doc(userId)
        .collection("workouts")
        .doc(workoutId)
        .delete();
  }
}
