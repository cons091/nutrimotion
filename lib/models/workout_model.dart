class Workout {
  final String id;
  final String title;
  final String day;
  final List<Exercise> exercises;

  Workout({
    required this.id,
    required this.title,
    required this.day,
    required this.exercises,
  });

  /// Convierte a Map para guardar en Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'day': day,
      'exercises': exercises.map((e) => e.toMap()).toList(),
    };
  }

  /// Reconstruye desde Firestore
  factory Workout.fromMap(Map<String, dynamic> map) {
    return Workout(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      day: map['day'] ?? '',
      exercises: map['exercises'] != null
          ? List<Exercise>.from(
              (map['exercises'] as List).map((e) => Exercise.fromMap(e)),
            )
          : [],
    );
  }
}

class Exercise {
  final String name;
  final List<SeriesEntry> series;

  Exercise({required this.name, required this.series});

  Map<String, dynamic> toMap() {
    return {'name': name, 'series': series.map((s) => s.toMap()).toList()};
  }

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      name: map['name'] ?? '',
      series: map['series'] != null
          ? List<SeriesEntry>.from(
              (map['series'] as List).map((s) => SeriesEntry.fromMap(s)),
            )
          : [],
    );
  }
}

class SeriesEntry {
  int reps;
  double? weight;

  SeriesEntry({required this.reps, this.weight});

  Map<String, dynamic> toMap() {
    return {'reps': reps, 'weight': weight};
  }

  factory SeriesEntry.fromMap(Map<String, dynamic> map) {
    return SeriesEntry(
      reps: map['reps'] ?? 0,
      weight: map['weight'] != null ? (map['weight'] as num).toDouble() : null,
    );
  }

  /// Nuevo: para actualizar reps o peso sin crear todo manualmente
  SeriesEntry copyWith({int? reps, double? weight}) {
    return SeriesEntry(reps: reps ?? this.reps, weight: weight ?? this.weight);
  }
}
