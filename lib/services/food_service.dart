// lib/services/food_service.dart

import 'package:nutrimotion/models/food_model.dart';
import 'dart:async'; // Necesario para Future

class FoodService {
  // 🍎 Base de Datos de Alimentos Estática (100g de porción)
  static final List<FoodItem> _staticFoodDatabase = [
    FoodItem(
      id: 'f1',
      name: 'Pechuga de Pollo',
      calories: 165,
      protein: 31.0,
      carbs: 0.0,
      fat: 3.6,
    ),
    FoodItem(
      id: 'f2',
      name: 'Arroz Blanco',
      calories: 130,
      protein: 2.7,
      carbs: 28.0,
      fat: 0.3,
    ),
    FoodItem(
      id: 'f3',
      name: 'Manzana',
      calories: 52,
      protein: 0.3,
      carbs: 14.0,
      fat: 0.2,
    ),
    FoodItem(
      id: 'f4',
      name: 'Aceite de Oliva Extra Virgen',
      calories: 884,
      protein: 0.0,
      carbs: 0.0,
      fat: 100.0,
    ),
    FoodItem(
      id: 'f5',
      name: 'Huevo (cocido)',
      calories: 155,
      protein: 13.0,
      carbs: 1.1,
      fat: 10.6,
    ),
    FoodItem(
      id: 'f6',
      name: 'Avena',
      calories: 389,
      protein: 16.9,
      carbs: 66.3,
      fat: 6.9,
    ),
    FoodItem(
      id: 'f7',
      name: 'Brócoli (cocido)',
      calories: 35,
      protein: 2.4,
      carbs: 7.2,
      fat: 0.4,
    ),
    FoodItem(
      id: 'f8',
      name: 'Salmón (cocido)',
      calories: 208,
      protein: 20.4,
      carbs: 0.0,
      fat: 13.4,
    ),
  ];

  /// Obtiene todos los alimentos de la base de datos (simulando una llamada a API/DB)
  Future<List<FoodItem>> getAllFoods() async {
    // Simular un retraso de red
    await Future.delayed(const Duration(milliseconds: 500));
    return _staticFoodDatabase;
  }

  /// Busca alimentos que coincidan con el término de búsqueda (case insensitive)
  Future<List<FoodItem>> searchFoods(String query) async {
    if (query.isEmpty) {
      return getAllFoods();
    }
    await Future.delayed(const Duration(milliseconds: 300));

    final normalizedQuery = query.toLowerCase();
    return _staticFoodDatabase
        .where((food) => food.name.toLowerCase().contains(normalizedQuery))
        .toList();
  }
}
