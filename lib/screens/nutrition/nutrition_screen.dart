import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:nutrimotion/screens/food/food_search_screen.dart';
import 'package:nutrimotion/services/nutrition_calculator.dart';
import 'package:nutrimotion/services/user_service.dart';
import 'package:nutrimotion/services/meal_service.dart';
import 'package:nutrimotion/models/meal_entry_model.dart';
import 'package:nutrimotion/models/food_model.dart';
import 'package:nutrimotion/models/user_model.dart';
import 'dart:async';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  final _userService = UserService();
  final _auth = FirebaseAuth.instance;
  late final NumberFormat numberFormat;

  final MealService _mealService = MealService();

  double _tdee = 0.0;
  Map<String, double> _macros = {};

  String _selectedActivityLevel = NutritionCalculator.activityLevels.keys.first;
  String _selectedGoal = NutritionCalculator.goalAdjustments.keys.firstWhere(
    (k) => k == 'Mantener peso',
    orElse: () => NutritionCalculator.goalAdjustments.keys.first,
  );
  final _selectedMacroPlan = NutritionCalculator.macroPlans.keys.first;

  DateTime _selectedDate = DateTime.now();

  List<MealEntry> _allEntriesForDay = [];
  StreamSubscription? _mealSubscription;

  @override
  void initState() {
    super.initState();
    numberFormat = NumberFormat('#,##0', 'es_ES');
    _listenToMealEntries();
  }

  @override
  void dispose() {
    _mealSubscription?.cancel();
    super.dispose();
  }

  void _listenToMealEntries() {
    _mealSubscription?.cancel();

    final stream = _mealService.getEntriesForDate(_selectedDate);

    _mealSubscription = stream.listen(
      (entries) {
        if (mounted) {
          setState(() {
            _allEntriesForDay = entries;
          });
        }
      },
      onError: (e) {
        if (mounted) {
          final errorMessage =
              e?.toString() ?? 'Error desconocido al cargar el diario.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al cargar diario: $errorMessage')),
          );
        }
      },
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _listenToMealEntries();
    }
  }

  /// -------------------------------------------------------------
  /// LÓGICA DE CÁLCULO
  /// -------------------------------------------------------------

  /// 1. Carga los parámetros del usuario, ejecuta los cálculos y actualiza el estado.
  void _calculateNutrition(AppUser user) {
    // 1.1. Validar que tenemos la data mínima para calcular
    if (user.peso == null ||
        user.altura == null ||
        user.edad == null ||
        user.sexo == null) {
      // Solo actualizamos las variables, el StreamBuilder manejará la UI
      _tdee = 0.0;
      _macros = {};
      return;
    }

    // 1.2. Inicializar parámetros seleccionables desde Firebase
    // Si la propiedad 'actividad' existe en Firebase, la usa; si no, usa el valor por defecto.
    final activity = user.actividad ?? _selectedActivityLevel;
    final goal = user.objetivo ?? _selectedGoal;

    // 1.3. Actualizar las variables de estado locales (sin setState)
    // Esto asegura que los dropdowns se carguen con el valor de Firebase
    if (_selectedActivityLevel != activity) {
      _selectedActivityLevel = activity;
    }
    if (_selectedGoal != goal) {
      _selectedGoal = goal;
    }

    // El Plan Macro (_selectedMacroPlan) usa el valor local de la UI

    // 2. Calcular BMR
    final bmr = NutritionCalculator.calculateBMR(
      weightKg: user.peso!,
      heightCm: user.altura!,
      age: user.edad!,
      gender: user.sexo!,
    );

    // 3. Calcular TDEE Ajustado por Actividad y Objetivo
    final tdee = NutritionCalculator.calculateTDEE(
      bmr: bmr,
      activityLevel: activity, // Usamos el valor de Firebase/local
      goal: goal, // Usamos el valor de Firebase/local
    );

    // 4. Distribuir Macros
    final macros = NutritionCalculator.calculateMacros(
      totalCalories: tdee,
      planName: _selectedMacroPlan, // Usamos el valor local de la UI
    );

    // 5. Actualizar los resultados
    _tdee = tdee;
    _macros = macros;
  }

  /// -------------------------------------------------------------
  /// VISTA PRINCIPAL
  /// -------------------------------------------------------------

  Widget _buildNutritionContent(ThemeData theme) {
    // ------------------------------------------------------------------
    // 1. Cálculo de Metas y Consumido
    // ------------------------------------------------------------------
    // Metas Diarias (del cálculo TDEE)
    final goalCalories = _tdee;
    final goalProtein = _macros['Proteínas'] ?? 0;
    final goalCarbs = _macros['Carbohidratos'] ?? 0;
    final goalFat = _macros['Grasas'] ?? 0;

    // Consumido (sumatoria de todas las entradas del día)
    double consumedCalories = 0;
    double consumedProtein = 0;
    double consumedCarbs = 0;
    double consumedFat = 0;

    for (var entry in _allEntriesForDay) {
      consumedCalories += entry.totalCalories;
      consumedProtein += entry.totalProtein;
      consumedCarbs += entry.totalCarbs;
      consumedFat += entry.totalFat;
    }

    // ------------------------------------------------------------------
    // 2. Construcción de la UI
    // ------------------------------------------------------------------

    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Control de Fecha
          _buildDateSelector(theme),
          const Divider(height: 1, indent: 16, endIndent: 16),
          const SizedBox(height: 16),

          // Metas y Progreso (Barra)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildProgressCard(
              theme,
              goalCalories: goalCalories,
              consumedCalories: consumedCalories,
              goalProtein: goalProtein,
              consumedProtein: consumedProtein,
              goalCarbs: goalCarbs,
              consumedCarbs: consumedCarbs,
              goalFat: goalFat,
              consumedFat: consumedFat,
            ),
          ),

          const SizedBox(height: 24),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('Diario de Comidas', style: theme.textTheme.titleLarge),
          ),
          const Divider(indent: 16, endIndent: 16),

          ...MealType.values.map((type) {
            return _buildMealSection(theme, type);
          }),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildDateSelector(ThemeData theme) {
    final dateFormat = DateFormat('EEEE, d MMMM', 'es_ES');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            onPressed: () {
              setState(
                () => _selectedDate = _selectedDate.subtract(
                  const Duration(days: 1),
                ),
              );
              _listenToMealEntries();
            },
          ),

          GestureDetector(
            onTap: () => _selectDate(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withValues(alpha: 0.1),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                dateFormat.format(_selectedDate),
                style: theme.textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),

          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 20),
            onPressed:
                _selectedDate.day == DateTime.now().day &&
                    _selectedDate.month == DateTime.now().month &&
                    _selectedDate.year == DateTime.now().year
                ? null
                : () {
                    setState(
                      () => _selectedDate = _selectedDate.add(
                        const Duration(days: 1),
                      ),
                    );
                    _listenToMealEntries();
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(
    ThemeData theme, {
    required double goalCalories,
    required double consumedCalories,
    required double goalProtein,
    required double consumedProtein,
    required double goalCarbs,
    required double consumedCarbs,
    required double goalFat,
    required double consumedFat,
  }) {
    final remainingProtein = (goalProtein - consumedProtein).round().clamp(
      0,
      goalProtein.round(),
    );
    final remainingCarbs = (goalCarbs - consumedCarbs).round().clamp(
      0,
      goalCarbs.round(),
    );
    final remainingFat = (goalFat - consumedFat).round().clamp(
      0,
      goalFat.round(),
    );

    final macroRow = Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildMacroProgress(
          theme,
          'Proteínas',
          remainingProtein,
          goalProtein.round(),
          consumedProtein.round(),
          Colors.blue,
        ),
        _buildMacroProgress(
          theme,
          'Carbohidratos',
          remainingCarbs,
          goalCarbs.round(),
          consumedCarbs.round(),
          Colors.green,
        ),
        _buildMacroProgress(
          theme,
          'Grasas',
          remainingFat,
          goalFat.round(),
          consumedFat.round(),
          Colors.red,
        ),
      ],
    );

    return Card(
      elevation: 4,
      color: theme.colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              '${numberFormat.format(consumedCalories.round())} / ${numberFormat.format(goalCalories.round())} calorias',
              style: theme.textTheme.headlineMedium!.copyWith(
                color: consumedCalories <= goalCalories
                    ? theme.colorScheme.primary
                    : Colors.red.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),

            const Divider(height: 24),
            macroRow,
          ],
        ),
      ),
    );
  }

  Widget _buildMacroProgress(
    ThemeData theme,
    String title,
    int remaining,
    int goal,
    int consumed,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          title,
          style: theme.textTheme.bodyLarge!.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${numberFormat.format(consumed)} g / ${numberFormat.format(goal)} g',
          style: theme.textTheme.bodyMedium,
        ),
        Text(
          remaining > 0 ? '$remaining g restantes' : '¡Meta Cumplida!',
          style: theme.textTheme.bodySmall!.copyWith(
            color: remaining == 0
                ? Colors.green
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildMealSection(ThemeData theme, MealType type) {
    final title = type.toString().split('.').last.toUpperCase();
    final entries = _allEntriesForDay
        .where((entry) => entry.mealType == type)
        .toList();
    final totalSectionCalories = entries.fold(
      0.0,
      (sum, entry) => sum + entry.totalCalories,
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 1,
      color: theme.colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text(
                title,
                style: theme.textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              trailing: Text(
                '${numberFormat.format(totalSectionCalories.round())} kcal',
                style: theme.textTheme.titleMedium!.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const Divider(height: 1, indent: 16, endIndent: 16),
            const SizedBox(height: 8),

            // Lista de alimentos consumidos
            if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  top: 8,
                  bottom: 8,
                ),
                child: Text(
                  'Aún no has registrado nada para el ${title.toLowerCase()}.',
                  style: theme.textTheme.bodyMedium!.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),

            ...entries.map((entry) => _buildMealEntryTile(theme, entry)),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add_circle_outline),
                label: Text('Añadir alimento a ${title.toLowerCase()}'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(40),
                  side: BorderSide(
                    color: theme.colorScheme.primary.withValues(alpha: 0.5),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => _openFoodSearch(type),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealEntryTile(ThemeData theme, MealEntry entry) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 8, bottom: 4, top: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
        onTap: null,

        title: Text(
          entry.foodItem.name,
          style: theme.textTheme.bodyLarge!.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '${numberFormat.format(entry.quantity.round())} ${entry.foodItem.unit} | ',
                  style: theme.textTheme.bodyMedium,
                ),
                Icon(
                  Icons.flash_on,
                  size: 14,
                  color: theme.colorScheme.primary,
                ),
                Text(
                  ' ${entry.totalCalories.toStringAsFixed(0)} kcal',
                  style: theme.textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'P:${entry.totalProtein.toStringAsFixed(0)}g',
                  style: TextStyle(color: Colors.blue.shade700, fontSize: 13),
                ),
                const SizedBox(width: 8),
                Text(
                  'C:${entry.totalCarbs.toStringAsFixed(0)}g',
                  style: TextStyle(color: Colors.green.shade700, fontSize: 13),
                ),
                const SizedBox(width: 8),
                Text(
                  'G:${entry.totalFat.toStringAsFixed(0)}g',
                  style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
        dense: true,
      ),
    );
  }

  void _openFoodSearch(MealType mealType) async {
    final selectedFood = await Navigator.of(context).push(
      MaterialPageRoute<FoodItem>(
        builder: (context) => const FoodSearchScreen(),
      ),
    );

    if (selectedFood != null) {
      _showQuantityDialog(selectedFood, mealType);
    }
  }

  void _showQuantityDialog(FoodItem foodItem, MealType mealType) {
    final formKey = GlobalKey<FormState>();

    final theme = Theme.of(context);

    final quantityController = TextEditingController(
      text: foodItem.servingSize.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateInDialog) {
            double currentQuantity =
                double.tryParse(quantityController.text) ??
                foodItem.servingSize;

            final multiplier = currentQuantity / foodItem.servingSize;
            final dynamicCalories = foodItem.calories * multiplier;
            final dynamicProtein = foodItem.protein * multiplier;
            final dynamicCarbs = foodItem.carbs * multiplier;
            final dynamicFat = foodItem.fat * multiplier;

            return AlertDialog(
              title: Text(
                'Añadir ${foodItem.name} a ${mealType.toString().split('.').last.toUpperCase()}',
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Cantidad (${foodItem.unit})',
                          suffixText: foodItem.unit,
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null ||
                              double.tryParse(value) == null ||
                              double.parse(value) <= 0) {
                            return 'Ingrese una cantidad válida.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Información Nutricional (${currentQuantity.toStringAsFixed(0)} ${foodItem.unit}):',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      _buildDynamicMacroRow(
                        theme,
                        dynamicCalories: dynamicCalories,
                        dynamicProtein: dynamicProtein,
                        dynamicCarbs: dynamicCarbs,
                        dynamicFat: dynamicFat,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final quantity = double.parse(quantityController.text);

                      try {
                        await _mealService.addEntry(
                          foodItem: foodItem,
                          quantity: quantity,
                          mealType: mealType,
                          date: _selectedDate,
                        );

                        if (!context.mounted) return;

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Alimento añadido correctamente"),
                          ),
                        );
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Error al añadir: $e")),
                          );
                        }
                      }
                    }
                  },
                  child: const Text('Añadir'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDynamicMacroRow(
    ThemeData theme, {
    required double dynamicCalories,
    required double dynamicProtein,
    required double dynamicCarbs,
    required double dynamicFat,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMacroItem(
          theme,
          'Calorías',
          dynamicCalories,
          'kcal',
          theme.colorScheme.primary,
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildMacroItem(
              theme,
              'P',
              dynamicProtein,
              'g',
              Colors.blue.shade700,
            ),
            _buildMacroItem(
              theme,
              'C',
              dynamicCarbs,
              'g',
              Colors.green.shade700,
            ),
            _buildMacroItem(theme, 'G', dynamicFat, 'g', Colors.red.shade700),
          ],
        ),
      ],
    );
  }

  Widget _buildMacroItem(
    ThemeData theme,
    String label,
    double value,
    String unit,
    Color color,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: theme.textTheme.bodyMedium!.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '${value.toStringAsFixed(1)} $unit',
          style: theme.textTheme.bodyMedium!.copyWith(color: color),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = _auth.currentUser?.uid;
    final theme = Theme.of(context);

    if (userId == null) {
      return const Center(child: Text("Inicia sesión para ver tu nutrición."));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Nutrición',
          style: theme.textTheme.headlineLarge!.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        centerTitle: false,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),

      body: StreamBuilder<AppUser>(
        stream: _userService.getUserData(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final errorMessage =
                snapshot.error?.toString() ?? 'Error desconocido del usuario.';
            return Center(child: Text('Error al cargar datos: $errorMessage'));
          }

          final user = snapshot.data;

          if (user == null ||
              user.peso == null ||
              user.altura == null ||
              user.edad == null ||
              user.sexo == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 60,
                      color: Colors.amber,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Faltan datos de perfil.',
                      style: theme.textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Por favor, completa tu Peso, Altura, Edad y Sexo en la sección de Perfil para calcular tu nutrición.',
                    ),
                  ],
                ),
              ),
            );
          }

          _calculateNutrition(user);

          return _buildNutritionContent(theme);
        },
      ),
    );
  }
}
