import 'package:flutter/material.dart';
import 'package:nutrimotion/utils/exercise_list.dart';

class ExercisePickerScreen extends StatelessWidget {
  final String group;
  const ExercisePickerScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    final exercises = ExerciseList.exercisesByGroup[group] ?? [];
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Seleccionar Ejercicio: $group"),
        backgroundColor: theme.colorScheme.surfaceContainerHigh,
      ),
      body: exercises.isEmpty
          ? Center(
              child: Text(
                "No hay ejercicios definidos para ${group.toLowerCase()}.",
                style: theme.textTheme.titleMedium,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: exercises.length,
              itemBuilder: (context, index) {
                final exercise = exercises[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 4,
                  ),
                  elevation: 2,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Icon(
                      Icons.fitness_center_rounded,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(
                      exercise,
                      style: theme.textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(context, exercise);
                    },
                  ),
                );
              },
            ),
    );
  }
}
