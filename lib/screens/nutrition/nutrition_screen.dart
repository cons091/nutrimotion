// lib/screens/food/nutrition_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:nutrimotion/screens/food/food_search_screen.dart';
import 'package:nutrimotion/services/nutrition_calculator.dart';
import 'package:nutrimotion/services/user_service.dart';
import 'package:nutrimotion/services/food_service.dart';
import 'package:nutrimotion/services/meal_service.dart';
import 'package:nutrimotion/models/meal_entry_model.dart';
import 'package:nutrimotion/models/food_model.dart';
import 'package:nutrimotion/models/user_model.dart';
import 'dart:async'; // Importación necesaria para StreamSubscription

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  // Inicialización de servicios y auth
  final _userService = UserService();
  final _auth = FirebaseAuth.instance;
  late final NumberFormat numberFormat;

  // Nuevos servicios de Comida
  final MealService _mealService = MealService();
  final _foodService = FoodService();

  // Variables de Resultado (Inicializadas a 0 y vacío)
  double _tdee = 0.0;
  Map<String, double> _macros = {};

  // Variables de Parámetros Seleccionables por el Usuario (Estado de la UI)
  String _selectedActivityLevel = NutritionCalculator.activityLevels.keys.first;
  String _selectedGoal = NutritionCalculator.goalAdjustments.keys.firstWhere(
    (k) => k == 'Mantener peso', // Valor inicial seguro
    orElse: () => NutritionCalculator.goalAdjustments.keys.first,
  );
  String _selectedMacroPlan = NutritionCalculator.macroPlans.keys.first;

  // Variable para almacenar los datos del usuario actualizados
  AppUser? _currentUser;

  // Variables del Diario
  DateTime _selectedDate =
      DateTime.now(); // Para el control de la fecha del diario

  // Lista de todas las entradas del día actual y el suscriptor del stream
  List<MealEntry> _allEntriesForDay = [];
  StreamSubscription? _mealSubscription;

  @override
  void initState() {
    super.initState();
    numberFormat = NumberFormat(
      '#,##0',
      'es_ES',
    ); // Formato de miles (ej: 1.650)
    _listenToMealEntries(); // 🔄 Empezar a escuchar el Stream de Firebase
  }

  @override
  void dispose() {
    _mealSubscription
        ?.cancel(); // 🚫 Cancelar la suscripción al cerrar la pantalla
    super.dispose();
  }

  // 📅 Método para escuchar el Stream de entradas del día (reemplaza _loadMealEntries)
  void _listenToMealEntries() {
    // Cancelar la escucha anterior si existe
    _mealSubscription?.cancel();

    // 1. Obtener el Stream de Firebase desde el servicio
    final stream = _mealService.getEntriesForDate(_selectedDate);

    // 2. Suscribirse al Stream
    _mealSubscription = stream.listen(
      (entries) {
        // 3. Cuando llegan nuevos datos, actualizamos la lista y la UI
        if (mounted) {
          setState(() {
            _allEntriesForDay = entries;
          });
        }
      },
      onError: (e) {
        // Manejar errores de Firebase
        if (mounted) {
          // 🛑 CORRECCIÓN CLAVE: Usamos .toString() y un fallback
          // para garantizar que la Snackbar reciba un String no nulo.
          final errorMessage =
              e?.toString() ?? 'Error desconocido al cargar el diario.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al cargar diario: $errorMessage')),
          );
        }
      },
    );
  }

  // 📅 Método para cambiar la fecha
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
      _listenToMealEntries(); // 🔄 Reiniciar la escucha para la nueva fecha
    }
  }

  // Muestra el diálogo para ingresar la nueva cantidad (No necesita cambios funcionales aquí)
  Future<void> _openEditDialog(MealEntry entry) async {
    final TextEditingController quantityController = TextEditingController(
      // Inicializar con la cantidad actual
      text: entry.quantity.toStringAsFixed(0),
    );

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);

        return AlertDialog(
          title: Text('Editar: ${entry.foodItem.name}'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                // Muestra la unidad actual
                Text('Unidad: ${entry.foodItem.unit}'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Nueva Cantidad',
                    border: const OutlineInputBorder(),
                    suffixText:
                        entry.foodItem.unit, // Muestra la unidad en el campo
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            FilledButton(
              child: const Text('Guardar'),
              onPressed: () {
                final newQuantity = double.tryParse(quantityController.text);
                if (newQuantity != null && newQuantity > 0) {
                  // Llama a la función de actualización y cierra el diálogo
                  _editEntry(entry, newQuantity);
                  Navigator.of(context).pop();
                } else {
                  // Muestra un error si la entrada no es válida
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Por favor, ingrese una cantidad válida (> 0).',
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Llama al servicio para actualizar la entrada en la base de datos (AHORA ASÍNCRONO)
  Future<void> _editEntry(MealEntry entry, double newQuantity) async {
    if (newQuantity <= 0) {
      // Si la cantidad es 0 o menos, eliminar la entrada
      _removeEntry(entry.id);
      return;
    }

    try {
      // 🚀 Llamada asíncrona al servicio
      await _mealService.updateMealEntry(entry.id, newQuantity: newQuantity);

      // ❌ Ya NO necesitamos llamar a _loadMealEntries, el Stream se encarga de recargar la UI
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entrada actualizada correctamente.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar la cantidad: $e')),
      );
    }
  }

  // 🗑️ Método para eliminar (AHORA ASÍNCRONO)
  Future<void> _removeEntry(String entryId) async {
    try {
      // 🚀 Llamada asíncrona al servicio
      await _mealService.removeEntry(entryId);
      // ❌ Ya NO necesitamos llamar a _loadMealEntries
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entrada eliminada correctamente.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar la entrada: $e')),
      );
    }
  }

  /// -------------------------------------------------------------
  /// LÓGICA DE CÁLCULO
  /// -------------------------------------------------------------

  /// 1. Carga los parámetros del usuario, ejecuta los cálculos y actualiza el estado.
  void _calculateNutrition(AppUser user) {
    _currentUser = user; // Guardar el usuario actual

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
  /// LÓGICA DE PERSISTENCIA
  /// -------------------------------------------------------------

  /// Guarda las preferencias de Actividad y Objetivo en Firestore.
  Future<void> _saveUserPreferences({
    required String activityLevel,
    required String goal,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _userService.updateUserData(userId, {
        'actividad': activityLevel,
        'objetivo': goal,
      });
      // La UI se actualizará automáticamente a través del StreamBuilder
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar preferencias: $e')),
        );
      }
    }
  }

  /// -------------------------------------------------------------
  /// WIDGETS AUXILIARES (Dropdowns y Info)
  /// -------------------------------------------------------------

  /// Dropdown simple para listas (Objetivo Calórico, Plan Macro)
  Widget _buildSimpleDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: items.contains(value)
          ? value
          : items.first, // Manejo seguro de valor inicial
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.fitness_center),
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16.0,
          horizontal: 12.0,
        ),
      ),
      items: items.map((String val) {
        return DropdownMenuItem<String>(value: val, child: Text(val));
      }).toList(),
      onChanged: onChanged,
    );
  }

  /// Dropdown para niveles de actividad con descripción (para el Diálogo)
  Widget _buildDropdownWithInfo({
    required String label,
    required String value,
    required Map<String, Map<String, dynamic>> itemsMap,
    required String infoTooltip,
    required ValueChanged<String?> onChanged,
  }) {
    // Usamos las claves del mapa para el dropdown
    final items = itemsMap.keys.toList();

    // Valor por defecto seguro
    final safeValue = items.contains(value) ? value : items.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(width: 8),
            Tooltip(
              message: infoTooltip,
              child: Icon(
                Icons.info_outline,
                size: 18,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: safeValue,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(
              vertical: 16.0,
              horizontal: 12.0,
            ),
          ),
          items: items.map((String key) {
            return DropdownMenuItem<String>(value: key, child: Text(key));
          }).toList(),
          onChanged: onChanged,
        ),
        // Descripción actual del nivel de actividad
        Padding(
          padding: const EdgeInsets.only(top: 8.0, left: 4.0),
          child: Text(
            itemsMap[safeValue]?['description'] ?? '',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  /// Columna para mostrar gramos y porcentaje de un macronutriente
  Widget _buildMacroColumn(
    ThemeData theme,
    String title,
    double grams,
    double percent,
  ) {
    Color color;
    switch (title) {
      case 'Proteínas':
        color = Colors.blue.shade700;
        break;
      case 'Carbohidratos':
        color = Colors.green.shade700;
        break;
      case 'Grasas':
        color = Colors.red.shade700;
        break;
      default:
        color = theme.colorScheme.onSurface;
    }

    return Column(
      children: [
        Text(
          title,
          style: theme.textTheme.bodyLarge!.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${numberFormat.format(grams.round())} g',
          style: theme.textTheme.titleMedium,
        ),
        Text(
          '(${numberFormat.format(percent.round())}%)',
          style: theme.textTheme.bodyMedium!.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  /// Tile para mostrar un parámetro actual (Actividad, Objetivo, Plan)
  Widget _buildInfoTile(
    ThemeData theme,
    String title,
    String value,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.bodyLarge!.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Text(value, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }

  /// -------------------------------------------------------------
  /// DIÁLOGO DE EDICIÓN DE PARÁMETROS
  /// -------------------------------------------------------------

  /// Muestra un diálogo modal para editar los parámetros de cálculo.
  Future<void> _showEditDialog() async {
    // Usamos variables locales para mantener el estado del diálogo
    String tempActivityLevel = _selectedActivityLevel;
    String tempGoal = _selectedGoal;
    String tempMacroPlan = _selectedMacroPlan;

    // Tooltip para describir los niveles de actividad
    const activityTooltip = '''
Niveles de Actividad:
- Sedentario: Poco o ningún ejercicio.
- Ligera: Ejercicio 1-3 veces por semana.
- Moderada: Ejercicio 4-5 veces por semana.
- Alta: Ejercicio diario o intenso 3-4 veces por semana.
- Muy Activo: Ejercicio intenso 6-7 veces por semana.
- Extra Activo: Ejercicio muy intenso a diario, o trabajo físico.
''';

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateInDialog) {
            return AlertDialog(
              title: const Text('Editar Parámetros de Cálculo'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Dropdown: Nivel de Actividad
                    _buildDropdownWithInfo(
                      label: 'Nivel de Actividad',
                      value: tempActivityLevel,
                      itemsMap: NutritionCalculator.activityLevels,
                      infoTooltip: activityTooltip,
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setStateInDialog(() => tempActivityLevel = newValue);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Dropdown: Objetivo Calórico
                    _buildSimpleDropdown(
                      label: 'Objetivo Calórico',
                      value: tempGoal,
                      items: NutritionCalculator.goalAdjustments.keys.toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setStateInDialog(() => tempGoal = newValue);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Dropdown: Plan de Macronutrientes
                    _buildSimpleDropdown(
                      label: 'Plan de Macronutrientes',
                      value: tempMacroPlan,
                      items: NutritionCalculator.macroPlans.keys.toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setStateInDialog(() => tempMacroPlan = newValue);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // 1. Guardar preferencias en Firebase (Actividad y Objetivo)
                    _saveUserPreferences(
                      activityLevel: tempActivityLevel,
                      goal: tempGoal,
                    );

                    // 2. Actualizar el estado de la pantalla principal
                    setState(() {
                      // Estos 3 estados se actualizan aquí
                      _selectedActivityLevel = tempActivityLevel;
                      _selectedGoal = tempGoal;
                      _selectedMacroPlan = tempMacroPlan;

                      // Forzar el recálculo (necesario solo para el plan macro, TDEE se actualiza por stream)
                      if (_currentUser != null) {
                        _calculateNutrition(_currentUser!);
                      }
                    });

                    Navigator.pop(context);
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
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

    // 🚀 Iterar sobre la nueva lista de estado _allEntriesForDay
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
          // 📅 Control de Fecha
          _buildDateSelector(theme),
          const Divider(height: 1, indent: 16, endIndent: 16),
          const SizedBox(height: 16),

          // 🎯 Metas y Progreso (Barra)
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

          // 📝 Diario de Comidas
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('Diario de Comidas', style: theme.textTheme.titleLarge),
          ),
          const Divider(indent: 16, endIndent: 16),

          // Listado de Secciones de Comida
          ...MealType.values.map((type) {
            return _buildMealSection(theme, type);
          }).toList(),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildDateSelector(ThemeData theme) {
    final dateFormat = DateFormat('EEEE, d MMMM', 'es_ES');

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 8.0,
        vertical: 8.0,
      ), // Ajustamos padding
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Botón Anterior
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            onPressed: () {
              setState(
                () => _selectedDate = _selectedDate.subtract(
                  const Duration(days: 1),
                ),
              );
              _listenToMealEntries(); // 🔄 Usar el nuevo método de escucha
            },
          ),

          // 📅 Indicador de Fecha (más prominente y clickeable)
          GestureDetector(
            onTap: () => _selectDate(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme
                    .colorScheme
                    .primaryContainer, // Un fondo sutil del color primario
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withOpacity(0.1),
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

          // Botón Siguiente
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 20),
            // Desactivar si la fecha es hoy o futura (opcional, pero útil)
            onPressed:
                _selectedDate.day == DateTime.now().day &&
                    _selectedDate.month == DateTime.now().month &&
                    _selectedDate.year == DateTime.now().year
                ? null // Desactivar si es hoy
                : () {
                    setState(
                      () => _selectedDate = _selectedDate.add(
                        const Duration(days: 1),
                      ),
                    );
                    _listenToMealEntries(); // 🔄 Usar el nuevo método de escucha
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
    // Las variables restantes todavía se necesitan para el progreso de los macros.
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

    // Fila para mostrar Macros (Restante vs Consumido)
    final macroRow = Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        // Proteínas
        _buildMacroProgress(
          theme,
          'Proteínas',
          remainingProtein,
          goalProtein.round(),
          consumedProtein.round(),
          Colors.blue,
        ),
        // Carbohidratos
        _buildMacroProgress(
          theme,
          'Carbohidratos',
          remainingCarbs,
          goalCarbs.round(),
          consumedCarbs.round(),
          Colors.green,
        ),
        // Grasas
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
            // 🚀 NUEVA MÉTRICA PRINCIPAL (Minimalista)
            Text(
              // 1. Formato: 0/2.125 calorias
              // 2. Unidad: 'calorias'
              '${numberFormat.format(consumedCalories.round())} / ${numberFormat.format(goalCalories.round())} calorias',
              style: theme.textTheme.headlineMedium!.copyWith(
                // Usamos el color para indicar si la meta fue superada o no
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

  // Widget auxiliar para cada Macro
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
        // Formato Consumido / Meta
        Text(
          '${numberFormat.format(consumed)} g / ${numberFormat.format(goal)} g',
          style: theme.textTheme.bodyMedium,
        ),
        // Muestra lo restante
        Text(
          remaining > 0 ? '${remaining} g restantes' : '¡Meta Cumplida!',
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

    // 🚀 Filtramos las entradas para este tipo de comida de la lista general
    final entries = _allEntriesForDay
        .where((entry) => entry.mealType == type)
        .toList();

    // final entries = _currentDayEntries[type] ?? []; // ❌ Eliminamos
    final totalSectionCalories = entries.fold(
      0.0,
      (sum, entry) => sum + entry.totalCalories,
    );

    return Card(
      // Estructura de Tarjeta: Elegante separación visual
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation:
          1, // ⬅️ Reducimos la elevación para un look más plano/minimalista
      color: theme
          .colorScheme
          .surfaceContainer, // Fondo sutilmente diferente al Scaffold
      child: Padding(
        padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título de la Sección y Resumen de Calorías
            ListTile(
              title: Text(
                title,
                // Estilo minimalista: Fuerte pero integrado
                style: theme.textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme
                      .colorScheme
                      .onSurface, // Color de texto normal, no primario
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

            ...entries
                .map((entry) => _buildMealEntryTile(theme, entry))
                .toList(),

            // ➕ Botón para Añadir Comida
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
                    color: theme.colorScheme.primary.withOpacity(0.5),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      8,
                    ), // Bordes menos redondos para elegancia
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
    Widget _buildActionButtons() {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ✏️ Botón de Editar Cantidad (Abre el diálogo)
          IconButton(
            icon: Icon(
              Icons.edit_outlined,
              size: 22,
              color: theme.colorScheme.primary,
            ),
            onPressed: () => _openEditDialog(entry),
          ),
          // 🗑️ Botón de Eliminar
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 22, color: Colors.red),
            onPressed: () => _removeEntry(entry.id),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 8, bottom: 4, top: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),

        // ❌ QUITAMOS onTap: Ya no se edita tocando toda la sección
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
            // 1. Cantidad y Calorías
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
            // 2. Macros (P/C/G)
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

        // 🚀 CAMBIO CLAVE: Reemplazamos el trailing con la fila de botones
        trailing: _buildActionButtons(),

        dense: true,
      ),
    );
  }

  /// 🍽️ Abre la pantalla de búsqueda de alimentos y espera el resultado.
  void _openFoodSearch(MealType mealType) async {
    // 💡 NOTA: Asume que tienes definida la clase FoodSearchScreen
    final selectedFood = await Navigator.of(context).push(
      MaterialPageRoute<FoodItem>(
        builder: (context) => const FoodSearchScreen(),
      ),
    );

    // Si el usuario seleccionó un alimento (futuro)
    if (selectedFood != null) {
      // ⭐️ Muestra el diálogo para ingresar la cantidad
      _showQuantityDialog(selectedFood, mealType);
    }
  }

  /// 🍚 Muestra el diálogo para ingresar la cantidad consumida. (AHORA ASÍNCRONO)
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
            // ⭐️ CLAVE 1: Inicializamos currentQuantity con el valor actual del controlador.
            double currentQuantity =
                double.tryParse(quantityController.text) ?? 0.0;

            // Función para calcular los macros basados en la cantidad
            void _updateCalculations(String? value) {
              double newQuantity = double.tryParse(value ?? '0') ?? 0.0;

              // ⭐️ CLAVE 2: Actualizar el estado local del diálogo con el nuevo valor
              setStateInDialog(() {
                currentQuantity = newQuantity;
              });
            }

            // Re-cálculo basado en la cantidad actual (currentQuantity)
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
                      // Campo de Cantidad (Gramaje)
                      TextFormField(
                        controller:
                            quantityController, // ⬅️ Usamos el controlador definido arriba
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Cantidad (${foodItem.unit})',
                          suffixText: foodItem.unit,
                        ),
                        validator: (value) {
                          if (value == null ||
                              double.tryParse(value) == null ||
                              double.parse(value) <= 0) {
                            return 'Ingrese una cantidad válida.';
                          }
                          return null;
                        },
                        // 🚀 CLAVE 3: El onChanged ejecuta el recálculo
                        onChanged: _updateCalculations,
                      ),
                      const SizedBox(height: 16),
                      // ... (Display de Información Nutricional Dinámica)
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
                    // 🚀 Hacemos el callback ASÍNCRONO
                    // ⭐️ CLAVE 4: Ejecutar validate (actualiza el estado interno del form)
                    if (formKey.currentState!.validate()) {
                      // ⭐️ CLAVE 5: Capturar el valor FINAL del controlador al guardar
                      final quantity = double.parse(quantityController.text);

                      // 🛑 CLAVE 6: Añadir el try-catch para manejar el error de Firebase
                      try {
                        await _mealService.addEntry(
                          foodItem: foodItem,
                          quantity: quantity, // ⬅️ Usa la cantidad capturada
                          mealType: mealType,
                          date: _selectedDate,
                        );

                        // Éxito: Cerrar diálogo y notificar
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Comida añadida exitosamente.'),
                          ),
                        );
                        // El Stream de Firebase actualizará automáticamente la lista.
                      } catch (e) {
                        // Fracaso: Notificar y cerrar diálogo si no está cerrado
                        if (Navigator.of(context).canPop()) {
                          Navigator.pop(context);
                        }
                        // Usamos e.toString() para asegurar que no se pase un objeto null o complejo.
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Error al añadir comida: ${e.toString()}',
                            ),
                          ),
                        );
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

  // 📦 Nuevo Widget Auxiliar para mostrar la Fila de Macros Dinámicos
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

  // Widget auxiliar para cada ítem de macro
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
        // ✅ Aquí la variable theme ya está definida
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

  /// -------------------------------------------------------------
  /// WIDGET PRINCIPAL (StreamBuilder)
  /// -------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final userId = _auth.currentUser?.uid;
    final theme = Theme.of(context);

    if (userId == null) {
      return const Center(child: Text("Inicia sesión para ver tu nutrición."));
    }

    return Scaffold(
      // 🚀 CAMBIO CLAVE: AppBar simple, plana y con título limpio
      appBar: AppBar(
        // Título: "Nutrición"
        title: Text(
          'Nutrición',
          style: theme.textTheme.headlineLarge!.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        centerTitle: false,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation:
            0, // ⬅️ Asegura que no hay sombra ni "sobreposición" al hacer scroll
      ),

      // 📝 StreamBuilder escucha los cambios en los datos del usuario en tiempo real
      body: StreamBuilder<AppUser>(
        stream: _userService.getUserData(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            // 🛑 CORRECCIÓN DE SEGURIDAD (Si el error viene del stream de usuario)
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
