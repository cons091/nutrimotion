import 'food_entry.dart';
import 'nutrition_goals.dart';

/// Agrega la lista de alimentos de un día y la compara con los objetivos.
///
/// Centraliza toda la aritmética del diario (totales consumidos, restante y
/// fracciones de progreso) para que la UI solo se encargue de dibujar.
class NutritionSummary {
  final List<FoodEntry> entries;
  final NutritionGoals? goals;

  final double consumedCalories;
  final double consumedProtein;
  final double consumedCarbs;
  final double consumedFat;

  NutritionSummary._({
    required this.entries,
    required this.goals,
    required this.consumedCalories,
    required this.consumedProtein,
    required this.consumedCarbs,
    required this.consumedFat,
  });

  /// Construye el resumen sumando todos los alimentos.
  factory NutritionSummary.from(List<FoodEntry> entries, NutritionGoals? goals) {
    double cal = 0, pro = 0, carb = 0, fat = 0;
    for (final e in entries) {
      cal += e.calories;
      pro += e.protein;
      carb += e.carbs;
      fat += e.fat;
    }
    return NutritionSummary._(
      entries: entries,
      goals: goals,
      consumedCalories: cal,
      consumedProtein: pro,
      consumedCarbs: carb,
      consumedFat: fat,
    );
  }

  // --- Restante frente al objetivo (puede ser negativo si hay exceso) ---
  double get remainingCalories =>
      goals == null ? 0 : goals!.calories - consumedCalories;
  double get remainingProtein =>
      goals == null ? 0 : goals!.protein - consumedProtein;
  double get remainingCarbs => goals == null ? 0 : goals!.carbs - consumedCarbs;
  double get remainingFat => goals == null ? 0 : goals!.fat - consumedFat;

  // --- Fracciones de progreso 0.0-1.0 (para barras/anillos) ---
  double get caloriesProgress => _fraction(consumedCalories, goals?.calories);
  double get proteinProgress => _fraction(consumedProtein, goals?.protein);
  double get carbsProgress => _fraction(consumedCarbs, goals?.carbs);
  double get fatProgress => _fraction(consumedFat, goals?.fat);

  /// True si se superó la meta calórica del día.
  bool get isOverCalories =>
      goals != null && consumedCalories > goals!.calories;

  /// Alimentos filtrados por tipo de comida.
  List<FoodEntry> entriesFor(MealType meal) =>
      entries.where((e) => e.mealType == meal).toList();

  /// Calorías totales de una comida concreta.
  double caloriesFor(MealType meal) => entriesFor(
    meal,
  ).fold<double>(0, (sum, e) => sum + e.calories);

  static double _fraction(double value, double? target) {
    if (target == null || target <= 0) return 0;
    final f = value / target;
    if (f < 0) return 0;
    if (f > 1) return 1;
    return f;
  }
}
