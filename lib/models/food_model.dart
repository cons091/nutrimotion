// lib/models/food_model.dart

class FoodItem {
  final String id;
  final String name;
  final String unit; // Unidad de referencia (ej: "g", "ml", "unidad")
  final double servingSize; // Tamaño de la porción estándar (ej: 100 g)
  final double calories; // Kcal por servingSize
  final double protein; // Gramos de proteína por servingSize
  final double carbs; // Gramos de carbohidratos por servingSize
  final double fat; // Gramos de grasa por servingSize

  FoodItem({
    required this.id,
    required this.name,
    this.unit = 'g',
    this.servingSize = 100.0,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  // Método para crear un objeto FoodItem desde un mapa (útil para JSON o Firestore)
  factory FoodItem.fromMap(Map<String, dynamic> map, String id) {
    return FoodItem(
      id: id,
      name: map['name'] ?? 'Alimento Desconocido',
      unit: map['unit'] ?? 'g',
      servingSize: (map['servingSize'] as num?)?.toDouble() ?? 100.0,
      calories: (map['calories'] as num?)?.toDouble() ?? 0.0,
      protein: (map['protein'] as num?)?.toDouble() ?? 0.0,
      carbs: (map['carbs'] as num?)?.toDouble() ?? 0.0,
      fat: (map['fat'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // Método para convertir el objeto a un mapa (útil para Firebase)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'unit': unit,
      'servingSize': servingSize,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }
}
