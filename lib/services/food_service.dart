import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/food_model.dart';
import 'package:flutter/foundation.dart';

class FoodService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final String collectionName = 'foods';

  Future<List<FoodItem>> searchFoods(String query) async {
    final userId = _auth.currentUser?.uid;
    final sanitizedQuery = query.trim().toLowerCase();

    Query publicQuery = _firestore
        .collection(collectionName)
        .where('isPublic', isEqualTo: true);

    Query privateQuery = _firestore
        .collection(collectionName)
        .where('creatorId', isEqualTo: userId ?? 'null_placeholder');

    if (sanitizedQuery.isNotEmpty && sanitizedQuery.length >= 2) {
      publicQuery = publicQuery.orderBy('name').startAt([sanitizedQuery]).endAt(
        ['$sanitizedQuery\uf8ff'],
      );

      privateQuery = privateQuery
          .orderBy('name')
          .startAt([sanitizedQuery])
          .endAt(['$sanitizedQuery\uf8ff']);
    } else {
      publicQuery = publicQuery.orderBy('name').limit(25);
      privateQuery = privateQuery.orderBy('name').limit(25);
    }

    try {
      final publicSnapshot = await publicQuery.get();
      final privateSnapshot = (userId != null)
          ? await privateQuery.get()
          : null;

      final publicFoods = publicSnapshot.docs
          .map(
            (doc) =>
                FoodItem.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();

      final privateFoods =
          privateSnapshot?.docs
              .map(
                (doc) => FoodItem.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList() ??
          [];

      final allFoods = <String, FoodItem>{};
      for (var food in publicFoods) {
        allFoods[food.id] = food;
      }
      for (var food in privateFoods) {
        allFoods[food.id] = food;
      }

      return allFoods.values.toList();
    } catch (e) {
      debugPrint('❌ Error en searchFoods (Revisa los Índices Compuestos): $e');
      throw Exception(
        'Error al buscar alimentos. Revisa los índices de Firestore: $e',
      );
    }
  }

  Future<List<FoodItem>> getAllFoods() {
    return searchFoods('');
  }

  Future<void> addCustomFood({
    required String name,
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
    String unit = 'g',
    double servingSize = 100.0,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('Usuario no autenticado.');
    }

    final newFoodItem = FoodItem(
      id: '',
      name: name,
      unit: unit,
      servingSize: servingSize,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      creatorId: userId,
      isPublic: false,
    );

    await _firestore.collection(collectionName).add(newFoodItem.toMap());
  }
}
