class Exercise {
  final String name;
  final int sets;
  final int reps;
  final double? weight;

  Exercise({
    required this.name,
    required this.sets,
    required this.reps,
    this.weight,
  });

  Map<String, dynamic> toMap() {
    return {"name": name, "sets": sets, "reps": reps, "weight": weight};
  }

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      name: map["name"],
      sets: map["sets"],
      reps: map["reps"],
      weight: map["weight"]?.toDouble(),
    );
  }
}

class Workout {
  final String id;
  final String title;
  final List<Exercise> exercises;

  Workout({required this.id, required this.title, required this.exercises});

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "title": title,
      "exercises": exercises.map((e) => e.toMap()).toList(),
    };
  }

  factory Workout.fromMap(Map<String, dynamic> map) {
    return Workout(
      id: map["id"],
      title: map["title"],
      exercises: List<Exercise>.from(
        map["exercises"].map((e) => Exercise.fromMap(e)),
      ),
    );
  }
}
