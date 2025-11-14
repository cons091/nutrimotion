// lib/models/meal_entry_model.dart

import 'food_model.dart';

enum MealType { desayuno, almuerzo, cena, snacks }

class MealEntry {
  final String id; // ID único del registro
  final FoodItem foodItem; // El alimento consumido
  final double quantity; // Cantidad consumida (ej: 150g)
  final MealType mealType; // Tipo de comida (Desayuno, Almuerzo, etc.)
  final DateTime date; // Fecha de consumo

  MealEntry({
    required this.id,
    required this.foodItem,
    required this.quantity,
    required this.mealType,
    required this.date,
  });

  // Métodos Calculados (Macros totales para esta entrada)
  double get totalCalories {
    return (foodItem.calories / foodItem.servingSize) * quantity;
  }

  double get totalProtein {
    return (foodItem.protein / foodItem.servingSize) * quantity;
  }

  double get totalCarbs {
    return (foodItem.carbs / foodItem.servingSize) * quantity;
  }

  double get totalFat {
    return (foodItem.fat / foodItem.servingSize) * quantity;
  }
}
