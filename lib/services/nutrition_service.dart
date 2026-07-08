import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/food_entry.dart';

/// Acceso a Firestore para el diario de nutrición.
///
/// Estructura: `users/{uid}/nutrition_entries/{entryId}`
///
/// Las consultas por día usan igualdad sobre `dayKey` (yyyy-MM-dd) para no
/// requerir índices compuestos; el orden se hace en el cliente.
class NutritionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _entriesRef(String userId) {
    return _db.collection('users').doc(userId).collection('nutrition_entries');
  }

  /// Añade un alimento al diario.
  Future<void> addEntry(String userId, FoodEntry entry) async {
    await _entriesRef(userId).doc(entry.id).set(entry.toMap());
  }

  /// Elimina un alimento del diario.
  Future<void> deleteEntry(String userId, String entryId) async {
    await _entriesRef(userId).doc(entryId).delete();
  }

  /// Stream en tiempo real de los alimentos registrados en un [day] concreto.
  ///
  /// Ordenados por fecha ascendente (en el cliente) para mostrarlos en el
  /// orden en que se registraron.
  Stream<List<FoodEntry>> entriesForDay(String userId, DateTime day) {
    final key = FoodEntry.dayKeyFrom(day);
    return _entriesRef(userId)
        .where('dayKey', isEqualTo: key)
        .snapshots()
        .map((snapshot) {
          final entries = snapshot.docs
              .map((doc) => FoodEntry.fromMap(doc.id, doc.data()))
              .toList();
          entries.sort((a, b) => a.date.compareTo(b.date));
          return entries;
        });
  }
}
