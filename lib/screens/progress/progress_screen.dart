import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:nutrimotion/models/training_session_model.dart';
import 'package:nutrimotion/services/training_session_service.dart';
import 'package:intl/intl.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final sessionService = TrainingSessionService();

  Stream<List<TrainingSession>>? _sessionsStream;

  String? _selectedGroup;
  String? _selectedExercise;

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
    _loadSessionsStream();
  }

  void _loadSessionsStream() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      _sessionsStream = sessionService.getSessions(userId);
    }
  }

  List<String> get _availableExercises {
    if (_selectedGroup == null) return [];
    return _groupExercises[_selectedGroup!] ?? [];
  }

  List<Map<String, dynamic>> _getExerciseHistory(
    List<TrainingSession> sessions,
  ) {
    if (_selectedExercise == null) return [];
    final history = <Map<String, dynamic>>[];

    final Map<DateTime, List<double>> weightsByDate = {};

    for (final session in sessions) {
      final matching = session.exercises
          .where((ex) => ex.name == _selectedExercise)
          .toList();

      if (matching.isNotEmpty) {
        final sessionDate = DateTime(
          session.date.year,
          session.date.month,
          session.date.day,
        );

        final allWeights = matching
            .expand((e) => e.series)
            .map((s) => s.weight ?? 0.0)
            .toList();

        weightsByDate.putIfAbsent(sessionDate, () => []).addAll(allWeights);
      }
    }

    weightsByDate.forEach((date, weights) {
      if (weights.isNotEmpty) {
        final avgWeight =
            weights.fold<double>(0, (a, b) => a + b) / weights.length;
        history.add({'date': date, 'weight': avgWeight});
      }
    });

    history.sort((a, b) => a['date'].compareTo(b['date']));
    return history;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Progreso de Entrenamiento"),
        backgroundColor: theme.colorScheme.surfaceContainerHigh,
      ),
      body: StreamBuilder<List<TrainingSession>>(
        stream: _sessionsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text("Error al cargar datos: ${snapshot.error}"),
            );
          }

          final sessions = snapshot.data ?? [];
          final history = _getExerciseHistory(sessions);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Visualización de la Evolución:",
                  style: theme.textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(),
                const SizedBox(height: 8),

                DropdownButtonFormField<String>(
                  initialValue: _selectedGroup,
                  decoration: _buildInputDecoration(theme, "Grupo Muscular"),
                  items: _groupExercises.keys
                      .map(
                        (group) =>
                            DropdownMenuItem(value: group, child: Text(group)),
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

                DropdownButtonFormField<String>(
                  initialValue: _selectedExercise,
                  decoration: _buildInputDecoration(
                    theme,
                    "Ejercicio Específico",
                  ),
                  items: _availableExercises
                      .map(
                        (name) =>
                            DropdownMenuItem(value: name, child: Text(name)),
                      )
                      .toList(),
                  onChanged: _selectedGroup == null
                      ? null
                      : (value) {
                          setState(() {
                            _selectedExercise = value;
                          });
                        },
                  disabledHint: Text(
                    _selectedGroup == null
                        ? "Selecciona un grupo primero"
                        : "Ejercicio Específico",
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                if (_selectedExercise == null)
                  _buildEmptyState(
                    "Selecciona un ejercicio para ver tu evolución 📈",
                    Icons.trending_up_rounded,
                  )
                else if (history.isEmpty)
                  _buildEmptyState(
                    "No hay datos aún para este ejercicio 😔",
                    Icons.search_off,
                  )
                else
                  _buildChart(history, theme),
              ],
            ),
          );
        },
      ),
    );
  }

  InputDecoration _buildInputDecoration(ThemeData theme, String label) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Center(
        child: Column(
          children: [
            Icon(
              icon,
              size: 80,
              color: theme.colorScheme.outline.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium!.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(List<Map<String, dynamic>> data, ThemeData theme) {
    final spots = data
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value['weight'] as double))
        .toList();

    double minWeight = data
        .map((e) => e['weight'] as double)
        .reduce((a, b) => a < b ? a : b);
    double maxWeight = data
        .map((e) => e['weight'] as double)
        .reduce((a, b) => a > b ? a : b);

    double minY = 0;
    double maxY = maxWeight;

    if (data.length <= 2 || (maxWeight - minWeight) < 1.0) {
      minY = (minWeight - 5).clamp(0, minWeight);
      maxY = maxWeight + 5;
    } else {
      final padding = (maxWeight - minWeight) * 0.1;
      minY = (minWeight - padding).clamp(0, minWeight);
      maxY = maxWeight + padding;
    }

    if (maxY == 0) maxY = 10;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Progreso de $_selectedExercise",
          style: theme.textTheme.headlineSmall!.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        AspectRatio(
          aspectRatio: 1.2,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                extraLinesData: ExtraLinesData(
                  verticalLines: [
                    VerticalLine(
                      x: data.length.toDouble() - 0.5,
                      color: theme.colorScheme.outlineVariant,
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    ),
                  ],
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    axisNameWidget: const Text("Peso (kg)"),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          NumberFormat('0.#').format(value),
                          style: theme.textTheme.labelSmall,
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    axisNameWidget: const Text("Fecha de Sesión"),
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 3,
                      reservedSize: 45,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= data.length) {
                          return const Text('');
                        }
                        if (index % 3 != 0) {
                          return Container();
                        }

                        final date = data[index]['date'] as DateTime;

                        return SideTitleWidget(
                          meta: meta,
                          angle: -45 * (3.14159 / 180),
                          space: 10,
                          child: Text(
                            DateFormat('dd/MMM', 'es_ES').format(date),
                            style: theme.textTheme.labelSmall,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: theme.colorScheme.outlineVariant,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    color: theme.colorScheme.primary,
                    barWidth: 3,
                    spots: spots,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: theme.colorScheme.primary,
                          strokeWidth: 1.5,
                          strokeColor: theme.colorScheme.onPrimary,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((LineBarSpot touchedSpot) {
                        final date =
                            data[touchedSpot.spotIndex]['date'] as DateTime;
                        final weight = touchedSpot.y;

                        return LineTooltipItem(
                          '${DateFormat('dd/MM/yy').format(date)}\n',
                          theme.textTheme.labelSmall!.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          children: [
                            TextSpan(
                              text: '${NumberFormat('0.##').format(weight)} kg',
                              style: theme.textTheme.titleSmall!.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ],
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),
        Text(
          "Historial de Registros",
          style: theme.textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildHistoryTable(data, theme),
      ],
    );
  }

  Widget _buildHistoryTable(List<Map<String, dynamic>> data, ThemeData theme) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Fecha",
                    style: theme.textTheme.titleSmall!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Peso Promedio (kg)",
                    style: theme.textTheme.titleSmall!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            ...data.map((item) {
              final date = item['date'] as DateTime;
              final weight = item['weight'] as double;
              return Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(DateFormat('dd MMM yyyy').format(date)),
                    Text(
                      NumberFormat('0.##').format(weight),
                      style: theme.textTheme.bodyLarge!.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
