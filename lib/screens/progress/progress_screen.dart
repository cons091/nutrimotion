import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:nutrimotion/models/training_session_model.dart';
import 'package:nutrimotion/services/training_session_service.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final sessionService = TrainingSessionService();
  List<TrainingSession> _sessions = [];
  bool _loading = true;

  String? _selectedGroup;
  String? _selectedExercise;

  // Mapeo de grupo muscular → ejercicios
  final Map<String, List<String>> _groupExercises = {
    "Pecho": [
      "Press de banca con barra",
      "Press inclinado con mancuernas",
      "Aperturas con mancuernas en banco plano",
      "Fondos en paralelas",
      "Cruces en polea alta",
    ],
    "Espalda": [
      "Dominadas",
      "Remo con barra",
      "Peso muerto convencional",
      "Remo en polea baja",
      "Pull-over en polea",
    ],
    "Piernas": [
      "Sentadilla con barra",
      "Prensa inclinada",
      "Zancadas con mancuernas",
      "Peso muerto rumano",
      "Curl femoral en máquina",
      "Extensiones de cuádriceps en máquina",
    ],
    "Hombros": [
      "Press militar con barra",
      "Elevaciones laterales",
      "Press Arnold",
      "Remo al mentón",
    ],
    "Brazos": [
      "Curl con barra Z",
      "Curl martillo",
      "Press francés con barra Z",
      "Extensión en polea con cuerda",
    ],
    "FullBody": [
      "Sentadilla frontal",
      "Press banca",
      "Peso muerto",
      "Press militar",
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    sessionService.getSessions(userId).listen((sessions) {
      setState(() {
        _sessions = sessions;
        _loading = false;
      });
    });
  }

  /// Devuelve todos los ejercicios del grupo seleccionado
  List<String> get _availableExercises {
    if (_selectedGroup == null) return [];
    final targetList = _groupExercises[_selectedGroup!] ?? [];
    return targetList; // ahora no filtramos por sesiones
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
                    "Selecciona una zona y un ejercicio:",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Selección de grupo muscular
                  DropdownButtonFormField<String>(
                    value: _selectedGroup,
                    hint: const Text("Seleccionar grupo muscular"),
                    items: _groupExercises.keys
                        .map(
                          (group) => DropdownMenuItem(
                            value: group,
                            child: Text(group),
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
                      value: _selectedExercise,
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
                        ? const Center(
                            child: Text(
                              "Selecciona un ejercicio para ver tu evolución 📈",
                              style: TextStyle(fontSize: 16),
                            ),
                          )
                        : _exerciseHistory.isEmpty
                        ? const Center(
                            child: Text(
                              "No hay datos aún para este ejercicio",
                              style: TextStyle(fontSize: 16),
                            ),
                          )
                        : _buildChart(),
                  ),
                ],
              ),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Progreso de $_selectedExercise",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                  color: Colors.green,
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
    );
  }
}
