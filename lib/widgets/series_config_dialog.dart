import 'package:flutter/material.dart';
import 'package:nutrimotion/models/workout_model.dart';

/// Diálogo para configurar las series (reps y peso) de un ejercicio.
///
/// Es un `StatefulWidget` para que los [TextEditingController] queden ligados
/// al ciclo de vida del diálogo y se liberen en [dispose]. Antes se creaban
/// dentro del builder de `showDialog` y nunca se liberaban (fuga de memoria).
///
/// Devuelve vía `Navigator.pop` la lista de [SeriesEntry] configurada, o
/// `null` si se cancela. Usado por `empty_workout_screen` y
/// `workout_form_screen` (que antes duplicaban este mismo diálogo).
class SeriesConfigDialog extends StatefulWidget {
  final String exerciseName;

  /// Si es `true`, exige peso > 0 en todas las series (además de reps > 0).
  /// Si es `false`, el peso es opcional (ejercicios con peso corporal).
  final bool requireWeight;

  const SeriesConfigDialog({
    super.key,
    required this.exerciseName,
    this.requireWeight = false,
  });

  @override
  State<SeriesConfigDialog> createState() => _SeriesConfigDialogState();
}

class _SeriesConfigDialogState extends State<SeriesConfigDialog> {
  final List<TextEditingController> _repsControllers = [];
  final List<TextEditingController> _weightControllers = [];

  @override
  void initState() {
    super.initState();
    _addSeriesRow();
  }

  @override
  void dispose() {
    for (final c in _repsControllers) {
      c.dispose();
    }
    for (final c in _weightControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addSeriesRow() {
    _repsControllers.add(TextEditingController());
    _weightControllers.add(TextEditingController());
  }

  void _submit() {
    final series = <SeriesEntry>[];
    for (var i = 0; i < _repsControllers.length; i++) {
      final reps = int.tryParse(_repsControllers[i].text.trim()) ?? 0;
      final weight = double.tryParse(
        _weightControllers[i].text.trim().replaceAll(',', '.'),
      );

      final invalidWeight =
          widget.requireWeight && (weight == null || weight <= 0);
      if (reps <= 0 || invalidWeight) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.requireWeight
                  ? "No se permiten valores 0 en series o peso."
                  : "Las repeticiones deben ser mayores que 0.",
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
      series.add(SeriesEntry(reps: reps, weight: weight));
    }
    Navigator.pop(context, series);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Configurar ${widget.exerciseName}"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Series"),
            ...List.generate(_repsControllers.length, (i) {
              return Row(
                children: [
                  Text("Serie ${i + 1}: "),
                  Expanded(
                    child: TextField(
                      controller: _repsControllers[i],
                      decoration: const InputDecoration(labelText: "Reps"),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _weightControllers[i],
                      decoration: const InputDecoration(labelText: "Peso (kg)"),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                ],
              );
            }),
            TextButton.icon(
              onPressed: () => setState(_addSeriesRow),
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
        ElevatedButton(onPressed: _submit, child: const Text("Añadir")),
      ],
    );
  }
}
