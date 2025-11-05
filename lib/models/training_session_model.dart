import 'package:cloud_firestore/cloud_firestore.dart';
import 'workout_model.dart';

class TrainingSession {
  final String id;
  final String userId;
  final String title;
  final DateTime date;
  final Duration duration; // en memoria como Duration
  final List<Exercise> exercises;
  final String? workoutTemplateId;
  final String? notes;

  TrainingSession({
    required this.id,
    required this.userId,
    required this.title,
    required this.date,
    required this.duration,
    required this.exercises,
    this.workoutTemplateId,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      // Guardamos duration en segundos (int) para fácil query
      'duration': duration.inSeconds,
      'date': Timestamp.fromDate(date),
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'workoutTemplateId': workoutTemplateId,
      'notes': notes,
    };
  }

  static TrainingSession fromMap(String id, Map<String, dynamic> map) {
    return TrainingSession(
      id: id,
      userId: map['userId'] as String,
      title: (map['title'] ?? '') as String,
      date: (map['date'] as Timestamp).toDate(),
      duration: Duration(seconds: (map['duration'] ?? 0) as int),
      exercises: (map['exercises'] as List<dynamic>)
          .map((e) => Exercise.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      workoutTemplateId: map['workoutTemplateId'] as String?,
      notes: map['notes'] as String?,
    );
  }
}
