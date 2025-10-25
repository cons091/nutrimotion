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

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("Mis Rutinas")),
      body: StreamBuilder<List<Workout>>(
        stream: workoutService.getWorkouts(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final workoutsFromStream = snapshot.data ?? [];

          // Mantener la lista local sincronizada
          if (_workouts.isEmpty ||
              _workouts.length != workoutsFromStream.length) {
            _workouts = workoutsFromStream;
          }

          if (_workouts.isEmpty) {
            return const Center(child: Text("No tienes rutinas aún"));
          }

          return ListView.builder(
            itemCount: _workouts.length,
            itemBuilder: (context, index) {
              final workout = _workouts[index];
              return Card(
                child: ListTile(
                  title: Text(workout.title),
                  subtitle: Text("${workout.exercises.length} ejercicios"),
                  onTap: () async {
                    final updatedWorkout = await Navigator.push<Workout>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WorkoutDetailScreen(workout: workout),
                      ),
                    );

                    if (updatedWorkout != null) {
                      setState(() {
                        _workouts[index] = updatedWorkout;
                      });
                    }
                  },
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.play_arrow, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  WorkoutSessionScreen(workout: workout),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          workoutService.deleteWorkout(userId, workout.id);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () async {
          final newWorkout = await Navigator.push<Workout>(
            context,
            MaterialPageRoute(builder: (_) => const WorkoutFormScreen()),
          );

          if (newWorkout != null) {
            setState(() {
              _workouts.add(newWorkout);
            });
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
