import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nutrimotion/models/workout_model.dart'; // Asegúrate de que este archivo exista
import 'package:nutrimotion/services/training_session_service.dart'; // Asegúrate de que este archivo exista

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
// 🚀 NUEVO WIDGET STATEFUL PARA GESTIONAR LA FILA DE LA SERIE (Focus Fix)
// ======================================================================
class SeriesEntryRow extends StatefulWidget {
  final SeriesEntry series;
  final int index;
  // Callback opcional si se necesita notificar a la pantalla principal
  final Function(int, double?)? onUpdate;

  const SeriesEntryRow({
    super.key,
    required this.series,
    required this.index,
    this.onUpdate,
  });

  @override
  State<SeriesEntryRow> createState() => _SeriesEntryRowState();
}

class _SeriesEntryRowState extends State<SeriesEntryRow> {
  // Los controladores se declaran e inicializan aquí, fuera del método build,
  // y por lo tanto persisten mientras el widget esté montado.
  late TextEditingController _repsController;
  late TextEditingController _weightController;

  @override
  void initState() {
    super.initState();
    _repsController = TextEditingController(
      text: widget.series.reps.toString(),
    );
    _weightController = TextEditingController(
      text: widget.series.weight?.toString() ?? "",
    );

    // Escucha los cambios en tiempo real sin llamar a setState en la pantalla principal
    _repsController.addListener(_updateReps);
    _weightController.addListener(_updateWeight);
  }

  // Se asegura de que si el widget padre cambia (ej. un nuevo ejercicio),
  // los controladores se actualicen.
  @override
  void didUpdateWidget(covariant SeriesEntryRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.series.reps != widget.series.reps) {
      _repsController.text = widget.series.reps.toString();
    }
    if (oldWidget.series.weight != widget.series.weight) {
      _weightController.text = widget.series.weight?.toString() ?? "";
    }
  }

  // Lógica para actualizar las repeticiones y validar (sin perder el foco)
  void _updateReps() {
    // Solo actualiza si no estamos en el proceso de escribir (compruebas que el texto no esté vacío)
    final text = _repsController.text;
    if (text.isEmpty) return;

    final parsed = int.tryParse(text);
    if (parsed != null && parsed > 0) {
      // Actualiza directamente el modelo de datos (series.reps)
      widget.series.reps = parsed;
      widget.onUpdate?.call(parsed, widget.series.weight);
    } else if (parsed != null && parsed <= 0) {
      // Validación: Muestra SnackBar pero no interrumpe la escritura inmediatamente.
      // La validación final y obligatoria se realiza en _finishWorkout.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Las repeticiones deben ser mayores que 0."),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // Lógica para actualizar el peso y validar (sin perder el foco)
  void _updateWeight() {
    final text = _weightController.text;
    if (text.isEmpty) {
      widget.series.weight =
          null; // o 0.0 según tu modelo. Dejo null por si el campo está vacío.
      widget.onUpdate?.call(widget.series.reps, null);
      return;
    }

    final parsed = double.tryParse(text);
    if (parsed != null && parsed > 0) {
      // Actualiza directamente el modelo de datos (series.weight)
      widget.series.weight = parsed;
      widget.onUpdate?.call(widget.series.reps, parsed);
    } else if (parsed != null && parsed <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("El peso debe ser mayor que 0."),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    // Es crucial deshacerse de los controladores para evitar fugas de memoria
    _repsController.removeListener(_updateReps);
    _weightController.removeListener(_updateWeight);
    _repsController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 40, child: Text("${widget.index + 1}")),
          SizedBox(
            width: 60,
            child: TextField(
              controller: _repsController, // Controlador persistente
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Reps"),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 60,
            child: TextField(
              controller: _weightController, // Controlador persistente
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Peso"),
            ),
          ),
        ],
      ),
    );
  }
}

// ======================================================================
// CLASE PRINCIPAL: _WorkoutSessionScreenState
// ======================================================================
class _WorkoutSessionScreenState extends State<WorkoutSessionScreen> {
  late Workout workout;
  bool isRunning = false;
  Duration elapsed = Duration.zero;
  Timer? timer;

  final _trainingService = TrainingSessionService();

  @override
  void initState() {
    super.initState();
    workout =
        widget.initialWorkout ??
        Workout(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: "Entrenamiento nuevo",
          day: DateTime.now().toString(),
          exercises: [],
        );

    if (widget.startAutomatically) _startTimer();
  }

  void _startTimer() {
    if (isRunning) return;
    setState(() => isRunning = true);
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      // Este setState es lo que causaba el problema de foco antes.
      // Ahora solo reconstruye la parte superior de la pantalla.
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
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: weightCtrl,
              decoration: const InputDecoration(labelText: "Peso (kg)"),
              keyboardType: TextInputType.number,
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
              final name = nameCtrl.text.trim();
              final reps = int.tryParse(repsCtrl.text) ?? 0;
              final weight = double.tryParse(weightCtrl.text) ?? 0;

              if (name.isEmpty || reps <= 0 || weight <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Por favor ingresa valores válidos (mayores a 0).",
                    ),
                    backgroundColor: Colors.redAccent,
                  ),
                );
                return; // No continúa si hay error
              }

              setState(() {
                workout.exercises.add(
                  Exercise(
                    name: name,
                    series: [SeriesEntry(reps: reps, weight: weight)],
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
      final userId = FirebaseAuth.instance.currentUser!.uid;
      await _trainingService.saveSession(
        userId: userId,
        title: workout.title,
        exercises: workout.exercises,
        duration: elapsed,
        workoutTemplateId: widget.initialWorkout?.id,
      );
    } catch (e) {
      debugPrint("Error al guardar entrenamiento: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error al guardar: $e")));
    }
  }

  Future<void> _finishWorkout() async {
    // 🔒 Validar antes de guardar (Esta validación sigue siendo importante)
    for (final ex in workout.exercises) {
      for (final s in ex.series) {
        if (s.reps <= 0 || (s.weight == null || s.weight! <= 0)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "No se pueden guardar series con repeticiones o peso en 0.",
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
          return;
        }
      }
    }

    _stopTimer();
    await _saveWorkoutToFirestore();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Entrenamiento guardado y finalizado 💪")),
    );
    Navigator.pop(context, workout);
  }

  String _formatTime(Duration d) =>
      "${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}";

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRoutine = widget.initialWorkout != null;

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
                      "No hay ejercicios aún.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: workout.exercises.length,
                    itemBuilder: (context, exIndex) {
                      final ex = workout.exercises[exIndex];
                      return Card(
                        margin: const EdgeInsets.all(8),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ex.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Column(
                                children: ex.series.asMap().entries.map((
                                  entry,
                                ) {
                                  final sIndex = entry.key;
                                  final series = entry.value;

                                  // 🔑 USAMOS EL NUEVO WIDGET PERSISTENTE AQUÍ
                                  return SeriesEntryRow(
                                    // Usar una clave única ayuda a Flutter a rastrear el estado
                                    key: ValueKey('${ex.name}_$sIndex'),
                                    series: series,
                                    index: sIndex,
                                    onUpdate: (reps, weight) {
                                      // Si se necesita forzar una reconstrucción
                                      // cuando los datos cambian (poco probable aquí,
                                      // ya que el modelo ya se actualiza), se haría aquí.
                                    },
                                  );
                                }).toList(),
                              ),
                            ],
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
                    child: ElevatedButton.icon(
                      onPressed: _addExercise,
                      icon: const Icon(Icons.add),
                      label: const Text("Agregar ejercicio"),
                    ),
                  ),
                if (!isRoutine) const SizedBox(width: 12),
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
