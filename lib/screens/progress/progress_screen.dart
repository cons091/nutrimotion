import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:nutrimotion/models/training_session_model.dart';
import 'package:nutrimotion/services/training_session_service.dart';
import 'package:nutrimotion/utils/exercise_list.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final sessionService = TrainingSessionService();
  List<TrainingSession> _sessions = [];
  bool _loading = true;

  /// Suscripción al stream de sesiones: se cancela en [dispose] para no
  /// seguir escuchando (ni llamando a setState) tras salir de la pantalla.
  StreamSubscription<List<TrainingSession>>? _sessionsSub;

  String? _selectedGroup;
  String? _selectedExercise;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  void _loadSessions() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      setState(() => _loading = false);
      return;
    }

    _sessionsSub = sessionService.getSessions(userId).listen((sessions) {
      if (!mounted) return;
      setState(() {
        _sessions = sessions;
        _loading = false;
      });
    });
  }

  @override
  void dispose() {
    _sessionsSub?.cancel();
    super.dispose();
  }

  /// Devuelve todos los ejercicios del grupo seleccionado
  /// (misma lista que usa el picker al entrenar: los nombres coinciden).
  List<String> get _availableExercises {
    if (_selectedGroup == null) return [];
    return ExerciseList.exercisesByGroup[_selectedGroup!] ?? [];
  }

  /// Obtiene los datos del ejercicio seleccionado para graficar
  List<Map<String, dynamic>> get _exerciseHistory {
    if (_selectedExercise == null) return [];
    final history = <Map<String, dynamic>>[];

    for (final session in _sessions) {
      final matching = session.exercises
          .where((ex) => ex.name == _selectedExercise)
          .toList();
      if (matching.isNotEmpty) {
        final allSeries = matching.expand((e) => e.series).toList();
        final avgWeight =
            allSeries
                .map((s) => s.weight ?? 0)
                .fold<double>(0, (a, b) => a + b) /
            (allSeries.isNotEmpty ? allSeries.length : 1);
        history.add({'date': session.date, 'weight': avgWeight});
      }
    }

    history.sort((a, b) => a['date'].compareTo(b['date']));
    return history;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Progreso")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Selecciona una zona y un ejercicio",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1B3B1F),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Selección de grupo muscular
                  DropdownButtonFormField<String>(
                    initialValue: _selectedGroup,
                    hint: const Text("Seleccionar grupo muscular"),
                    items: ExerciseList.groups
                        .map(
                          (group) => DropdownMenuItem(
                            value: group,
                            child: Text(ExerciseList.labelFor(group)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedGroup = value;
                        _selectedExercise = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Selección de ejercicio
                  if (_selectedGroup != null)
                    DropdownButtonFormField<String>(
                      initialValue: _selectedExercise,
                      hint: const Text("Seleccionar ejercicio"),
                      items: _availableExercises
                          .map(
                            (name) => DropdownMenuItem(
                              value: name,
                              child: Text(name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedExercise = value;
                        });
                      },
                    ),
                  const SizedBox(height: 24),

                  Expanded(
                    child: _selectedExercise == null
                        ? _emptyState(
                            Icons.insights_outlined,
                            "Selecciona un ejercicio\npara ver tu evolución",
                          )
                        : _exerciseHistory.isEmpty
                        ? _emptyState(
                            Icons.hourglass_empty,
                            "No hay datos aún para este ejercicio.\n¡Entrena y vuelve!",
                          )
                        : _buildChart(),
                  ),
                ],
              ),
            ),
    );
  }

  /// Estado vacío con icono, para guiar al usuario.
  Widget _emptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    final data = _exerciseHistory;

    final spots = data
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value['weight'] as double))
        .toList();

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Progreso de $_selectedExercise",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1B3B1F),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
          child: LineChart(
            LineChartData(
              minY: 0,
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= data.length) {
                        return const Text('');
                      }
                      final date = data[index]['date'] as DateTime;
                      return Text(
                        "${date.day}/${date.month}",
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
              ),
              gridData: const FlGridData(show: true),
              lineBarsData: [
                LineChartBarData(
                  isCurved: true,
                  color: Theme.of(context).colorScheme.primary,
                  barWidth: 3,
                  spots: spots,
                  dotData: const FlDotData(show: true),
                ),
              ],
            ),
          ),
        ),
            const SizedBox(height: 10),
            const Text(
              "Eje X: Fecha | Eje Y: Peso promedio (kg)",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
