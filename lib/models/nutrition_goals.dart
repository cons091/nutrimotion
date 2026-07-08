/// Objetivos nutricionales diarios calculados a partir del perfil del usuario.
///
/// Todos los valores están en unidades "por día":
/// - [calories] en kilocalorías (kcal)
/// - [protein], [carbs] y [fat] en gramos (g)
///
/// Es un objeto de solo lectura: se genera desde [NutritionCalculator] y
/// representa la meta contra la que se compara lo consumido.
class NutritionGoals {
  /// Meta calórica diaria (kcal).
  final double calories;

  /// Meta de proteína diaria (g).
  final double protein;

  /// Meta de carbohidratos diaria (g).
  final double carbs;

  /// Meta de grasa diaria (g).
  final double fat;

  /// Metabolismo basal estimado (kcal), útil para mostrar el desglose.
  final double bmr;

  /// Gasto energético total diario / TDEE (kcal) antes de ajustar por objetivo.
  final double maintenanceCalories;

  const NutritionGoals({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.bmr,
    required this.maintenanceCalories,
  });

  /// Calorías aportadas por cada macronutriente (Atwater: 4/4/9 kcal por g).
  double get proteinCalories => protein * 4;
  double get carbsCalories => carbs * 4;
  double get fatCalories => fat * 9;

  /// Reparto porcentual de calorías por macro (0-100), útil para gráficos.
  double get proteinPercent =>
      calories <= 0 ? 0 : (proteinCalories / calories) * 100;
  double get carbsPercent =>
      calories <= 0 ? 0 : (carbsCalories / calories) * 100;
  double get fatPercent => calories <= 0 ? 0 : (fatCalories / calories) * 100;

  @override
  String toString() =>
      'NutritionGoals(cal: ${calories.round()}, P: ${protein.round()}g, '
      'C: ${carbs.round()}g, G: ${fat.round()}g)';
}
