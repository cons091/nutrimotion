import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nutrimotion/models/workout_model.dart';
import 'package:nutrimotion/services/training_session_service.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:intl/intl.dart';
import 'package:nutrimotion/screens/training/group_selection_screen.dart';

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

class SeriesEntryRow extends StatefulWidget {
  final SeriesEntry series;
  final int index;
  final Function(int, double?)? onUpdate;
  final Function() onToggleComplete;

  const SeriesEntryRow({
    super.key,
    required this.series,
    required this.index,
    this.onUpdate,
    required this.onToggleComplete,
  });

  @override
  State<SeriesEntryRow> createState() => _SeriesEntryRowState();
}

class _SeriesEntryRowState extends State<SeriesEntryRow> {
  late TextEditingController _repsController;
  late TextEditingController _weightController;

  @override
  void initState() {
    super.initState();
    _repsController = TextEditingController(
      text: widget.series.reps.toString(),
    );
    final formattedWeight = widget.series.weight != null
        ? NumberFormat('0.##').format(widget.series.weight)
        : "";
    _weightController = TextEditingController(text: formattedWeight);

    _repsController.addListener(_updateReps);
    _weightController.addListener(_updateWeight);
  }

  void _updateReps() {
    final text = _repsController.text;
    if (text.isEmpty) return;

    final parsed = int.tryParse(text);
    if (parsed != null && parsed >= 0) {
      widget.series.reps = parsed;
      widget.onUpdate?.call(parsed, widget.series.weight);
    }
  }

  void _updateWeight() {
    final text = _weightController.text;
    if (text.isEmpty) {
      widget.series.weight = 0;
      widget.onUpdate?.call(widget.series.reps, 0);
      return;
    }

    final parsed = double.tryParse(text);
    if (parsed != null && parsed >= 0) {
      widget.series.weight = parsed;
      widget.onUpdate?.call(widget.series.reps, parsed);
    }
  }

