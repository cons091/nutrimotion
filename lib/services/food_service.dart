import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/food_model.dart';

class FoodService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final String collectionName = 'foods';

  // 1. Método para la BÚSQUEDA (Implementa la lógica central)
  // (Este código ya es correcto y usa la doble consulta)
  Future<List<FoodItem>> searchFoods(String query) async {
    final userId = _auth.currentUser?.uid;
    final sanitizedQuery = query.trim().toLowerCase();

    // 1. Consulta 1: Alimentos Públicos (isPublic == true)
    Query publicQuery = _firestore
        .collection(collectionName)
        .where(
          'isPublic',
          isEqualTo: true,
        ); // Filtro que coincide con la regla 1

    // 2. Consulta 2: Alimentos Privados del Usuario (creatorId == userId)
    // Usamos 'null' como placeholder si no hay userId para evitar un error de consulta.
    Query privateQuery = _firestore
        .collection(collectionName)
        .where(
          'creatorId',
          isEqualTo: userId ?? 'null_placeholder',
        ); // Filtro que coincide con la regla 2

    // Aplicar filtros de búsqueda por nombre si la consulta no está vacía
    if (sanitizedQuery.isNotEmpty && sanitizedQuery.length >= 2) {
      publicQuery = publicQuery.orderBy('name').startAt([sanitizedQuery]).endAt(
        [sanitizedQuery + '\uf8ff'],
      );

      privateQuery = privateQuery
          .orderBy('name')
          .startAt([sanitizedQuery])
          .endAt([sanitizedQuery + '\uf8ff']);
    } else {
      // Si la búsqueda está vacía (getAllFoods), solo ordenamos y limitamos
      publicQuery = publicQuery.orderBy('name').limit(25);
      privateQuery = privateQuery.orderBy('name').limit(25);
    }

    try {
      // Ejecutar ambas consultas en paralelo
      final publicSnapshot = await publicQuery.get();
      final privateSnapshot = (userId != null)
          ? await privateQuery.get()
          : null;

      // Mapear resultados
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

      // Fusionar las listas y eliminar duplicados
      final allFoods = <String, FoodItem>{};
      for (var food in publicFoods) {
        allFoods[food.id] = food;
      }
      for (var food in privateFoods) {
        allFoods[food.id] = food;
      }

      return allFoods.values.toList();
    } catch (e) {
      print('❌ Error en searchFoods (Revisa los Índices Compuestos): $e');
      throw Exception(
        'Error al buscar alimentos. Revisa los índices de Firestore: $e',
      );
    }
  }

  // 2. Método para la CARGA INICIAL (Implementa el getAllFoods)
  Future<List<FoodItem>> getAllFoods() {
    // Sigue funcionando igual (llama a searchFoods con query vacío)
    return searchFoods('');
  }

  // 3. Método para la creación de alimento personalizado (Sin cambios)
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
