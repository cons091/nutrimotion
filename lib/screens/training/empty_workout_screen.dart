import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nutrimotion/models/workout_model.dart';
import 'package:nutrimotion/models/training_session_model.dart';
import 'package:nutrimotion/services/training_session_service.dart';
import 'package:nutrimotion/screens/training/exercise_picker_screen.dart';

class EmptyWorkoutScreen extends StatefulWidget {
  const EmptyWorkoutScreen({super.key});

  @override
  State<EmptyWorkoutScreen> createState() => _EmptyWorkoutScreenState();
}

class _EmptyWorkoutScreenState extends State<EmptyWorkoutScreen> {
  late Stopwatch _stopwatch;
  late final _timerStream = Stream.periodic(const Duration(seconds: 1));
  final List<Exercise> _exercises = [];

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$h:$m:$s";
  }

  void _addExercise() async {
    final selectedGroup = await showDialog<String>(
      context: context,
      builder: (_) {
        String? selected = "Piernas";

        return AlertDialog(
          title: const Text("Selecciona un grupo muscular"),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return DropdownButtonFormField<String>(
                initialValue: selected,
                decoration: const InputDecoration(
                  labelText: "Grupo muscular",
                  prefixIcon: Icon(Icons.fitness_center),
                ),
                items: const [
                  DropdownMenuItem(value: "Piernas", child: Text("Piernas")),
                  DropdownMenuItem(value: "Espalda", child: Text("Espalda")),
                  DropdownMenuItem(value: "Pecho", child: Text("Pecho")),
                  DropdownMenuItem(value: "Hombros", child: Text("Hombros")),
                  DropdownMenuItem(value: "Brazos", child: Text("Brazos")),
                  DropdownMenuItem(value: "FullBody", child: Text("Full Body")),
                ],
                onChanged: (value) => setStateDialog(() => selected = value),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, selected),
              child: const Text("Siguiente"),
            ),
          ],
        );
      },
    );

    if (selectedGroup == null) return;

    final exerciseName = await Navigator.push<String>(
      // ignore: use_build_context_synchronously
      context,
      MaterialPageRoute(
        builder: (_) => ExercisePickerScreen(group: selectedGroup),
      ),
    );

    if (!context.mounted || exerciseName == null) return;

    List<TextEditingController> repsControllers = [TextEditingController()];
    List<TextEditingController> weightControllers = [TextEditingController()];

    showDialog(
      // ignore: use_build_context_synchronously
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text("Configurar $exerciseName"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Series"),
                    Column(
                      children: List.generate(repsControllers.length, (i) {
                        return Row(
                          children: [
                            Text("Serie ${i + 1}: "),
                            Expanded(
                              child: TextField(
                                controller: repsControllers[i],
                                decoration: const InputDecoration(
                                  labelText: "Reps",
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: weightControllers[i],
                                decoration: const InputDecoration(
                                  labelText: "Peso (kg)",
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        setStateDialog(() {
                          repsControllers.add(TextEditingController());
                          weightControllers.add(TextEditingController());
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text("Añadir serie"),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar"),
                ),
                ElevatedButton(
                  onPressed: () {
                    final series = <SeriesEntry>[];
                    for (var i = 0; i < repsControllers.length; i++) {
                      series.add(
                        SeriesEntry(
                          reps: int.tryParse(repsControllers[i].text) ?? 0,
                          weight: double.tryParse(weightControllers[i].text),
                        ),
                      );
                    }

                    setState(() {
                      _exercises.add(
                        Exercise(name: exerciseName, series: series),
                      );
                    });

                    Navigator.pop(context);
                  },
                  child: const Text("Añadir"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _finishWorkout() async {
    _stopwatch.stop();
    final duration = _stopwatch.elapsed;

    final userId = FirebaseAuth.instance.currentUser!.uid;
    final session = TrainingSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      title: "Entrenamiento libre",
      date: DateTime.now(),
      duration: duration,
      exercises: _exercises,
    );

    await TrainingSessionService().addSession(session);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Entrenamiento guardado 🏋️")));

    Navigator.popUntil(context, (r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Entrenamiento vacío")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            StreamBuilder(
              stream: _timerStream,
              builder: (context, snapshot) {
                return Text(
                  _formatDuration(_stopwatch.elapsed),
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            Expanded(
              child: _exercises.isEmpty
                  ? const Center(child: Text("Aún no has agregado ejercicios"))
                  : ListView.builder(
                      itemCount: _exercises.length,
                      itemBuilder: (context, index) {
                        final ex = _exercises[index];
                        return Card(
                          child: ListTile(
                            title: Text(ex.name),
                            subtitle: Text(
                              ex.series
                                  .map(
                                    (s) =>
                                        "${s.reps} reps x ${s.weight ?? 0} kg",
                                  )
                                  .join(" | "),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _addExercise,
              icon: const Icon(Icons.add),
              label: const Text("Añadir ejercicio"),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _finishWorkout,
              icon: const Icon(Icons.flag),
              label: const Text("Finalizar entrenamiento"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
