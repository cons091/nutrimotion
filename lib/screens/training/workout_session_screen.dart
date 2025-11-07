import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nutrimotion/models/workout_model.dart';

class WorkoutSessionScreen extends StatefulWidget {
  final Workout? initialWorkout;
  final bool startAutomatically;

  const WorkoutSessionScreen({
    super.key,
    this.initialWorkout,
    this.startAutomatically = false,
  });

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen> {
  late Workout workout;
  bool isRunning = false;
  Duration elapsed = Duration.zero;
  Timer? timer;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    // Si no hay rutina, se crea una vacía
    workout =
        widget.initialWorkout ??
        Workout(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: "Entrenamiento nuevo",
          day: DateTime.now().toString(),
          exercises: [],
        );

    if (widget.startAutomatically) {
      _startTimer();
    }
  }

  void _startTimer() {
    if (isRunning) return;
    setState(() => isRunning = true);
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => elapsed += const Duration(seconds: 1));
    });
  }

  void _stopTimer() {
    timer?.cancel();
    setState(() => isRunning = false);
  }

  void _addExercise() {
    TextEditingController nameCtrl = TextEditingController();
    TextEditingController repsCtrl = TextEditingController();
    TextEditingController weightCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Agregar ejercicio"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Nombre"),
            ),
            TextField(
              controller: repsCtrl,
              decoration: const InputDecoration(labelText: "Repeticiones"),
            ),
            TextField(
              controller: weightCtrl,
              decoration: const InputDecoration(labelText: "Peso (kg)"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                workout.exercises.add(
                  Exercise(
                    name: nameCtrl.text,
                    series: [
                      SeriesEntry(
                        reps: int.tryParse(repsCtrl.text) ?? 0,
                        weight: double.tryParse(weightCtrl.text),
                      ),
                    ],
                  ),
                );
              });
              Navigator.pop(context);
            },
            child: const Text("Agregar"),
          ),
        ],
      ),
    );
  }

  Future<void> _saveWorkoutToFirestore() async {
    try {
      final workoutData = {
        'id': workout.id,
        'title': workout.title,
        'date': DateTime.now(),
        'duration_seconds': elapsed.inSeconds,
        'exercises': workout.exercises.map((ex) {
          return {
            'name': ex.name,
            'series': ex.series.map((s) => s.toMap()).toList(),
          };
        }).toList(),
      };

      await _db.collection('training_history').doc(workout.id).set(workoutData);
    } catch (e) {
      debugPrint("Error al guardar entrenamiento: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error al guardar: $e")));
    }
  }

  Future<void> _finishWorkout() async {
    _stopTimer();
    await _saveWorkoutToFirestore();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Entrenamiento guardado y finalizado 💪")),
    );
    Navigator.pop(context, workout);
  }

  String _formatTime(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(workout.title)),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Text(
            _formatTime(elapsed),
            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: workout.exercises.isEmpty
                ? const Center(
                    child: Text(
                      "No hay ejercicios aún.\nPresiona el botón para añadir uno.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: workout.exercises.length,
                    itemBuilder: (context, index) {
                      final ex = workout.exercises[index];
                      return Card(
                        margin: const EdgeInsets.all(8),
                        child: ListTile(
                          title: Text(ex.name),
                          subtitle: Text(
                            ex.series.isNotEmpty
                                ? "${ex.series.length} serie(s) - ${ex.series[0].reps} reps"
                                : "Sin series",
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() => workout.exercises.removeAt(index));
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _addExercise,
                    icon: const Icon(Icons.add),
                    label: const Text("Agregar ejercicio"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _finishWorkout,
                    icon: const Icon(Icons.check),
                    label: const Text("Finalizar entrenamiento"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
