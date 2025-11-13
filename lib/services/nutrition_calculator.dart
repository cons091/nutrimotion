// lib/services/nutrition_calculator.dart

class NutritionCalculator {
  // Constantes de Calorías por Gramo
  static const double proteinKcalPerGram = 4.0;
  static const double carbsKcalPerGram = 4.0;
  static const double fatKcalPerGram = 9.0;

  // Definición de planes de Macronutrientes (Porcentajes)
  // En lib/services/nutrition_calculator.dart

  // Definición de planes de Macronutrientes (Porcentajes)
  static final Map<String, Map<String, double>> macroPlans = {
    // Usamos los nombres completos y el valor en porcentaje (ej: 25.0, no 0.25)
    'Mantenimiento Balanceado': {
      'Proteínas': 25.0, // Antes 'protein': 0.25
      'Carbohidratos': 50.0, // Antes 'carbs': 0.50
      'Grasas': 25.0, // Antes 'fat': 0.25
    },
    'Pérdida de Peso Alto en Proteína': {
      'Proteínas': 35.0,
      'Carbohidratos': 40.0,
      'Grasas': 25.0,
    },
    'Ganancia Muscular Bajo en Grasa': {
      'Proteínas': 30.0,
      'Carbohidratos': 55.0,
      'Grasas': 15.0,
    },
  };
  static const Map<String, double> caloriesPerGram = {
    'Proteínas': 4.0,
    'Carbohidratos': 4.0,
    'Grasas': 9.0,
  };
  // Factores de Actividad (Nivel de Actividad)
  static final Map<String, Map<String, dynamic>> activityLevels = {
    'Sedentario': {
      'factor': 1.2,
      'description': 'Poco o ningún ejercicio.',
      'detail': 'Poco o ningún ejercicio.',
    },
    'Actividad Ligera': {
      'factor': 1.375,
      'description': 'Ejercicio 1-3 veces por semana.',
      'detail':
          'Ejercicio: 15-30 minutos de actividad con ritmo cardíaco elevado.',
    },
    'Actividad Moderada': {
      'factor': 1.55,
      'description': 'Ejercicio 4-5 veces por semana.',
      'detail':
          'Ejercicio: 15-30 minutos de actividad con ritmo cardíaco elevado.',
    },
    'Actividad Alta': {
      'factor': 1.725,
      'description':
          'Ejercicio diario o ejercicio intenso 3-4 veces por semana.',
      'detail':
          'Ejercicio Intenso: 45-120 minutos de actividad con ritmo cardíaco elevado.',
    },
    'Muy Activo': {
      'factor':
          1.9, // Usaremos 1.9 para Muy Activo (similar a extra activo en algunas calculadoras)
      'description': 'Ejercicio intenso 6-7 veces por semana.',
      'detail':
          'Ejercicio Intenso: 45-120 minutos de actividad con ritmo cardíaco elevado.',
    },
    'Extra Activo': {
      'factor': 2.0, // Factor más alto, o 1.9 si lo agrupas con 'Muy Activo'
      'description': 'Ejercicio muy intenso a diario, o trabajo físico.',
      'detail':
          'Ejercicio Muy Intenso: 2+ horas de actividad con ritmo cardíaco elevado.',
    },
  };

  // Ajustes de Objetivo (Calorías a sumar/restar)
  static final Map<String, int> goalAdjustments = {
    'Mantener peso': 0,

    // Pérdida de Peso (Déficit)
    'Pérdida leve (0.25 kg/sem)': -250, // Déficit diario de 250 kcal
    'Pérdida moderada (0.5 kg/sem)': -500, // Déficit diario de 500 kcal
    'Pérdida extrema (1.0 kg/sem)': -1000, // Déficit diario de 1000 kcal
    // Ganancia de Peso (Superávit)
    'Ganancia leve (0.25 kg/sem)': 250, // Superávit diario de 250 kcal
    'Ganancia moderada (0.5 kg/sem)': 500, // Superávit diario de 500 kcal
    'Ganancia extrema (1.0 kg/sem)': 1000, // Superávit diario de 1000 kcal
  };

  /// 1A. Calcula la Tasa Metabólica Basal (TMB) usando la Ecuación Mifflin-St Jeor
  static double calculateBMR({
    required double weightKg,
    required double heightCm,
    required int age,
    required String gender,
  }) {
    double bmr;
    if (gender.toLowerCase() == 'mujer') {
      // TMB Mujer = (10 x Peso) + (6.25 x Altura) - (5 x Edad) - 161
      bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161;
    } else {
      // TMB Hombre = (10 x Peso) + (6.25 x Altura) - (5 x Edad) + 5
      bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5;
    }
    return bmr;
  }

  /// 1B. Calcula las Calorías Diarias Totales (TDEE ajustado por objetivo)
  static double calculateTDEE({
    required double bmr,
    required String activityLevel,
    required String goal,
  }) {
    // 1. Obtener Factor de Actividad
    final activityFactor = activityLevels[activityLevel]?['factor'] ?? 1.2;

    // TDEE Inicial = TMB * Factor de Actividad
    final tdeeInitial = bmr * activityFactor;

    // 2. Obtener Ajuste por Objetivo
    final goalAdjustment = goalAdjustments[goal] ?? 0;

    // TDEE Ajustado = TDEE Inicial + Ajuste
    final tdeeAdjusted = tdeeInitial + goalAdjustment;

    return tdeeAdjusted.clamp(1200, double.infinity);
  }

  /// 2. Distribuye las calorías totales en gramos de macronutrientes
  static Map<String, double> calculateMacros({
    required double totalCalories,
    required String planName,
  }) {
    final plan = macroPlans[planName];
    if (plan == null) return {};

    final Map<String, double> macros = {};

    // 1. Calcular calorías objetivo por macro (usando el plan %)
    final proteinCalories = totalCalories * (plan['Proteínas']! / 100);
    final carbCalories = totalCalories * (plan['Carbohidratos']! / 100);
    final fatCalories = totalCalories * (plan['Grasas']! / 100);

    // 2. Convertir calorías a gramos (usando la nueva constante caloriesPerGram)
    macros['Proteínas'] =
        proteinCalories / (caloriesPerGram['Proteínas'] ?? 4.0);
    macros['Carbohidratos'] =
        carbCalories / (caloriesPerGram['Carbohidratos'] ?? 4.0);
    macros['Grasas'] = fatCalories / (caloriesPerGram['Grasas'] ?? 9.0);

    return macros;
  }
}
