import 'package:flutter/material.dart';
import 'package:nutrimotion/models/workout_model.dart';
import 'package:nutrimotion/screens/training/workout_form_screen.dart';
import 'package:nutrimotion/screens/training/workout_session_screen.dart'; // Asumiendo que existe

class WorkoutDetailScreen extends StatefulWidget {
  final Workout workout;
  const WorkoutDetailScreen({super.key, required this.workout});

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  late Workout _currentWorkout;

  @override
  void initState() {
    super.initState();
    _currentWorkout = widget.workout;
  }

  // 🔄 Función para manejar la edición y actualización
  void _editWorkout() async {
    final updatedWorkout = await Navigator.push<Workout>(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutFormScreen(existingWorkout: _currentWorkout),
      ),
    );

    // Si se recibió una rutina actualizada (no es null)
    if (updatedWorkout != null) {
      setState(() {
        _currentWorkout = updatedWorkout;
      });
      // Devolvemos el resultado al WorkoutListScreen para que se actualice
      if (mounted) {
        Navigator.pop(context, updatedWorkout);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Función de ayuda para determinar el icono del día/grupo muscular
    IconData _getDayIcon(String day) {
      switch (day) {
        case "Piernas":
          return Icons.airline_seat_legroom_extra_rounded;
        case "Espalda":
          return Icons.back_hand_rounded;
        case "Pecho":
          return Icons.man_rounded;
        case "Hombros":
          return Icons.accessibility_new_rounded;
        case "Brazos":
          return Icons.fitness_center_rounded;
        case "FullBody":
          return Icons.run_circle_rounded;
        default:
          return Icons.calendar_month;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentWorkout.title),
        backgroundColor: theme.colorScheme.surfaceContainer,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ℹ️ Información General
              Row(
                children: [
                  Icon(
                    _getDayIcon(_currentWorkout.day),
                    color: theme.colorScheme.primary,
                    size: 30,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _currentWorkout.day,
                    style: theme.textTheme.titleLarge!.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Text(
                "Ejercicios (${_currentWorkout.exercises.length})",
                style: theme.textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(thickness: 2),

              // 🏋️‍♂️ Lista de Ejercicios
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _currentWorkout.exercises.length,
                itemBuilder: (context, index) {
                  final ex = _currentWorkout.exercises[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${index + 1}. ${ex.name}",
                            style: theme.textTheme.titleMedium!.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Estilo de tabla más limpio sin bordes completos
                          Table(
                            columnWidths: const {
                              0: FlexColumnWidth(1.5), // Serie
                              1: FlexColumnWidth(1.5), // Reps
                              2: FlexColumnWidth(2.5), // Peso
                            },
                            children: [
                              // Encabezado de la tabla
                              TableRow(
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                children: [
                                  _buildTableCell(
                                    "Serie",
                                    isHeader: true,
                                    theme: theme,
                                  ),
                                  _buildTableCell(
                                    "Reps",
                                    isHeader: true,
                                    theme: theme,
                                  ),
                                  _buildTableCell(
                                    "Peso (kg)",
                                    isHeader: true,
                                    theme: theme,
                                  ),
                                ],
                              ),
                              // Filas de datos
                              ...ex.series.asMap().entries.map((entry) {
                                final i = entry.key + 1;
                                final s = entry.value;
                                return TableRow(
                                  children: [
                                    _buildTableCell("$i", theme: theme),
                                    _buildTableCell("${s.reps}", theme: theme),
                                    _buildTableCell(
                                      "${s.weight ?? 0}",
                                      theme: theme,
                                    ),
                                  ],
                                );
                              }).toList(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),

      // ➕ Botones Flotantes Agrupados: Empezar y Editar (Alternativa al Appbar)
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // ✏️ Editar (Small FAB) - Si se prefiere no usar el AppBar Action
          FloatingActionButton.small(
            heroTag: "fab_edit",
            onPressed: _editWorkout,
            tooltip: "Editar rutina",
            backgroundColor: theme.colorScheme.secondaryContainer,
            foregroundColor: theme.colorScheme.onSecondaryContainer,
            child: const Icon(Icons.edit_note_rounded),
          ),
          const SizedBox(height: 10),

          // 🚀 Comenzar Rutina (Extended FAB principal)
          FloatingActionButton.extended(
            heroTag: "fab_start",
            onPressed: () {
              // Navegar a la pantalla de sesión de entrenamiento
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WorkoutSessionScreen(
                    initialWorkout: _currentWorkout,
                    startAutomatically: true,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text("COMENZAR RUTINA"),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // Widget auxiliar para construir celdas de tabla estilizadas
  Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    required ThemeData theme,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: Center(
        child: Text(
          text,
          style: isHeader
              ? theme.textTheme.labelMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                )
              : theme.textTheme.bodyMedium,
        ),
      ),
    );
  }
}
