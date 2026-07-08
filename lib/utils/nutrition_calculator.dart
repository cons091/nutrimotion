import '../models/user_model.dart';
import '../models/nutrition_goals.dart';

/// Lógica pura de cálculo nutricional.
///
/// Convierte el perfil del usuario ([AppUser]) en objetivos diarios de
/// calorías y macronutrientes usando ecuaciones estándar de nutrición:
///
/// 1. **Metabolismo basal (BMR)** con la fórmula de *Mifflin-St Jeor*, la más
///    precisa para población general.
/// 2. **Gasto energético total (TDEE)** = BMR × factor de actividad.
/// 3. **Ajuste por objetivo** (déficit / mantenimiento / recomposición /
///    superávit).
/// 4. **Reparto de macros**: proteína en función del peso corporal, grasa como
///    porcentaje de las calorías y carbohidratos con el resto.
///
/// No depende de Flutter ni de Firebase, por lo que es fácil de testear.
class NutritionCalculator {
  const NutritionCalculator._();

  // --- Factores de actividad (multiplicadores del BMR) ---
  // Las claves coinciden con las opciones del registro/perfil.
  static const Map<String, double> _activityFactors = {
    'sedentario': 1.2,
    'ligero': 1.375,
    'moderado': 1.55,
    'alto': 1.725,
    'muy alto': 1.9,
  };

  static const double _defaultActivityFactor = 1.2;

  // --- Ajuste calórico por objetivo (multiplicador del TDEE) ---
  static const Map<String, double> _goalFactors = {
    'deficit': 0.80, // -20% para perder grasa
    'mantenimiento': 1.00,
    'recomposicion': 0.95, // ligero déficit con proteína alta
    'superavit': 1.10, // +10% para ganar masa
  };

  // --- Proteína objetivo en g por kg de peso corporal, según objetivo ---
  static const Map<String, double> _proteinPerKg = {
    'deficit': 2.0, // más proteína para preservar músculo en déficit
    'mantenimiento': 1.8,
    'recomposicion': 2.2,
    'superavit': 1.8,
  };

  /// Porcentaje de las calorías totales que provienen de la grasa.
  static const double _fatCaloriePercent = 0.25;

  /// Calorías mínimas de seguridad para no devolver metas peligrosamente bajas.
  static const double _minCalories = 1200;

  /// Indica si el perfil tiene los datos mínimos para calcular metas.
  static bool hasRequiredData(AppUser? user) {
    if (user == null) return false;
    return user.peso != null &&
        user.peso! > 0 &&
        user.altura != null &&
        user.altura! > 0 &&
        user.edad != null &&
        user.edad! > 0;
  }

  /// Calcula los objetivos nutricionales diarios del [user].
  ///
  /// Devuelve `null` si faltan datos del perfil (peso, altura o edad).
  static NutritionGoals? forUser(AppUser? user) {
    if (!hasRequiredData(user)) return null;

    final peso = user!.peso!;
    final altura = user.altura!;
    final edad = user.edad!;

    final bmr = _basalMetabolicRate(
      weightKg: peso,
      heightCm: altura,
      ageYears: edad,
      sexo: user.sexo,
    );

    final tdee = bmr * _activityFactor(user.actividad);

    final goalKey = _normalize(user.objetivo);
    final calories = _clampCalories(tdee * (_goalFactors[goalKey] ?? 1.0));

    // Proteína a partir del peso corporal.
    final protein = peso * (_proteinPerKg[goalKey] ?? 1.8);

    // Grasa como % de las calorías.
    final fat = (calories * _fatCaloriePercent) / 9;

    // Carbohidratos con las calorías restantes (nunca negativos).
    final remainingCalories = calories - (protein * 4) - (fat * 9);
    final carbs = remainingCalories > 0 ? remainingCalories / 4 : 0.0;

    return NutritionGoals(
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      bmr: bmr,
      maintenanceCalories: tdee,
    );
  }

  /// Metabolismo basal (Mifflin-St Jeor).
  ///
  /// Hombre: 10·peso + 6.25·altura − 5·edad + 5
  /// Mujer:  10·peso + 6.25·altura − 5·edad − 161
  static double _basalMetabolicRate({
    required double weightKg,
    required double heightCm,
    required int ageYears,
    required String? sexo,
  }) {
    final base = (10 * weightKg) + (6.25 * heightCm) - (5 * ageYears);
    final esHombre = _normalize(sexo) == 'hombre';
    return base + (esHombre ? 5 : -161);
  }

  /// Multiplicador de actividad tolerante a mayúsculas/acentos.
  static double _activityFactor(String? actividad) {
    return _activityFactors[_normalize(actividad)] ?? _defaultActivityFactor;
  }

  static double _clampCalories(double calories) {
    return calories < _minCalories ? _minCalories : calories;
  }

  /// Normaliza un string: minúsculas, sin acentos y sin espacios sobrantes.
  /// Así "Déficit", "deficit" o "DÉFICIT " se tratan igual.
  static String _normalize(String? value) {
    if (value == null) return '';
    final s = value.trim().toLowerCase();
    const withAccents = 'áàäâéèëêíìïîóòöôúùüû';
    const without = 'aaaaeeeeiiiioooouuuu';
    final buffer = StringBuffer();
    for (final rune in s.runes) {
      final ch = String.fromCharCode(rune);
      final idx = withAccents.indexOf(ch);
      buffer.write(idx >= 0 ? without[idx] : ch);
    }
    return buffer.toString();
  }
}
