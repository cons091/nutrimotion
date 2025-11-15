// lib/screens/food/food_search_screen.dart

import 'package:flutter/material.dart';
import 'package:nutrimotion/models/food_model.dart';
import 'package:nutrimotion/services/food_service.dart';

class FoodSearchScreen extends StatefulWidget {
  const FoodSearchScreen({super.key});

  @override
  State<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends State<FoodSearchScreen> {
  final FoodService _foodService = FoodService();
  final TextEditingController _searchController = TextEditingController();
  Future<List<FoodItem>>? _searchFuture;
  List<FoodItem> _lastSearchResults = [];

  @override
  void initState() {
    super.initState();
    // 💡 La inicialización ya se realizó.
    // Ahora solo cargamos los alimentos directamente.
    _searchFuture = _foodService.getAllFoods();
  }

  // ❌ ELIMINADO: El método _initializeAndLoadFoods() ya no es necesario.

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    setState(() {
      _searchFuture = _foodService.searchFoods(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Alimentos'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Column(
        children: [
          // 🔍 Campo de Búsqueda
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Buscar alimento (ej: Pollo, Arroz, Manzana)',
                hintText: 'Ingrese el nombre del alimento',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12.0)),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
              ),
              onChanged: _performSearch,
            ),
          ),

          // 📊 Resultados de la Búsqueda
          Expanded(
            child: FutureBuilder<List<FoodItem>>(
              future: _searchFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  // Muestra el error de permisos aquí
                  return Center(
                    child: Text('Error al cargar alimentos: ${snapshot.error}'),
                  );
                }

                _lastSearchResults = snapshot.data ?? [];

                if (_lastSearchResults.isEmpty) {
                  return const Center(
                    child: Text('No se encontraron alimentos con ese nombre.'),
                  );
                }

                return ListView.builder(
                  itemCount: _lastSearchResults.length,
                  itemBuilder: (context, index) {
                    final food = _lastSearchResults[index];
                    return _buildFoodItemTile(theme, food);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 📦 Widget auxiliar para mostrar la información nutricional de un alimento
  Widget _buildFoodItemTile(ThemeData theme, FoodItem food) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 1,
      child: ListTile(
        title: Text(
          food.name,
          style: theme.textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'Porción: ${food.servingSize.toStringAsFixed(0)} ${food.unit} | ${food.calories.toStringAsFixed(0)} kcal',
        ),
        trailing: Icon(
          Icons.add_circle,
          size: 24,
          color: theme.colorScheme.primary,
        ),
        onTap: () {
          Navigator.of(context).pop(food);
        },
      ),
    );
  }
}
