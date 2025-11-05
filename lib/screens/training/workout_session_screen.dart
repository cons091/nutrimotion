import 'package:flutter/material.dart';
import 'package:nutrimotion/models/workout_model.dart';
import 'package:nutrimotion/screens/training/exercise_picker_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nutrimotion/services/training_session_service.dart';

class WorkoutSessionScreen extends StatefulWidget {
  final Workout? workout;
  const WorkoutSessionScreen({super.key, this.workout});

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen> {
  final _stopwatch = Stopwatch();
  final _trainingService = TrainingSessionService();

  late List<Exercise> _exercises;
  late String _title;

  @override
  void initState() {
    super.initState();
    _exercises = widget.workout?.exercises ?? [];
    _title = widget.workout?.title ?? "Entrenamiento vacío";
    _stopwatch.start();
  }

  @override
  void dispose() {
    _stopwatch.stop();
    super.dispose();
  }

  Future<void> _addExercise() async {
    String selectedGroup = "Piernas";

    // 👇 Paso 1: elegir grupo muscular (como en crear rutina)
    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Selecciona grupo muscular"),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return DropdownButton<String>(
                value: selectedGroup,
                items: const [
                  DropdownMenuItem(value: "Piernas", child: Text("Piernas")),
                  DropdownMenuItem(value: "Espalda", child: Text("Espalda")),
                  DropdownMenuItem(value: "Pecho", child: Text("Pecho")),
                  DropdownMenuItem(value: "Hombros", child: Text("Hombros")),
                  DropdownMenuItem(value: "Brazos", child: Text("Brazos")),
                  DropdownMenuItem(value: "FullBody", child: Text("Full Body")),
                ],
                onChanged: (value) {
                  setStateDialog(() => selectedGroup = value!);
                },
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, selectedGroup),
              child: const Text("Seleccionar"),
            ),
          ],
        );
      },
    ).then((result) async {
      if (result == null) return;

      // 👇 Paso 2: elegir ejercicio (igual que en rutinas normales)
      final exerciseName = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ExercisePickerScreen(group: result)),
      );

      if (exerciseName == null) return;

      // 👇 Paso 3: añadir series y pesos
      List<TextEditingController> repsControllers = [TextEditingController()];
      List<TextEditingController> weightControllers = [TextEditingController()];

      await showDialog(
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
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  setStateDialog(() {
                                    repsControllers.removeAt(i);
                                    weightControllers.removeAt(i);
                                  });
                                },
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
    });
  }

  Future<void> _finishWorkout() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final duration = _stopwatch.elapsed;

    await _trainingService.saveSession(
      userId: userId,
      title: _title,
      exercises: _exercises,
      duration: duration,
    );

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Entrenamiento guardado ✅")));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final elapsed =
        "${_stopwatch.elapsed.inMinutes.toString().padLeft(2, '0')}:${(_stopwatch.elapsed.inSeconds % 60).toString().padLeft(2, '0')}";

    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "⏱ Tiempo: $elapsed",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _exercises.isEmpty
                  ? const Center(
                      child: Text(
                        "Aún no has añadido ejercicios",
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _exercises.length,
                      itemBuilder: (context, index) {
                        final ex = _exercises[index];
                        return Card(
                          child: ListTile(
                            title: Text(ex.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: ex.series
                                  .asMap()
                                  .entries
                                  .map(
                                    (e) => Text(
                                      "Serie ${e.key + 1}: ${e.value.reps} reps - ${e.value.weight ?? 0} kg",
                                    ),
                                  )
                                  .toList(),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() => _exercises.removeAt(index));
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
            ElevatedButton.icon(
              onPressed: _addExercise,
              icon: const Icon(Icons.add),
              label: const Text("Añadir Ejercicio"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _finishWorkout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("Finalizar Entrenamiento"),
            ),
          ],
        ),
      ),
    );
  }
}
