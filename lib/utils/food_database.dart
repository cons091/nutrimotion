/// Alimento de referencia con valores nutricionales por 100 g.
///
/// A partir de estos valores y de los gramos consumidos se calcula la porción
/// real (ver [FoodItem.forGrams]).
class FoodItem {
  final String name;

  /// Categoría para agrupar/filtrar en el selector.
  final String category;

  /// Valores por 100 g.
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;

  const FoodItem({
    required this.name,
    required this.category,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
  });

  /// Devuelve los macros de la porción de [grams] gramos.
  ({double calories, double protein, double carbs, double fat}) forGrams(
    double grams,
  ) {
    final factor = grams / 100.0;
    return (
      calories: caloriesPer100g * factor,
      protein: proteinPer100g * factor,
      carbs: carbsPer100g * factor,
      fat: fatPer100g * factor,
    );
  }
}

/// Pequeña base de datos local de alimentos comunes (valores aproximados
/// por 100 g). Sirve para registrar rápido sin conexión a una API externa.
class FoodDatabase {
  const FoodDatabase._();

  static const List<FoodItem> items = [
    // --- Proteínas ---
    FoodItem(
      name: 'Pechuga de pollo',
      category: 'Proteínas',
      caloriesPer100g: 165,
      proteinPer100g: 31,
      carbsPer100g: 0,
      fatPer100g: 3.6,
    ),
    FoodItem(
      name: 'Huevo entero',
      category: 'Proteínas',
      caloriesPer100g: 155,
      proteinPer100g: 13,
      carbsPer100g: 1.1,
      fatPer100g: 11,
    ),
    FoodItem(
      name: 'Atún al natural',
      category: 'Proteínas',
      caloriesPer100g: 116,
      proteinPer100g: 26,
      carbsPer100g: 0,
      fatPer100g: 1,
    ),
    FoodItem(
      name: 'Carne de res magra',
      category: 'Proteínas',
      caloriesPer100g: 187,
      proteinPer100g: 26,
      carbsPer100g: 0,
      fatPer100g: 9,
    ),
    FoodItem(
      name: 'Salmón',
      category: 'Proteínas',
      caloriesPer100g: 208,
      proteinPer100g: 20,
      carbsPer100g: 0,
      fatPer100g: 13,
    ),
    FoodItem(
      name: 'Lentejas cocidas',
      category: 'Proteínas',
      caloriesPer100g: 116,
      proteinPer100g: 9,
      carbsPer100g: 20,
      fatPer100g: 0.4,
    ),
    // --- Lácteos ---
    FoodItem(
      name: 'Yogur griego natural',
      category: 'Lácteos',
      caloriesPer100g: 59,
      proteinPer100g: 10,
      carbsPer100g: 3.6,
      fatPer100g: 0.4,
    ),
    FoodItem(
      name: 'Leche semidesnatada',
      category: 'Lácteos',
      caloriesPer100g: 47,
      proteinPer100g: 3.3,
      carbsPer100g: 4.8,
      fatPer100g: 1.6,
    ),
    FoodItem(
      name: 'Queso fresco batido 0%',
      category: 'Lácteos',
      caloriesPer100g: 47,
      proteinPer100g: 8,
      carbsPer100g: 4,
      fatPer100g: 0.2,
    ),
    // --- Carbohidratos ---
    FoodItem(
      name: 'Arroz blanco cocido',
      category: 'Carbohidratos',
      caloriesPer100g: 130,
      proteinPer100g: 2.7,
      carbsPer100g: 28,
      fatPer100g: 0.3,
    ),
    FoodItem(
      name: 'Avena',
      category: 'Carbohidratos',
      caloriesPer100g: 389,
      proteinPer100g: 17,
      carbsPer100g: 66,
      fatPer100g: 7,
    ),
    FoodItem(
      name: 'Pan integral',
      category: 'Carbohidratos',
      caloriesPer100g: 247,
      proteinPer100g: 13,
      carbsPer100g: 41,
      fatPer100g: 3.4,
    ),
    FoodItem(
      name: 'Pasta cocida',
      category: 'Carbohidratos',
      caloriesPer100g: 158,
      proteinPer100g: 6,
      carbsPer100g: 31,
      fatPer100g: 0.9,
    ),
    FoodItem(
      name: 'Papa cocida',
      category: 'Carbohidratos',
      caloriesPer100g: 87,
      proteinPer100g: 1.9,
      carbsPer100g: 20,
      fatPer100g: 0.1,
    ),
    FoodItem(
      name: 'Batata / camote',
      category: 'Carbohidratos',
      caloriesPer100g: 86,
      proteinPer100g: 1.6,
      carbsPer100g: 20,
      fatPer100g: 0.1,
    ),
    // --- Frutas y verduras ---
    FoodItem(
      name: 'Banana',
      category: 'Frutas',
      caloriesPer100g: 89,
      proteinPer100g: 1.1,
      carbsPer100g: 23,
      fatPer100g: 0.3,
    ),
    FoodItem(
      name: 'Manzana',
      category: 'Frutas',
      caloriesPer100g: 52,
      proteinPer100g: 0.3,
      carbsPer100g: 14,
      fatPer100g: 0.2,
    ),
    FoodItem(
      name: 'Brócoli',
      category: 'Verduras',
      caloriesPer100g: 34,
      proteinPer100g: 2.8,
      carbsPer100g: 7,
      fatPer100g: 0.4,
    ),
    // --- Grasas ---
    FoodItem(
      name: 'Aguacate / palta',
      category: 'Grasas',
      caloriesPer100g: 160,
      proteinPer100g: 2,
      carbsPer100g: 9,
      fatPer100g: 15,
    ),
    FoodItem(
      name: 'Almendras',
      category: 'Grasas',
      caloriesPer100g: 579,
      proteinPer100g: 21,
      carbsPer100g: 22,
      fatPer100g: 50,
    ),
    FoodItem(
      name: 'Aceite de oliva',
      category: 'Grasas',
      caloriesPer100g: 884,
      proteinPer100g: 0,
      carbsPer100g: 0,
      fatPer100g: 100,
    ),
    FoodItem(
      name: 'Mantequilla de maní',
      category: 'Grasas',
      caloriesPer100g: 588,
      proteinPer100g: 25,
      carbsPer100g: 20,
      fatPer100g: 50,
    ),
  ];

  /// Categorías únicas, en orden de aparición.
  static List<String> get categories {
    final seen = <String>[];
    for (final item in items) {
      if (!seen.contains(item.category)) seen.add(item.category);
    }
    return seen;
  }

  /// Búsqueda simple por nombre (case-insensitive).
  static List<FoodItem> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items.where((f) => f.name.toLowerCase().contains(q)).toList();
  }
}
