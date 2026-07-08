import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import 'package:nutrimotion/models/user_model.dart';
import 'package:nutrimotion/models/food_entry.dart';
import 'package:nutrimotion/models/nutrition_goals.dart';
import 'package:nutrimotion/models/nutrition_summary.dart';
import 'package:nutrimotion/services/nutrition_service.dart';
import 'package:nutrimotion/utils/nutrition_calculator.dart';
import 'package:nutrimotion/screens/nutrition/add_food_sheet.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  final _nutritionService = NutritionService();
  final _uuid = const Uuid();

  NutritionGoals? _goals;
  bool _loadingProfile = true;

  /// Día visible, normalizado a medianoche.
  late DateTime _selectedDay;

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDay = DateTime(now.year, now.month, now.day);
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = _userId;
    if (uid == null) {
      setState(() => _loadingProfile = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (!mounted) return;
      if (doc.exists && doc.data() != null) {
        final user = AppUser.fromMap(doc.data()!);
        setState(() {
          _goals = NutritionCalculator.forUser(user);
          _loadingProfile = false;
        });
      } else {
        setState(() => _loadingProfile = false);
      }
    } catch (_) {
      setState(() => _loadingProfile = false);
    }
  }

  void _changeDay(int deltaDays) {
    setState(() {
      _selectedDay = _selectedDay.add(Duration(days: deltaDays));
    });
  }

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDay.year == now.year &&
        _selectedDay.month == now.month &&
        _selectedDay.day == now.day;
  }

  Future<void> _openAddFood(MealType meal) async {
    final uid = _userId;
    if (uid == null) return;

    final result = await showModalBottomSheet<FoodEntry>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => AddFoodSheet(initialMeal: meal),
    );

    if (result == null) return;

    // La hoja devuelve un FoodEntry sin id/fecha definitivos: los fijamos aquí.
    final entry = result.copyWith(
      id: _uuid.v4(),
      date: DateTime(
        _selectedDay.year,
        _selectedDay.month,
        _selectedDay.day,
        DateTime.now().hour,
        DateTime.now().minute,
        DateTime.now().second,
      ),
    );

    try {
      await _nutritionService.addEntry(uid, entry);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo guardar el alimento'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteEntry(FoodEntry entry) async {
    final uid = _userId;
    if (uid == null) return;
    try {
      await _nutritionService.deleteEntry(uid, entry.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${entry.name} eliminado')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo eliminar'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = _userId;

    return Scaffold(
      appBar: AppBar(title: const Text('Nutrición')),
      body: _loadingProfile
          ? const Center(child: CircularProgressIndicator())
          : uid == null
          ? const Center(child: Text('Inicia sesión para ver tu nutrición'))
          : StreamBuilder<List<FoodEntry>>(
              stream: _nutritionService.entriesForDay(uid, _selectedDay),
              builder: (context, snapshot) {
                // Un stream de Firestore que falla (p. ej. reglas de
                // seguridad sin desplegar) muere silenciosamente: hay que
                // mostrarlo, no fingir que no hay datos.
                if (snapshot.hasError) {
                  return _buildStreamError(snapshot.error);
                }
                final entries = snapshot.data ?? [];
                final summary = NutritionSummary.from(entries, _goals);
                final loading =
                    snapshot.connectionState == ConnectionState.waiting;

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildDaySelector()),
                    SliverToBoxAdapter(
                      child: _goals == null
                          ? _buildProfileIncompleteCard()
                          : _buildSummaryCard(summary),
                    ),
                    if (loading)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      )
                    else
                      ..._buildMealSections(summary),
                    const SliverToBoxAdapter(child: SizedBox(height: 90)),
                  ],
                );
              },
            ),
      floatingActionButton: (uid == null)
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openAddFood(MealType.snack),
              icon: const Icon(Icons.add),
              label: const Text('Agregar'),
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // Selector de día
  // ---------------------------------------------------------------------------
  Widget _buildDaySelector() {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE1ECDF)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.chevron_left, color: scheme.primary),
              onPressed: () => _changeDay(-1),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_today, size: 15, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  _isToday ? 'Hoy' : _formatDate(_selectedDay),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1B3B1F),
                  ),
                ),
              ],
            ),
            IconButton(
              icon: Icon(
                Icons.chevron_right,
                color: _isToday ? Colors.grey.shade300 : scheme.primary,
              ),
              // No permitir avanzar más allá de hoy.
              onPressed: _isToday ? null : () => _changeDay(1),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tarjeta de resumen (calorías + macros)
  // ---------------------------------------------------------------------------
  Widget _buildSummaryCard(NutritionSummary s) {
    final goals = s.goals!;
    final remaining = s.remainingCalories;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _calorieBlock(
                  'Objetivo',
                  goals.calories.round().toString(),
                ),
                _calorieRing(s),
                _calorieBlock(
                  remaining >= 0 ? 'Restante' : 'Exceso',
                  remaining.abs().round().toString(),
                  color: remaining >= 0
                      ? Theme.of(context).colorScheme.primary
                      : Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 20),
            _macroBar(
              'Proteína',
              s.consumedProtein,
              goals.protein,
              s.proteinProgress,
              Colors.redAccent,
            ),
            const SizedBox(height: 10),
            _macroBar(
              'Carbohidratos',
              s.consumedCarbs,
              goals.carbs,
              s.carbsProgress,
              Colors.orange,
            ),
            const SizedBox(height: 10),
            _macroBar(
              'Grasa',
              s.consumedFat,
              goals.fat,
              s.fatProgress,
              Colors.blueAccent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _calorieBlock(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black87,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _calorieRing(NutritionSummary s) {
    return SizedBox(
      width: 92,
      height: 92,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 92,
            height: 92,
            child: CircularProgressIndicator(
              value: s.caloriesProgress,
              strokeWidth: 9,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(
                s.isOverCalories
                    ? Colors.red
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                s.consumedCalories.round().toString(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'kcal',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _macroBar(
    String label,
    double consumed,
    double goal,
    double progress,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(
              '${consumed.round()} / ${goal.round()} g',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Error del stream de Firestore (p. ej. permisos)
  // ---------------------------------------------------------------------------
  Widget _buildStreamError(Object? error) {
    final isPermission = error.toString().contains('permission-denied');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              isPermission
                  ? 'Sin permiso para leer tu diario de nutrición.\n'
                        'Revisa las reglas de Firestore (firestore.rules).'
                  : 'No se pudo cargar tu diario de nutrición.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Aviso de perfil incompleto
  // ---------------------------------------------------------------------------
  Widget _buildProfileIncompleteCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      color: Colors.amber.shade50,
      child: const Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.amber, size: 32),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Completa tu peso, altura y edad en tu Perfil para calcular '
                'tus objetivos de calorías y macros.',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Secciones por comida
  // ---------------------------------------------------------------------------
  List<Widget> _buildMealSections(NutritionSummary s) {
    return MealType.values.map((meal) {
      final entries = s.entriesFor(meal);
      final kcal = s.caloriesFor(meal);
      return SliverToBoxAdapter(
        child: _mealCard(meal, entries, kcal),
      );
    }).toList();
  }

  Widget _mealCard(MealType meal, List<FoodEntry> entries, double kcal) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  _mealIcon(meal),
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              title: Text(
                meal.label,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('${kcal.round()} kcal'),
              trailing: IconButton(
                icon: Icon(
                  Icons.add_circle_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onPressed: () => _openAddFood(meal),
              ),
            ),
            if (entries.isEmpty)
              const Padding(
                padding: EdgeInsets.only(left: 16, bottom: 8, right: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Sin alimentos registrados',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
              )
            else
              ...entries.map((e) => _entryTile(e)),
          ],
        ),
      ),
    );
  }

  Widget _entryTile(FoodEntry e) {
    return Dismissible(
      key: ValueKey(e.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _deleteEntry(e),
      child: ListTile(
        dense: true,
        title: Text(e.name),
        subtitle: Text(
          [
            if (e.quantityGrams != null) '${e.quantityGrams!.round()} g',
            'P ${e.protein.round()}g',
            'C ${e.carbs.round()}g',
            'G ${e.fat.round()}g',
          ].join(' · '),
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Text(
          '${e.calories.round()} kcal',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------
  IconData _mealIcon(MealType meal) {
    switch (meal) {
      case MealType.desayuno:
        return Icons.free_breakfast;
      case MealType.almuerzo:
        return Icons.lunch_dining;
      case MealType.cena:
        return Icons.dinner_dining;
      case MealType.snack:
        return Icons.cookie;
    }
  }

  String _formatDate(DateTime d) {
    const meses = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    return '${d.day} ${meses[d.month - 1]} ${d.year}';
  }
}
