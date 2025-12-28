import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nutrimotion/models/food_model.dart';
import 'package:nutrimotion/models/meal_entry_model.dart';

class MealService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  CollectionReference get _mealEntriesCollection =>
      _firestore.collection('meal_entries');

  String? get _currentUserId => _auth.currentUser?.uid;

  Future<void> addEntry({
    required FoodItem foodItem,
    required double quantity,
    required MealType mealType,
    required DateTime date,
  }) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception(
        "Usuario no autenticado. No se puede guardar la entrada.",
      );
    }

    final newEntry = MealEntry(
      id: '',
      foodItem: foodItem,
      quantity: quantity,
      mealType: mealType,
      date: date,
    );

    final data = newEntry.toMap();

    data['userId'] = userId;

    await _mealEntriesCollection.add(data);
  }

  Future<void> removeEntry(String entryId) async {
    await _mealEntriesCollection.doc(entryId).delete();
  }

  Future<void> updateMealEntry(
    String entryId, {
    required double newQuantity,
  }) async {
    await _mealEntriesCollection.doc(entryId).update({'quantity': newQuantity});
  }

  Stream<List<MealEntry>> getEntriesForDate(DateTime date) {
    final userId = _currentUserId;
    if (userId == null) {
      return Stream.value([]);
    }

    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _mealEntriesCollection
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .where('date', isLessThan: endOfDay)
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return MealEntry.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }).toList();
        });
  }
}
