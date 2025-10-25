import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nutrimotion/models/workout_model.dart';
import 'package:nutrimotion/services/workout_service.dart';
import 'package:nutrimotion/screens/training/exercise_picker_screen.dart';

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
  String _selectedDay = "Piernas"; // 👈 valor por defecto para el dropdown

  @override
  void initState() {
    super.initState();

    if (widget.existingWorkout != null) {
      // Si viene de edición, precargamos datos
      _titleController = TextEditingController(
        text: widget.existingWorkout!.title,
      );
      _selectedDay = widget.existingWorkout!.day;
      _exercises = List.from(widget.existingWorkout!.exercises);
    } else {
      // Nuevo workout
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

    if (exerciseName == null) return;

    List<TextEditingController> repsControllers = [TextEditingController()];
    List<TextEditingController> weightControllers = [TextEditingController()];

    showDialog(
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

  void _saveWorkout() {
    if (_formKey.currentState!.validate()) {
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

      // 👇 Pop y devolver workout actualizado
      Navigator.pop(context, workout);
    }
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

              // Dropdown día/grupo muscular
              DropdownButtonFormField<String>(
                value: _selectedDay,
                decoration: const InputDecoration(
                  labelText: "Día / Grupo muscular",
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
                onChanged: (value) {
                  setState(() {
                    _selectedDay = value!;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Lista de ejercicios añadidos
              // Lista de ejercicios añadidos
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
                            // Nombre del ejercicio y botón eliminar ejercicio
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

                            // Series del ejercicio
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
                                            setState(() {
                                              ex.series[i] = SeriesEntry(
                                                reps:
                                                    int.tryParse(value) ??
                                                    s.reps,
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
                                            setState(() {
                                              ex.series[i] = SeriesEntry(
                                                reps: s.reps,
                                                weight: double.tryParse(value),
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

                            // Botón añadir serie
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

              // Botón añadir ejercicio
              ElevatedButton.icon(
                onPressed: _addExercise,
                icon: const Icon(Icons.add),
                label: const Text("Añadir Ejercicio"),
              ),
              const SizedBox(height: 20),

              // Botón guardar / actualizar
              ElevatedButton(
                onPressed: _saveWorkout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
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
