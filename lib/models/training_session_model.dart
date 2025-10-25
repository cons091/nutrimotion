import 'package:cloud_firestore/cloud_firestore.dart';
import 'workout_model.dart';

class TrainingSession {
  final String id;
  final String userId;
  final DateTime date;
  final Duration duration;
  final List<Exercise> exercises;
  final String? workoutTemplateId; // si viene de una rutina guardada
  final String? notes;

  TrainingSession({
    required this.id,
    required this.userId,
    required this.date,
    required this.duration,
    required this.exercises,
    this.workoutTemplateId,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'duration': duration.inSeconds,
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'workoutTemplateId': workoutTemplateId,
      'notes': notes,
    };
  }

  static TrainingSession fromMap(String id, Map<String, dynamic> map) {
    return TrainingSession(
      id: id,
      userId: map['userId'],
      date: (map['date'] as Timestamp).toDate(),
      duration: Duration(seconds: map['duration'] ?? 0),
      exercises: (map['exercises'] as List<dynamic>)
          .map((e) => Exercise.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      workoutTemplateId: map['workoutTemplateId'],
      notes: map['notes'],
    );
  }
}
