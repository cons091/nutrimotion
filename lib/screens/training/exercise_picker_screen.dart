import 'package:flutter/material.dart';
import 'package:nutrimotion/utils/exercise_list.dart';

class ExercisePickerScreen extends StatelessWidget {
  final String group;
  const ExercisePickerScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    final exercises = ExerciseList.exercisesByGroup[group] ?? [];

    return Scaffold(
      appBar: AppBar(title: Text("Ejercicios de ${ExerciseList.labelFor(group)}")),
      body: ListView.builder(
        itemCount: exercises.length,
        itemBuilder: (context, index) {
          final exercise = exercises[index];
          return ListTile(
            title: Text(exercise),
            onTap: () {
              Navigator.pop(context, exercise);
            },
          );
        },
      ),
    );
  }
}
