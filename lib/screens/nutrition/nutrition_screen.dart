import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Para formatear números
import 'package:nutrimotion/models/user_model.dart';
import 'package:nutrimotion/services/nutrition_calculator.dart';
import 'package:nutrimotion/services/user_service.dart'; // Importar UserService

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  // Inicialización de servicios y auth
  final _userService = UserService();
  final _auth = FirebaseAuth.instance;
  // Formato para mostrar números grandes (ej: 2.000 kcal)
  final numberFormat = NumberFormat('#,##0', 'es_ES');

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

  @override
  void initState() {
    super.initState();
    // No necesitamos llamar a _loadUserData() aquí, el StreamBuilder lo manejará.
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
    // Variables para simplificar la lectura de macros
    final proteinGrams = _macros['Proteínas'] ?? 0;
    final carbGrams = _macros['Carbohidratos'] ?? 0;
    final fatGrams = _macros['Grasas'] ?? 0;

    // Cálculo de porcentajes para la vista compacta
    final totalCalories = _tdee > 0 ? _tdee : 1; // Evitar división por cero
    final proteinKcal =
        proteinGrams *
        (NutritionCalculator.caloriesPerGram['Proteínas'] ?? 4.0);
    final carbKcal =
        carbGrams *
        (NutritionCalculator.caloriesPerGram['Carbohidratos'] ?? 4.0);
    final fatKcal =
        fatGrams * (NutritionCalculator.caloriesPerGram['Grasas'] ?? 9.0);

    final proteinPercent = (proteinKcal / totalCalories) * 100;
    final carbPercent = (carbKcal / totalCalories) * 100;
    final fatPercent = (fatKcal / totalCalories) * 100;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --------------------------------------
          // TÍTULO Y BOTÓN DE EDICIÓN
          // --------------------------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Distribución de Macronutrientes',
                style: theme.textTheme.titleLarge,
              ),
              OutlinedButton.icon(
                onPressed: _showEditDialog,
                icon: const Icon(Icons.settings_outlined, size: 18),
                label: const Text('Editar Parámetros'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 16),

          // --------------------------------------
          // CARD COMPACTO DE MACROS Y CALORÍAS
          // --------------------------------------
          Card(
            color: theme.colorScheme.surfaceContainerHigh,
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fila 1: Calorías Diarias Totales
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Calorías Diarias (TDEE):',
                        style: theme.textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${numberFormat.format(_tdee.round())} kcal',
                        style: theme.textTheme.headlineSmall!.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Fila 2: Distribución de Macros (Gramos y %)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMacroColumn(
                        theme,
                        'Proteínas',
                        proteinGrams,
                        proteinPercent,
                      ),
                      _buildMacroColumn(
                        theme,
                        'Carbohidratos',
                        carbGrams,
                        carbPercent,
                      ),
                      _buildMacroColumn(theme, 'Grasas', fatGrams, fatPercent),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // --------------------------------------
          // Parámetros actuales
          // --------------------------------------
          Text('Parámetros de Cálculo', style: theme.textTheme.titleMedium),
          const Divider(),
          _buildInfoTile(
            theme,
            'Nivel de Actividad',
            _selectedActivityLevel,
            Icons.directions_run,
          ),
          _buildInfoTile(theme, 'Objetivo', _selectedGoal, Icons.track_changes),
          _buildInfoTile(
            theme,
            'Plan Macro',
            _selectedMacroPlan,
            Icons.pie_chart_outline,
          ),
        ],
      ),
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
      appBar: AppBar(
        title: const Text('Mi Calculadora Nutricional'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      // 📝 StreamBuilder escucha los cambios en los datos del usuario en tiempo real
      body: StreamBuilder<AppUser>(
        stream: _userService.getUserData(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error al cargar datos: ${snapshot.error}'),
            );
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

          // 2. ⭐️ Si los datos están completos:
          // A. Ejecutar la lógica de cálculo y actualizar las variables de estado locales (sin setState)
          _calculateNutrition(user);

          // B. Devolver la interfaz redibujada con los nuevos valores
          return _buildNutritionContent(theme);
        },
      ),
    );
  }
}
