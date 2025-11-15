// lib/screens/training/group_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:nutrimotion/screens/training/exercise_picker_screen.dart';
import 'package:nutrimotion/utils/exercise_list.dart';

// 🚀 FUNCIÓN MOVÍDA A NIVEL GLOBAL (TOP-LEVEL)
IconData _getDayIcon(String day) {
  switch (day) {
    case "Piernas":
      return Icons.airline_seat_legroom_extra_rounded;
    case "Espalda":
      return Icons.back_hand_rounded;
    case "Pecho":
      return Icons.man_rounded;
    case "Hombros":
      return Icons.accessibility_new_rounded;
    case "Brazos":
      return Icons.fitness_center_rounded;
    case "FullBody":
      return Icons.run_circle_rounded;
    default:
      return Icons.calendar_month;
  }
}

class GroupSelectionScreen extends StatelessWidget {
  const GroupSelectionScreen({super.key});

  // ❌ Ya no está aquí: IconData _getDayIcon(String day) { ... }

  @override
  Widget build(BuildContext context) {
    final groups = ExerciseList.exercisesByGroup.keys.toList();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Seleccionar Grupo Muscular"),
        backgroundColor: theme.colorScheme.surfaceContainerHigh,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final group = groups[index];

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            elevation: 2,
            child: ListTile(
              leading: Icon(
                _getDayIcon(group), // 🎯 Ahora la función es accesible
                color: theme.colorScheme.primary,
              ),
              title: Text(group, style: theme.textTheme.titleMedium),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final exerciseName = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ExercisePickerScreen(group: group),
                  ),
                );

                if (exerciseName != null) {
                  Navigator.pop(context, exerciseName);
                }
              },
            ),
          );
        },
      ),
    );
  }
}
