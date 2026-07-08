import 'package:cloud_firestore/cloud_firestore.dart';

/// Tipos de comida del día. Se guardan como string en Firestore.
enum MealType { desayuno, almuerzo, cena, snack }

extension MealTypeInfo on MealType {
  /// Clave estable para persistir (no cambia aunque cambie la etiqueta visible).
  String get key => name;

  /// Etiqueta legible para la UI.
  String get label {
    switch (this) {
      case MealType.desayuno:
        return 'Desayuno';
      case MealType.almuerzo:
        return 'Almuerzo';
      case MealType.cena:
        return 'Cena';
      case MealType.snack:
        return 'Snacks';
    }
  }

  static MealType fromKey(String? key) {
    return MealType.values.firstWhere(
      (m) => m.key == key,
      orElse: () => MealType.snack,
    );
  }
}

/// Un alimento registrado en el diario de nutrición del usuario.
///
/// Los valores [calories], [protein], [carbs] y [fat] corresponden a la
/// porción efectivamente consumida (ya multiplicada por la cantidad), no a
/// valores por 100 g.
class FoodEntry {
  final String id;
  final String name;
  final MealType mealType;

  /// Calorías de la porción consumida (kcal).
  final double calories;

  /// Macronutrientes de la porción consumida (g).
  final double protein;
  final double carbs;
  final double fat;

  /// Cantidad consumida en gramos (opcional, informativa).
  final double? quantityGrams;

  /// Fecha/hora del registro.
  final DateTime date;

  FoodEntry({
    required this.id,
    required this.name,
    required this.mealType,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.date,
    this.quantityGrams,
  });

  /// Clave de día "yyyy-MM-dd" usada para agrupar y consultar por jornada.
  String get dayKey => dayKeyFrom(date);

  static String dayKeyFrom(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'mealType': mealType.key,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'quantityGrams': quantityGrams,
      'date': Timestamp.fromDate(date),
      'dayKey': dayKey,
    };
  }

  factory FoodEntry.fromMap(String id, Map<String, dynamic> map) {
    return FoodEntry(
      id: id,
      name: (map['name'] ?? '') as String,
      mealType: MealTypeInfo.fromKey(map['mealType'] as String?),
      calories: _toDouble(map['calories']),
      protein: _toDouble(map['protein']),
      carbs: _toDouble(map['carbs']),
      fat: _toDouble(map['fat']),
      quantityGrams: map['quantityGrams'] == null
          ? null
          : _toDouble(map['quantityGrams']),
      date: map['date'] is Timestamp
          ? (map['date'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  FoodEntry copyWith({
    String? id,
    String? name,
    MealType? mealType,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? quantityGrams,
    DateTime? date,
  }) {
    return FoodEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      mealType: mealType ?? this.mealType,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      quantityGrams: quantityGrams ?? this.quantityGrams,
      date: date ?? this.date,
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}