  @override
  void dispose() {
    _repsController.removeListener(_updateReps);
    _weightController.removeListener(_updateWeight);
    _repsController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = widget.series.isCompleted ?? false;
    final theme = Theme.of(context);
    final borderColor = isCompleted
        ? theme.colorScheme.primary
        : theme.colorScheme.outline;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      decoration: BoxDecoration(
        color: isCompleted
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 40,
            child: Text(
              "${widget.index + 1}",
              style: theme.textTheme.titleMedium!.copyWith(
                fontWeight: isCompleted ? FontWeight.bold : FontWeight.w500,
                color: isCompleted
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: TextFormField(
                controller: _repsController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  labelText: "Reps",
                  isDense: true,
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: borderColor),
                  ),
                ),
                style: TextStyle(
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                  color: isCompleted ? theme.colorScheme.outline : null,
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: TextFormField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  labelText: "Peso (kg)",
                  isDense: true,
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: borderColor),
                  ),
                ),
                style: TextStyle(
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                  color: isCompleted ? theme.colorScheme.outline : null,
                ),
              ),
            ),
          ),

          IconButton(
            icon: Icon(
              isCompleted
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 32,
              color: isCompleted
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
            ),
            onPressed: widget.onToggleComplete,
          ),
        ],
      ),
    );
  }
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen> {
  late Workout workout;

  bool isRunning = false;
  Duration elapsed = Duration.zero;
  Timer? timer;

  Timer? restTimer;
  Duration restTime = Duration.zero;
  bool isResting = false;

  late Duration currentRestDuration;

  final _trainingService = TrainingSessionService();

  @override
  void initState() {
    super.initState();
    workout =
        widget.initialWorkout ??
        Workout(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: "Entrenamiento rápido",
          day: DateFormat('EEEE').format(DateTime.now()),
          exercises: [],
        );

    for (var ex in workout.exercises) {
      for (var series in ex.series) {
        series.isCompleted = false;
        series.weight ??= 0;
      }
    }
    currentRestDuration = Duration(
      seconds: widget.initialWorkout?.restTimeSeconds ?? 90,
    );
    if (widget.startAutomatically) _startTimer();
  }

  void _editWorkoutDetails() {
    TextEditingController titleCtrl = TextEditingController(
      text: workout.title,
    );

    final List<int> restOptionsSeconds = [30, 45, 60, 90, 120, 150, 180, 240];
    int tempSelectedRestSeconds = currentRestDuration.inSeconds;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('✏️ Editar Configuración'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setStateInDialog) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                        labelText: "Nombre de la Rutina",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Tiempo de Descanso:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    DropdownButton<int>(
                      isExpanded: true,
                      value: tempSelectedRestSeconds,
                      items: restOptionsSeconds.map((int value) {
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text(
                            _formatRestTime(Duration(seconds: value)),
                          ),
                        );
                      }).toList(),
                      onChanged: (int? newValue) {
                        if (newValue != null) {
                          setStateInDialog(() {
                            tempSelectedRestSeconds = newValue;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Seleccionado: ${_formatRestTime(Duration(seconds: tempSelectedRestSeconds))}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('CANCELAR'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            FilledButton(
              child: const Text('GUARDAR'),
              onPressed: () {
                setState(() {
                  workout = Workout(
                    id: workout.id,
                    title: titleCtrl.text.trim(),
                    day: workout.day,
                    exercises: workout.exercises,
                    restTimeSeconds: tempSelectedRestSeconds,
                  );
                  currentRestDuration = Duration(
                    seconds: tempSelectedRestSeconds,
                  );
                  if (isResting) {
                    _stopRestTimer();
                    _startRestTimer();
                  }
                });
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _startTimer() {
    _stopRestTimer();
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

  void _startRestTimer() {
    _stopTimer();

    setState(() {
      isResting = true;
      restTime = currentRestDuration;
    });

    restTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (restTime.inSeconds > 0) {
        setState(() => restTime -= const Duration(seconds: 1));
      } else {
        _stopRestTimer();
        _startTimer();
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Descanso iniciado: ${_formatRestTime(currentRestDuration)} 🧘",
          ),
          backgroundColor: Theme.of(context).colorScheme.tertiary,
        ),
      );
    }
  }

  void _stopRestTimer() {
    restTimer?.cancel();
    setState(() {
      isResting = false;
      restTime = Duration.zero;
    });
  }

  void _toggleSeriesCompletion(Exercise exercise, int seriesIndex) {
    setState(() {
      final series = exercise.series[seriesIndex];
      series.isCompleted = !(series.isCompleted ?? false);
    });
    if (exercise.series[seriesIndex].isCompleted == true) {
      _startRestTimer();
    }
  }

  void _addExercise() async {
    final exerciseName = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GroupSelectionScreen()),
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
              title: Text("Configurar ${exerciseName as String}"),
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
                  onPressed: () {
                    for (var c in repsControllers) {
                      c.dispose();
                    }
                    for (var c in weightControllers) {
                      c.dispose();
                    }
                    Navigator.pop(context);
                  },
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
                      workout.exercises.add(
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

  Future<void> _saveWorkoutToFirestore() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception("Usuario no autenticado");
      }
      final completedExercises = workout.exercises
          .map((ex) {
            final completedSeries = ex.series
                .where((s) => (s.isCompleted == true && s.reps > 0))
                .toList();

            return Exercise(name: ex.name, series: completedSeries);
          })
          .where((ex) => ex.series.isNotEmpty)
          .toList();

      if (completedExercises.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "No se guardó el entrenamiento. ¡No se completó ninguna serie! 😴",
              ),
            ),
          );
        }
        return;
      }

      await _trainingService.saveSession(
        userId: userId,
        title: workout.title,
        exercises: completedExercises,
        duration: elapsed,
        workoutTemplateId: widget.initialWorkout?.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Entrenamiento guardado y finalizado 💪"),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint("Error al guardar entrenamiento: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al guardar: ${e.toString()}")),
        );
      }
    }
  }

  Future<void> _finishWorkout() async {
    _stopTimer();
    _stopRestTimer();
    await _saveWorkoutToFirestore();

    if (mounted) Navigator.pop(context, workout);
  }

  String _formatTime(Duration d) =>
      "${d.inHours.toString().padLeft(2, '0')}:${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}";

  String _formatRestTime(Duration d, {bool showSecondsOnly = false}) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(1, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');

    if (showSecondsOnly) {
      return '$minutes:$seconds';
    }
    return '$minutes min $seconds seg';
  }

  @override
  void dispose() {
    timer?.cancel();
    restTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRoutine = widget.initialWorkout != null;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(workout.title),
        backgroundColor: theme.colorScheme.surfaceContainerHigh,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded),
            onPressed: _editWorkoutDetails,
            tooltip: 'Editar nombre y descanso',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 20.0, bottom: 16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(width: 15),
                    Icon(
                      isResting
                          ? Icons.snooze_rounded
                          : (isRunning
                                ? Icons.timer_outlined
                                : Icons.timer_off_outlined),
                      size: 40,
                      color: isResting
                          ? theme.colorScheme.tertiary
                          : theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isResting
                          ? _formatRestTime(restTime)
                          : _formatTime(elapsed),
                      style: theme.textTheme.displaySmall!.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isResting
                            ? theme.colorScheme.tertiary
                            : theme.colorScheme.primary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: isResting
                          ? null
                          : (isRunning ? _stopTimer : _startTimer),
                      icon: Icon(
                        isRunning
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_fill,
                      ),
                      label: Text(isRunning ? "PAUSAR" : "INICIAR"),
                      style: TextButton.styleFrom(
                        foregroundColor: isResting
                            ? theme.colorScheme.outline
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 15),
                    ElevatedButton.icon(
                      onPressed: isResting ? _stopRestTimer : _startRestTimer,
                      icon: Icon(
                        isResting ? Icons.stop_rounded : Icons.timer_rounded,
                      ),
                      label: Text(
                        isResting
                            ? "CANCELAR DESCANSO"
                            : "DESCANSO (${_formatRestTime(currentRestDuration, showSecondsOnly: true)})",
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isResting
                            ? theme.colorScheme.tertiaryContainer
                            : theme.colorScheme.errorContainer.withValues(
                                alpha: 0.5,
                              ),
                        foregroundColor: isResting
                            ? theme.colorScheme.onTertiaryContainer
                            : theme.colorScheme.onErrorContainer,
                        elevation: 4,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: workout.exercises.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.fitness_center_outlined,
                          size: 60,
                          color: theme.colorScheme.outline.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "¡Añade tu primer ejercicio!",
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: workout.exercises.length,
                    itemBuilder: (context, exIndex) {
                      final ex = workout.exercises[exIndex];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ex.name,
                                  style: theme.textTheme.titleLarge!.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                const Divider(height: 24),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const SizedBox(width: 40),
                                      Expanded(
                                        child: Center(
                                          child: Text(
                                            "Rep. Plan",
                                            style: theme.textTheme.labelLarge
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Center(
                                          child: Text(
                                            "Peso Plan (kg)",
                                            style: theme.textTheme.labelLarge
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 48),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Lista de Series
                                Column(
                                  children: ex.series.asMap().entries.map((
                                    entry,
                                  ) {
                                    final sIndex = entry.key;
                                    final series = entry.value;

                                    return SeriesEntryRow(
                                      key: ValueKey('${ex.name}_$sIndex'),
                                      series: series,
                                      index: sIndex,
                                      onToggleComplete: () =>
                                          _toggleSeriesCompletion(ex, sIndex),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      final lastSeries = ex.series.last;
                                      ex.series.add(
                                        SeriesEntry(
                                          reps: lastSeries.reps,
                                          weight: lastSeries.weight,
                                          isCompleted: false,
                                        ),
                                      );
                                    });
                                  },
                                  icon: const Icon(Icons.add_circle_outline),
                                  label: const Text("Añadir Serie"),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(
                                      double.infinity,
                                      40,
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
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                if (!isRoutine)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _addExercise,
                      icon: const Icon(Icons.fitness_center),
                      label: const Text("Nuevo Ejercicio"),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                if (!isRoutine) const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: workout.exercises.isEmpty
                        ? null
                        : _finishWorkout,
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: const Text("FINALIZAR Y GUARDAR"),
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
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
