// lib/services/meal_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nutrimotion/models/food_model.dart';
import 'package:nutrimotion/models/meal_entry_model.dart';

class MealService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // Colección principal de entradas de comidas
  CollectionReference get _mealEntriesCollection =>
      _firestore.collection('meal_entries');

  // Propiedad para obtener el ID del usuario actual de forma segura
  String? get _currentUserId => _auth.currentUser?.uid;

  // 📝 Añadir un nuevo registro de comida (AHORA ASÍNCRONO)
  Future<void> addEntry({
    required FoodItem foodItem,
    required double quantity,
    required MealType mealType,
    required DateTime date,
  }) async {
    final userId = _currentUserId;
    if (userId == null) {
      // 🛑 CORRECCIÓN: Si no hay usuario, lanzamos una excepción
      throw Exception(
        "Usuario no autenticado. No se puede guardar la entrada.",
      );
    }

    // 1. Crear el objeto MealEntry para obtener los datos
    final newEntry = MealEntry(
      id: '', // ID temporal
      foodItem: foodItem,
      quantity: quantity,
      mealType: mealType,
      date: date,
    );

    // 2. Crear el mapa de datos para Firestore
    final data = newEntry.toMap();

    // ✅ CLAVE para las Reglas de Seguridad: Asignar el ID del usuario al documento
    data['userId'] = userId;

    // 3. Escribir en Firestore
    await _mealEntriesCollection.add(data);
  }

  // 🗑️ Eliminar un registro (AHORA ASÍNCRONO)
  Future<void> removeEntry(String entryId) async {
    await _mealEntriesCollection.doc(entryId).delete();
  }

  // ⬆️ Actualizar un registro (AHORA ASÍNCRONO)
  Future<void> updateMealEntry(
    String entryId, {
    required double newQuantity,
  }) async {
    await _mealEntriesCollection.doc(entryId).update({'quantity': newQuantity});
  }

  // 📅 Obtener los registros para una fecha específica (AHORA STREAM)
  Stream<List<MealEntry>> getEntriesForDate(DateTime date) {
    final userId = _currentUserId;
    if (userId == null) {
      // Si no hay usuario, retorna un stream vacío
      return Stream.value([]);
    }

    // Normalizar las fechas (ignorar la hora para filtrar por todo el día)
    final startOfDay = DateTime(date.year, date.month, date.day);
    // El fin del día es el inicio del día siguiente
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _mealEntriesCollection
        // 1. Filtra por el usuario actual
        .where('userId', isEqualTo: userId)
        // 2. Filtra por el rango de fechas (el día completo)
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .where('date', isLessThan: endOfDay)
        // 3. Ordena por fecha (requiere el índice compuesto que creaste)
        .orderBy('date', descending: false)
        // 4. Obtiene un stream de cambios en tiempo real
        .snapshots()
        // 5. Mapea el snapshot de Firestore a una lista de objetos MealEntry
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            // Mapear cada documento a un objeto MealEntry, usando doc.id como el ID
            return MealEntry.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }).toList();
        });
  }
}
