import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nutrimotion/models/workout_model.dart';
import 'package:nutrimotion/services/workout_service.dart';
import 'package:nutrimotion/screens/training/exercise_picker_screen.dart';
import 'package:nutrimotion/utils/exercise_list.dart';
import 'package:nutrimotion/widgets/series_config_dialog.dart';

class WorkoutFormScreen extends StatefulWidget {
  final Workout? existingWorkout;

  const WorkoutFormScreen({super.key, this.existingWorkout});

  @override
  State<WorkoutFormScreen> createState() => _WorkoutFormScreenState();
}

class _WorkoutFormScreenState extends State<WorkoutFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;

  List<Exercise> _exercises = [];
  String _selectedDay = "Piernas";

  @override
  void initState() {
    super.initState();
    if (widget.existingWorkout != null) {
      _titleController = TextEditingController(
        text: widget.existingWorkout!.title,
      );
      // Si la rutina guardada tiene un grupo antiguo que ya no existe en la
      // lista canónica, caemos al primero para no romper el dropdown.
      _selectedDay = ExerciseList.groups.contains(widget.existingWorkout!.day)
          ? widget.existingWorkout!.day
          : ExerciseList.groups.first;
      _exercises = List.from(widget.existingWorkout!.exercises);
    } else {
      _titleController = TextEditingController();
      _exercises = [];
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _addExercise() async {
    final exerciseName = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExercisePickerScreen(group: _selectedDay),
      ),
    );

    if (exerciseName == null || !mounted) return;

    // El diálogo gestiona (y libera) sus propios controllers; con
    // requireWeight exige reps y peso > 0, como validaba antes esta pantalla.
    final series = await showDialog<List<SeriesEntry>>(
      context: context,
      builder: (_) =>
          SeriesConfigDialog(exerciseName: exerciseName, requireWeight: true),
    );

    if (series == null || !mounted) return;

    setState(() {
      _exercises.add(Exercise(name: exerciseName, series: series));
    });
  }

  void _saveWorkout() {
    if (!_formKey.currentState!.validate()) return;

    // ✅ Validar que no haya valores 0 en los ejercicios existentes
    for (final ex in _exercises) {
      for (final s in ex.series) {
        if (s.reps <= 0 || (s.weight ?? 0) <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("❌ '${ex.name}' tiene valores 0 en sus series."),
            ),
          );
          return;
        }
      }
    }

    final workout = Workout(
      id:
          widget.existingWorkout?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text,
      day: _selectedDay,
      exercises: _exercises,
    );

    final userId = FirebaseAuth.instance.currentUser!.uid;
    final workoutService = WorkoutService();

    if (widget.existingWorkout != null) {
      workoutService.updateWorkout(userId, workout);
    } else {
      workoutService.addWorkout(userId, workout);
    }

    Navigator.pop(context, workout);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingWorkout != null ? "Editar Rutina" : "Nueva Rutina",
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: "Nombre de la Rutina",
                ),
                validator: (value) => value!.isEmpty ? "Campo requerido" : null,
              ),
              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                initialValue: _selectedDay,
                decoration: const InputDecoration(
                  labelText: "Día / Grupo muscular",
                  prefixIcon: Icon(Icons.fitness_center),
                ),
                items: ExerciseList.groups
                    .map(
                      (g) => DropdownMenuItem(
                        value: g,
                        child: Text(ExerciseList.labelFor(g)),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _selectedDay = value!),
              ),
              const SizedBox(height: 20),

              Expanded(
                child: ListView.builder(
                  itemCount: _exercises.length,
                  itemBuilder: (context, index) {
                    final ex = _exercises[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  ex.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _exercises.removeAt(index);
                                    });
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            Column(
                              children: ex.series.asMap().entries.map((entry) {
                                final i = entry.key;
                                final s = entry.value;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      Text("Serie ${i + 1}: "),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextFormField(
                                          initialValue: s.reps.toString(),
                                          decoration: const InputDecoration(
                                            labelText: "Reps",
                                            border: OutlineInputBorder(),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                          ),
                                          keyboardType: TextInputType.number,
                                          onChanged: (value) {
                                            final parsed =
                                                int.tryParse(value) ?? 0;
                                            setState(() {
                                              ex.series[i] = SeriesEntry(
                                                reps: parsed,
                                                weight: s.weight,
                                              );
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextFormField(
                                          initialValue:
                                              s.weight?.toString() ?? '',
                                          decoration: const InputDecoration(
                                            labelText: "Peso (kg)",
                                            border: OutlineInputBorder(),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                          ),
                                          keyboardType: TextInputType.number,
                                          onChanged: (value) {
                                            final parsed =
                                                double.tryParse(value) ?? 0;
                                            setState(() {
                                              ex.series[i] = SeriesEntry(
                                                reps: s.reps,
                                                weight: parsed,
                                              );
                                            });
                                          },
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            ex.series.removeAt(i);
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),

                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    ex.series.add(
                                      SeriesEntry(reps: 0, weight: 0),
                                    );
                                  });
                                },
                                icon: const Icon(Icons.add),
                                label: const Text("Añadir serie"),
                              ),
                            ),
                          ],
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
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _saveWorkout,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text(
                  widget.existingWorkout != null
                      ? "Actualizar rutina"
                      : "Guardar rutina",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
