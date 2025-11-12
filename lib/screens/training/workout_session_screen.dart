import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nutrimotion/models/workout_model.dart';
import 'package:nutrimotion/services/training_session_service.dart';
import 'package:flutter/foundation.dart' show kDebugMode; // Para debugPrint
import 'package:intl/intl.dart'; // Necesario para formatear el número de peso

// ======================================================================
// WIDGET PRINCIPAL
// ======================================================================

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

// ======================================================================
// WIDGET SECUNDARIO: SeriesEntryRow
// ======================================================================

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
    // Aseguramos que el peso se muestre con una precisión legible
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
      // Permitir reps 0 temporalmente
      widget.series.reps = parsed;
      widget.onUpdate?.call(parsed, widget.series.weight);
    }
  }

  void _updateWeight() {
    final text = _weightController.text;
    if (text.isEmpty) {
      widget.series.weight = 0; // Usar 0 en lugar de null para consistencia
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
            ? theme.colorScheme.primaryContainer.withOpacity(0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Número de Serie
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

          // Campo de Repeticiones
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

          // Campo de Peso
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

          // Botón de Check/Completado
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

// ======================================================================
// ESTADO PRINCIPAL: _WorkoutSessionScreenState
// ======================================================================

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen> {
  late Workout workout;

  // Cronómetro principal
  bool isRunning = false;
  Duration elapsed = Duration.zero;
  Timer? timer;

  // Temporizador de descanso
  Timer? restTimer;
  Duration restTime = Duration.zero;
  bool isResting = false;
  final Duration defaultRestDuration = const Duration(
    minutes: 1,
    seconds: 30,
  ); // 90s

  final _trainingService = TrainingSessionService();

  @override
  void initState() {
    super.initState();
    // Inicialización del workout
    workout =
        widget.initialWorkout ??
        Workout(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: "Entrenamiento rápido",
          day: DateFormat(
            'EEEE',
          ).format(DateTime.now()), // Día de la semana actual
          exercises: [],
        );

    // Si es una plantilla, aseguramos que todas las series tengan isCompleted = false
    for (var ex in workout.exercises) {
      for (var series in ex.series) {
        series.isCompleted = false;
        // Si el peso es nulo, lo establecemos a 0 para mejor manejo en sesión
        series.weight ??= 0;
      }
    }

    if (widget.startAutomatically) _startTimer();
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
    _stopTimer(); // Pausar el cronómetro principal

    setState(() {
      isResting = true;
      restTime = defaultRestDuration;
    });

    restTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (restTime.inSeconds > 0) {
        setState(() => restTime -= const Duration(seconds: 1));
      } else {
        _stopRestTimer();
        _startTimer(); // Reanudar el entrenamiento
        // Opcional: Notificación/Vibración
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Descanso iniciado: ${_formatRestTime(defaultRestDuration)} 🧘",
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

    // Si la serie se marca como completada, sugerir iniciar el descanso
    if (exercise.series[seriesIndex].isCompleted == true) {
      _startRestTimer();
    }
  }

  // Método para agregar ejercicio (mejorado con validación y Material 3)
  void _addExercise() {
    TextEditingController nameCtrl = TextEditingController();
    TextEditingController repsCtrl = TextEditingController(text: "10");
    TextEditingController weightCtrl = TextEditingController(text: "0");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("➕ Agregar Ejercicio"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: "Nombre del Ejercicio",
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: repsCtrl,
              decoration: const InputDecoration(
                labelText: "Repeticiones (Mín 1)",
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: weightCtrl,
              decoration: const InputDecoration(labelText: "Peso (kg) (Mín 0)"),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          FilledButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final reps = int.tryParse(repsCtrl.text) ?? 0;
              final weight = double.tryParse(weightCtrl.text) ?? 0;

              if (name.isEmpty || reps <= 0) {
                // Permitimos peso 0
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "El Nombre y las Repeticiones deben ser mayores a 0.",
                      ),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
                return;
              }

              setState(() {
                workout.exercises.add(
                  Exercise(
                    name: name,
                    series: [
                      SeriesEntry(
                        reps: reps,
                        weight: weight,
                        isCompleted: false,
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
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception("Usuario no autenticado");
      }

      // Filtramos las series que se completaron y tienen valores válidos (Reps > 0)
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

  String _formatRestTime(Duration d) =>
      "${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}";

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
      ),
      body: Column(
        children: [
          // ⏱️ Sección del Cronómetro (Estilo Moderno)
          Padding(
            padding: const EdgeInsets.only(top: 20.0, bottom: 16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
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
                // Botones de control del cronómetro y descanso
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
                        isResting ? "CANCELAR DESCANSO" : "DESCANSO (90s)",
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isResting
                            ? theme.colorScheme.tertiaryContainer
                            : theme.colorScheme.errorContainer.withOpacity(0.5),
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

          // 🏋️‍♂️ Lista de Ejercicios
          Expanded(
            child: workout.exercises.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.fitness_center_outlined,
                          size: 60,
                          color: theme.colorScheme.outline.withOpacity(0.5),
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
                                // Nombre del Ejercicio
                                Text(
                                  ex.name,
                                  style: theme.textTheme.titleLarge!.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme
                                        .colorScheme
                                        .primary, // Color primario para resaltar
                                  ),
                                ),
                                const Divider(height: 24),

                                // Encabezados de Columna (Asegurar que los textos sean visibles y centrados)
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
                                      const SizedBox(
                                        width: 48,
                                      ), // Espacio para el icono de check
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

                                // Botón para añadir una nueva serie al ejercicio
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

          // 🎯 Botones de Acción (Pie de página)
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
