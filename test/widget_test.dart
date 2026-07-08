// Tests de la lógica de agregación del diario de nutrición (NutritionSummary).
//
// Nota: se reemplazó el test "counter" por defecto de la plantilla, que ya no
// aplicaba a esta app y además rompía la suite.

import 'package:flutter_test/flutter_test.dart';
import 'package:nutrimotion/models/food_entry.dart';
import 'package:nutrimotion/models/nutrition_goals.dart';
import 'package:nutrimotion/models/nutrition_summary.dart';

void main() {
  const goals = NutritionGoals(
    calories: 2000,
    protein: 150,
    carbs: 200,
    fat: 60,
    bmr: 1600,
    maintenanceCalories: 2000,
  );

  FoodEntry entry({
    required String name,
    required MealType meal,
    required double cal,
    double p = 0,
    double c = 0,
    double f = 0,
  }) {
    return FoodEntry(
      id: name,
      name: name,
      mealType: meal,
      calories: cal,
      protein: p,
      carbs: c,
      fat: f,
      date: DateTime(2026, 1, 1),
    );
  }

  group('NutritionSummary', () {
    test('suma calorías y macros de todos los alimentos', () {
      final s = NutritionSummary.from([
        entry(name: 'Pollo', meal: MealType.almuerzo, cal: 300, p: 50),
        entry(name: 'Arroz', meal: MealType.almuerzo, cal: 200, c: 45),
      ], goals);

      expect(s.consumedCalories, 500);
      expect(s.consumedProtein, 50);
      expect(s.consumedCarbs, 45);
    });

    test('calcula el restante frente al objetivo', () {
      final s = NutritionSummary.from([
        entry(name: 'X', meal: MealType.cena, cal: 1500),
      ], goals);
      expect(s.remainingCalories, 500);
      expect(s.isOverCalories, isFalse);
    });

    test('detecta exceso calórico', () {
      final s = NutritionSummary.from([
        entry(name: 'X', meal: MealType.cena, cal: 2200),
      ], goals);
      expect(s.isOverCalories, isTrue);
      expect(s.remainingCalories, -200);
    });

    test('el progreso se limita a [0,1]', () {
      final s = NutritionSummary.from([
        entry(name: 'X', meal: MealType.cena, cal: 4000),
      ], goals);
      expect(s.caloriesProgress, 1.0);

      final empty = NutritionSummary.from([], goals);
      expect(empty.caloriesProgress, 0.0);
    });

    test('agrupa y suma por tipo de comida', () {
      final s = NutritionSummary.from([
        entry(name: 'Huevo', meal: MealType.desayuno, cal: 150),
        entry(name: 'Avena', meal: MealType.desayuno, cal: 250),
        entry(name: 'Pollo', meal: MealType.almuerzo, cal: 300),
      ], goals);

      expect(s.entriesFor(MealType.desayuno).length, 2);
      expect(s.caloriesFor(MealType.desayuno), 400);
      expect(s.caloriesFor(MealType.almuerzo), 300);
      expect(s.caloriesFor(MealType.snack), 0);
    });

    test('sin objetivos, el progreso es 0 y restante 0', () {
      final s = NutritionSummary.from([
        entry(name: 'X', meal: MealType.cena, cal: 500),
      ], null);
      expect(s.caloriesProgress, 0.0);
      expect(s.remainingCalories, 0.0);
      expect(s.consumedCalories, 500); // el consumo sí se calcula
    });
  });
}
