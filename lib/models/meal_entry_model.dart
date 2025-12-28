import 'package:cloud_firestore/cloud_firestore.dart';
import 'food_model.dart';

enum MealType { desayuno, almuerzo, cena, snacks }

class MealEntry {
  final String id; // ID único del registro (Document ID de Firestore)
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

  // 🆕 Método para crear un objeto desde Firestore
  factory MealEntry.fromMap(Map<String, dynamic> map, String id) {
    // 1. Obtener el MealType del string guardado
    MealType type = MealType.values.firstWhere(
      (e) => e.toString() == 'MealType.${map['mealType']}',
      orElse: () => MealType.desayuno,
    );

    // 2. Convertir el Timestamp de Firestore a DateTime
    final DateTime date =
        (map['date'] as Timestamp?)?.toDate() ?? DateTime.now();

    // 3. Obtener el mapa de foodItem de forma segura
    final Map<String, dynamic>? foodItemMap =
        map['foodItem'] as Map<String, dynamic>?;

    if (foodItemMap == null) {
      return MealEntry(
        id: id,
        foodItem: FoodItem(
          id: 'corrupt_doc_$id',
          name: 'Documento Corrupto',
          calories: 0.0,
          protein: 0.0,
          carbs: 0.0,
          fat: 0.0,
        ),
        quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
        mealType: type,
        date: date,
      );
    }

    // 4. Obtener el ID del alimento, asumiendo que está dentro del mapa
    final String foodItemId =
        (foodItemMap['id'] as String?) ?? 'unknown_food_id';

    return MealEntry(
      id: id,
      // 5. Reconstruir el FoodItem
      foodItem: FoodItem.fromMap(foodItemMap, foodItemId),
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      mealType: type,
      date: date, // Usamos la fecha segura
    );
  }

  // 🆕 Método para convertir el objeto a Firestore
  Map<String, dynamic> toMap() {
    return {
      'foodItem': foodItem.toMap(), // Guarda todos los detalles del alimento
      'quantity': quantity,
      'mealType': mealType
          .toString()
          .split('.')
          .last, // Guarda 'desayuno' como string
      'date': date, // Firestore convierte DateTime a Timestamp automáticamente
    };
  }

  // Método copyWith existente
  MealEntry copyWith({
    String? id,
    FoodItem? foodItem,
    double? quantity,
    MealType? mealType,
    DateTime? date,
  }) {
    return MealEntry(
      id: id ?? this.id,
      foodItem: foodItem ?? this.foodItem,
      quantity: quantity ?? this.quantity,
      mealType: mealType ?? this.mealType,
      date: date ?? this.date,
    );
  }

  @override
  String toString() {
    return 'MealEntry(id: $id, food: ${foodItem.name}, qty: $quantity, type: ${mealType.name}, date: $date)';
  }
}
