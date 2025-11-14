// lib/services/meal_service.dart

import 'package:nutrimotion/models/food_model.dart';
import 'package:nutrimotion/models/meal_entry_model.dart';

class MealService {
  final List<MealEntry> _mealDiary = [];
  int _idCounter = 0;

  // 📝 Añadir un nuevo registro de comida
  void addEntry({
    required FoodItem foodItem,
    required double quantity,
    required MealType mealType,
    required DateTime date,
  }) {
    // Normalizamos la fecha para la búsqueda
    final targetDate = DateTime(date.year, date.month, date.day);

    // 1. Buscar si ya existe una entrada para este alimento, tipo de comida, y fecha
    final existingEntryIndex = _mealDiary.indexWhere((entry) {
      final entryDate = DateTime(
        entry.date.year,
        entry.date.month,
        entry.date.day,
      );
      return entry.foodItem.id == foodItem.id &&
          entry.mealType == mealType &&
          entryDate.isAtSameMomentAs(targetDate);
    });

    if (existingEntryIndex != -1) {
      // 2. Si existe: Crear una nueva entrada con la cantidad acumulada
      final existingEntry = _mealDiary[existingEntryIndex];
      final newQuantity = existingEntry.quantity + quantity;

      // 3. Eliminar la entrada antigua
      _mealDiary.removeAt(existingEntryIndex);

      // 4. Añadir la nueva entrada consolidada
      final consolidatedEntry = MealEntry(
        id: existingEntry.id, // Reutilizar el ID original
        foodItem: foodItem,
        quantity: newQuantity, // Cantidad sumada
        mealType: mealType,
        date: date,
      );
      _mealDiary.add(consolidatedEntry);
    } else {
      // 5. Si no existe: Añadir una nueva entrada normal
      final newEntry = MealEntry(
        id: 'e${_idCounter++}',
        foodItem: foodItem,
        quantity: quantity,
        mealType: mealType,
        date: date,
      );
      _mealDiary.add(newEntry);
    }
  }

  // 🗑️ Eliminar un registro (útil para la UI)
  void removeEntry(String entryId) {
    _mealDiary.removeWhere((entry) => entry.id == entryId);
  }

  void updateMealEntry(String entryId, {required double newQuantity}) {
    // 1. Encontrar el índice de la entrada por su ID
    final index = _mealDiary.indexWhere((entry) => entry.id == entryId);

    if (index != -1) {
      final existingEntry = _mealDiary[index];

      // 2. Crear una nueva entrada con la cantidad actualizada
      final updatedEntry = MealEntry(
        id: existingEntry.id,
        foodItem: existingEntry.foodItem,
        quantity: newQuantity, // ⬅️ Cantidad actualizada
        mealType: existingEntry.mealType,
        date: existingEntry.date,
      );

      // 3. Reemplazar la entrada antigua con la nueva entrada actualizada
      _mealDiary[index] = updatedEntry;
    }
    // Nota: Si el ID no se encuentra, simplemente se ignora la operación.
  }

  // 📅 Obtener los registros para una fecha específica
  List<MealEntry> getEntriesForDate(DateTime date) {
    // Normalizamos la fecha para ignorar la hora (solo día, mes, año)
    final targetDate = DateTime(date.year, date.month, date.day);
    return _mealDiary.where((entry) {
      final entryDate = DateTime(
        entry.date.year,
        entry.date.month,
        entry.date.day,
      );
      return entryDate.isAtSameMomentAs(targetDate);
    }).toList();
  }
}
