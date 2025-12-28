import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nutrimotion/models/workout_model.dart';
import 'package:nutrimotion/services/workout_service.dart';
import 'package:nutrimotion/screens/training/workout_form_screen.dart';
import 'package:nutrimotion/screens/training/workout_detail_screen.dart';
import 'package:nutrimotion/screens/training/workout_session_screen.dart';

class WorkoutListScreen extends StatefulWidget {
  const WorkoutListScreen({super.key});

  @override
  State<WorkoutListScreen> createState() => _WorkoutListScreenState();
}

class _WorkoutListScreenState extends State<WorkoutListScreen> {
  final workoutService = WorkoutService();
  List<Workout> _workouts = [];

  Future<void> _confirmAndDelete(String userId, Workout workout) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Eliminar rutina"),
        content: Text(
          "¿Estás seguro de que quieres eliminar la rutina '${workout.title}'? Esta acción no se puede deshacer.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancelar"),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade100),
            child: Text(
              "Eliminar",
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await workoutService.deleteWorkout(userId, workout.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Rutina '${workout.title}' eliminada.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tus Entrenamientos 💪"),
        backgroundColor: theme.colorScheme.surfaceContainer,
      ),
      body: StreamBuilder<List<Workout>>(
        stream: workoutService.getWorkouts(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final workoutsFromStream = snapshot.data ?? [];

          if (_workouts.isEmpty ||
              _workouts.length != workoutsFromStream.length) {
            _workouts = workoutsFromStream;
          }

          if (_workouts.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.list_alt,
                      size: 80,
                      color: theme.colorScheme.outline.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "No tienes rutinas guardadas.",
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Crea una nueva rutina o empieza un entrenamiento vacío.",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12.0),
            itemCount: _workouts.length,
            itemBuilder: (context, index) {
              final workout = _workouts[index];

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Icon(
                            Icons.fitness_center,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        title: Text(
                          workout.title,
                          style: theme.textTheme.titleMedium!.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          "${workout.exercises.length} ${workout.exercises.length == 1 ? 'ejercicio' : 'ejercicios'}",
                          style: theme.textTheme.bodyMedium,
                        ),
                        onTap: () async {
                          final updatedWorkout = await Navigator.push<Workout>(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  WorkoutDetailScreen(workout: workout),
                            ),
                          );

                          if (updatedWorkout != null) {
                            setState(() {
                              _workouts[index] = updatedWorkout;
                            });
                          }
                        },
                        trailing: IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: theme.colorScheme.error,
                          ),
                          onPressed: () => _confirmAndDelete(userId, workout),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => WorkoutSessionScreen(
                                    initialWorkout: workout,
                                    startAutomatically: true,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: const Text("COMENZAR RUTINA"),
                            style: FilledButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: "fab1",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const WorkoutSessionScreen(startAutomatically: true),
                ),
              );
            },
            tooltip: "Comenzar un entrenamiento sin plantilla",
            child: const Icon(Icons.timer_outlined),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: "fab2",
            onPressed: () async {
              final newWorkout = await Navigator.push<Workout>(
                context,
                MaterialPageRoute(builder: (_) => const WorkoutFormScreen()),
              );
              if (newWorkout != null &&
                  !_workouts.any((w) => w.id == newWorkout.id)) {
                setState(() {
                  _workouts.add(newWorkout);
                });
              }
            },
            icon: const Icon(Icons.add_box_rounded),
            label: const Text("Nueva Rutina"),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
          ),
        ],
      ),
    );
  }
}
