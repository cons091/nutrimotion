import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nutrimotion/models/workout_model.dart';

class WorkoutSessionScreen extends StatefulWidget {
  final Workout workout;
  final bool isReviewMode; // para diferenciar entre ver rutina o entrenar

  const WorkoutSessionScreen({
    super.key,
    required this.workout,
    this.isReviewMode = false,
  });

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen> {
  late Workout _sessionWorkout;
  Timer? _timer;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();

    // Copia de la rutina para no modificar la original
    _sessionWorkout = Workout(
      id: widget.workout.id,
      title: widget.workout.title,
      day: widget.workout.day,
      exercises: widget.workout.exercises
          .map(
            (ex) => Exercise(
              name: ex.name,
              series: ex.series
                  .map((s) => SeriesEntry(reps: s.reps, weight: s.weight))
                  .toList(),
            ),
          )
          .toList(),
    );

    // ✅ Si no es modo revisión, iniciar cronómetro automáticamente
    if (!widget.isReviewMode) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _elapsedSeconds++;
        });
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _finishSession() {
    _timer?.cancel(); // detener cronómetro
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Entrenamiento completado 💪"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Has completado ${_sessionWorkout.exercises.length} ejercicios.",
            ),
            const SizedBox(height: 8),
            Text("Tiempo total: ${_formatTime(_elapsedSeconds)}"),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // cerrar diálogo
              Navigator.pop(context); // volver a la pantalla principal
            },
            child: const Text("Cerrar"),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Entrenando: ${_sessionWorkout.title}"),
        actions: [
          if (!widget.isReviewMode)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  const Icon(Icons.access_time, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(_elapsedSeconds),
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: _sessionWorkout.exercises.map((exercise) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...exercise.series.asMap().entries.map((entry) {
                      final seriesIndex = entry.key;
                      final series = entry.value;
                      return Row(
                        children: [
                          Text("Serie ${seriesIndex + 1}: "),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              initialValue: series.reps.toString(),
                              decoration: const InputDecoration(
                                labelText: "Reps",
                              ),
                              keyboardType: TextInputType.number,
                              readOnly: widget.isReviewMode,
                              onChanged: (value) {
                                if (!widget.isReviewMode) {
                                  setState(() {
                                    series.reps =
                                        int.tryParse(value) ?? series.reps;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              initialValue: series.weight?.toString() ?? '',
                              decoration: const InputDecoration(
                                labelText: "Peso (kg)",
                              ),
                              keyboardType: TextInputType.number,
                              readOnly: widget.isReviewMode,
                              onChanged: (value) {
                                if (!widget.isReviewMode) {
                                  setState(() {
                                    series.weight =
                                        double.tryParse(value) ?? series.weight;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
      bottomNavigationBar: widget.isReviewMode
          ? null
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: ElevatedButton.icon(
                onPressed: _finishSession,
                icon: const Icon(Icons.stop),
                label: const Text("Finalizar entrenamiento"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ),
    );
  }
}
