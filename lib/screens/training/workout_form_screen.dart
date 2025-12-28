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
  String _selectedDay = "Piernas";

  @override
  void initState() {
    super.initState();
    if (widget.existingWorkout != null) {
      _titleController = TextEditingController(
        text: widget.existingWorkout!.title,
      );
      _selectedDay = widget.existingWorkout!.day;
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

    if (exerciseName == null) return;

    List<TextEditingController> repsControllers = [
      TextEditingController(text: '8'),
    ];
    List<TextEditingController> weightControllers = [
      TextEditingController(text: '0'),
    ];

    List<SeriesEntry> tempSeries = [SeriesEntry(reps: 8, weight: 0)];

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text("Configurar $exerciseName"),
              contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Define las repeticiones y el peso para cada serie:",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Column(
                      children: List.generate(tempSeries.length, (i) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Container(
                                alignment: Alignment.center,
                                width: 24,
                                child: Text(
                                  "S${i + 1}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  controller: repsControllers[i],
                                  decoration: const InputDecoration(
                                    labelText: "Reps",
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  controller: weightControllers[i],
                                  decoration: const InputDecoration(
                                    labelText: "Peso (kg)",
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  if (tempSeries.length > 1) {
                                    setStateDialog(() {
                                      repsControllers.removeAt(i);
                                      weightControllers.removeAt(i);
                                      tempSeries.removeAt(i);
                                    });
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Debes tener al menos 1 serie.",
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () {
                          setStateDialog(() {
                            repsControllers.add(
                              TextEditingController(text: '8'),
                            );
                            weightControllers.add(
                              TextEditingController(text: '0'),
                            );
                            tempSeries.add(SeriesEntry(reps: 8, weight: 0));
                          });
                        },
                        icon: const Icon(Icons.add),
                        label: const Text("Añadir serie"),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar"),
                ),
                FilledButton(
                  onPressed: () {
                    final newSeries = <SeriesEntry>[];
                    bool hasInvalidValue = false;
                    for (var i = 0; i < repsControllers.length; i++) {
                      final reps = int.tryParse(repsControllers[i].text) ?? 0;
                      final weight =
                          double.tryParse(weightControllers[i].text) ?? 0;
                      if (reps <= 0 || weight <= 0) {
                        hasInvalidValue = true;
                        break;
                      }
                      newSeries.add(SeriesEntry(reps: reps, weight: weight));
                    }

                    if (hasInvalidValue) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "❌ Las repeticiones y el peso deben ser mayores a 0 en todas las series.",
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                      return;
                    }

                    setState(() {
                      _exercises.add(
                        Exercise(name: exerciseName, series: newSeries),
                      );
                    });
                    for (var c in repsControllers) {
                      c.dispose();
                    }
                    for (var c in weightControllers) {
                      c.dispose();
                    }

                    if (mounted) Navigator.pop(context);
                  },
                  child: const Text("Añadir Ejercicio"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _saveWorkout() {
    if (!_formKey.currentState!.validate()) return;

    if (_exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Debes añadir al menos un ejercicio a la rutina."),
        ),
      );
      return;
    }
    for (final ex in _exercises) {
      for (final s in ex.series) {
        if (s.reps <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "❌ El ejercicio '${ex.name}' tiene series con repeticiones en 0 o menos.",
              ),
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

    if (mounted) {
      Navigator.pop(context, workout);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingWorkout != null ? "Editar Rutina" : "Nueva Rutina",
          style: theme.textTheme.titleLarge!.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.colorScheme.surfaceContainer,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: "Nombre de la Rutina",
                        hintText: "Ej. Pecho y Tríceps Avanzado",
                        prefixIcon: Icon(Icons.label_important_outline_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? "El nombre es requerido" : null,
                    ),
                    const SizedBox(height: 20),

                    DropdownButtonFormField<String>(
                      initialValue: _selectedDay,
                      decoration: const InputDecoration(
                        labelText: "Día / Grupo muscular",
                        prefixIcon: Icon(Icons.fitness_center_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        contentPadding: EdgeInsets.fromLTRB(12, 18, 12, 18),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: "Piernas",
                          child: Text("Piernas 🦵"),
                        ),
                        DropdownMenuItem(
                          value: "Espalda",
                          child: Text("Espalda 🔄"),
                        ),
                        DropdownMenuItem(
                          value: "Pecho",
                          child: Text("Pecho 💥"),
                        ),
                        DropdownMenuItem(
                          value: "Hombros",
                          child: Text("Hombros ⛰️"),
                        ),
                        DropdownMenuItem(
                          value: "Brazos",
                          child: Text("Brazos 💪"),
                        ),
                        DropdownMenuItem(
                          value: "FullBody",
                          child: Text("Full Body 🤸"),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedDay = value!),
                    ),
                    const SizedBox(height: 30),

                    Text(
                      "Ejercicios de la rutina (${_exercises.length})",
                      style: theme.textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),

                    _exercises.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20.0),
                            child: Center(
                              child: Text(
                                "Toca 'Añadir Ejercicio' para empezar.",
                                style: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _exercises.length,
                            itemBuilder: (context, index) {
                              final ex = _exercises[index];

                              return Dismissible(
                                key: ValueKey(ex.name + index.toString()),
                                direction: DismissDirection.endToStart,
                                onDismissed: (direction) {
                                  setState(() {
                                    _exercises.removeAt(index);
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("'${ex.name}' eliminado."),
                                    ),
                                  );
                                },
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.errorContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.delete_sweep_rounded,
                                    color: theme.colorScheme.error,
                                    size: 30,
                                  ),
                                ),
                                child: Card(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ex.name,
                                          style: theme.textTheme.titleMedium!
                                              .copyWith(
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    theme.colorScheme.primary,
                                              ),
                                        ),
                                        const SizedBox(height: 10),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 4.0,
                                          ),
                                          child: Row(
                                            children: [
                                              const SizedBox(width: 45),
                                              Expanded(
                                                child: Text(
                                                  "REPS",
                                                  style: theme
                                                      .textTheme
                                                      .labelSmall,
                                                ),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  "PESO (kg)",
                                                  style: theme
                                                      .textTheme
                                                      .labelSmall,
                                                ),
                                              ),
                                              const SizedBox(width: 48),
                                            ],
                                          ),
                                        ),
                                        const Divider(height: 1, thickness: 1),
                                        const SizedBox(height: 8),
                                        ...ex.series.asMap().entries.map((
                                          entry,
                                        ) {
                                          final i = entry.key;
                                          final s = entry.value;
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 6,
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 45,
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(
                                                    "S${i + 1}:",
                                                    style: theme
                                                        .textTheme
                                                        .bodyMedium!
                                                        .copyWith(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: TextFormField(
                                                    initialValue: s.reps
                                                        .toString(),
                                                    keyboardType:
                                                        TextInputType.number,
                                                    textAlign: TextAlign.center,
                                                    decoration: const InputDecoration(
                                                      isDense: true,
                                                      contentPadding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 4,
                                                          ),
                                                      border: OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.all(
                                                              Radius.circular(
                                                                8,
                                                              ),
                                                            ),
                                                      ),
                                                    ),
                                                    onChanged: (value) {
                                                      final parsed =
                                                          int.tryParse(value) ??
                                                          0;
                                                      setState(() {
                                                        ex.series[i] =
                                                            SeriesEntry(
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
                                                        s.weight?.toString() ??
                                                        '0',
                                                    keyboardType:
                                                        TextInputType.number,
                                                    textAlign: TextAlign.center,
                                                    decoration: const InputDecoration(
                                                      isDense: true,
                                                      contentPadding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 4,
                                                          ),
                                                      border: OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.all(
                                                              Radius.circular(
                                                                8,
                                                              ),
                                                            ),
                                                      ),
                                                    ),
                                                    onChanged: (value) {
                                                      final parsed =
                                                          double.tryParse(
                                                            value,
                                                          ) ??
                                                          0;
                                                      setState(() {
                                                        ex.series[i] =
                                                            SeriesEntry(
                                                              reps: s.reps,
                                                              weight: parsed,
                                                            );
                                                      });
                                                    },
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.close_rounded,
                                                    color:
                                                        theme.colorScheme.error,
                                                  ),
                                                  onPressed: () {
                                                    if (ex.series.length > 1) {
                                                      setState(() {
                                                        ex.series.removeAt(i);
                                                      });
                                                    } else {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            "Un ejercicio debe tener al menos una serie.",
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  },
                                                ),
                                              ],
                                            ),
                                          );
                                        }),

                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton.icon(
                                            onPressed: () {
                                              setState(() {
                                                ex.series.add(
                                                  SeriesEntry(
                                                    reps: 8,
                                                    weight: 0,
                                                  ),
                                                );
                                              });
                                            },
                                            icon: const Icon(
                                              Icons.add_circle_outline,
                                            ),
                                            label: const Text(
                                              "Añadir otra serie",
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 10.0,
            ),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _addExercise,
                icon: const Icon(Icons.playlist_add_rounded),
                label: const Text("Añadir Ejercicio"),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: theme.colorScheme.primary, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 0, 20.0, 20.0),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: _saveWorkout,
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  widget.existingWorkout != null
                      ? "ACTUALIZAR RUTINA"
                      : "GUARDAR RUTINA",
                  style: theme.textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
