import 'package:flutter/material.dart';
import 'package:nutrimotion/models/workout_model.dart';
import 'package:nutrimotion/screens/training/workout_form_screen.dart';

class WorkoutDetailScreen extends StatelessWidget {
  final Workout workout;
  const WorkoutDetailScreen({super.key, required this.workout});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(workout.title)),
      body: ListView.builder(
        itemCount: workout.exercises.length,
        itemBuilder: (context, index) {
          final ex = workout.exercises[index];
          return Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ex.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Table(
                    border: TableBorder.all(color: Colors.grey.shade300),
                    children: [
                      const TableRow(
                        decoration: BoxDecoration(color: Color(0xFFEFEFEF)),
                        children: [
                          Padding(
                            padding: EdgeInsets.all(6),
                            child: Text(
                              "Serie",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(6),
                            child: Text(
                              "Reps",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(6),
                            child: Text(
                              "Peso (kg)",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      ...ex.series.asMap().entries.map((entry) {
                        final i = entry.key + 1;
                        final s = entry.value;
                        return TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(6),
                              child: Text("$i"),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(6),
                              child: Text("${s.reps}"),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(6),
                              child: Text("${s.weight ?? 0}"),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final updatedWorkout = await Navigator.push<Workout>(
            context,
            MaterialPageRoute(
              builder: (_) => WorkoutFormScreen(existingWorkout: workout),
            ),
          );
          if (updatedWorkout != null) {
            Navigator.pop(context, updatedWorkout);
          }
        },
        label: const Text("Editar rutina"),
        icon: const Icon(Icons.edit),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
