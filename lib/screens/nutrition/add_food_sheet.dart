import 'package:flutter/material.dart';

import 'package:nutrimotion/models/food_entry.dart';
import 'package:nutrimotion/utils/food_database.dart';

/// Hoja inferior para registrar un alimento.
///
/// Ofrece dos modos:
/// 1. **Buscar**: elegir un alimento de la base local e indicar los gramos;
///    los macros se calculan automáticamente.
/// 2. **Manual**: introducir nombre y macros a mano.
///
/// Devuelve, vía `Navigator.pop`, un [FoodEntry] con `id`/`date` provisionales
/// (la pantalla que la abre les asigna los valores definitivos).
class AddFoodSheet extends StatefulWidget {
  final MealType initialMeal;

  const AddFoodSheet({super.key, required this.initialMeal});

  @override
  State<AddFoodSheet> createState() => _AddFoodSheetState();
}

class _AddFoodSheetState extends State<AddFoodSheet> {
  late MealType _meal;
  bool _manualMode = false;

  // Modo "buscar".
  final _searchController = TextEditingController();
  final _gramsController = TextEditingController(text: '100');
  FoodItem? _selectedItem;

  // Modo "manual".
  final _nameController = TextEditingController();
  final _calController = TextEditingController();
  final _proController = TextEditingController();
  final _carbController = TextEditingController();
  final _fatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _meal = widget.initialMeal;
    _searchController.addListener(() => setState(() {}));
    _gramsController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _gramsController.dispose();
    _nameController.dispose();
    _calController.dispose();
    _proController.dispose();
    _carbController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  double get _grams => _parse(_gramsController.text);

  static double _parse(String raw) {
    final cleaned = raw.trim().replaceAll(',', '.');
    return double.tryParse(cleaned) ?? 0;
  }

  void _submitFromDatabase() {
    final item = _selectedItem;
    if (item == null || _grams <= 0) return;
    final macros = item.forGrams(_grams);
    Navigator.pop(
      context,
      FoodEntry(
        id: 'pending',
        name: item.name,
        mealType: _meal,
        calories: macros.calories,
        protein: macros.protein,
        carbs: macros.carbs,
        fat: macros.fat,
        quantityGrams: _grams,
        date: DateTime.now(),
      ),
    );
  }

  void _submitManual() {
    final name = _nameController.text.trim();
    final cal = _parse(_calController.text);
    if (name.isEmpty || cal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Indica al menos un nombre y las calorías'),
        ),
      );
      return;
    }
    Navigator.pop(
      context,
      FoodEntry(
        id: 'pending',
        name: name,
        mealType: _meal,
        calories: cal,
        protein: _parse(_proController.text),
        carbs: _parse(_carbController.text),
        fat: _parse(_fatController.text),
        date: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Empuja el contenido por encima del teclado.
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 4,
        bottom: bottomInset + 16,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Agregar alimento',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _mealSelector(),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: false,
                  label: Text('Buscar'),
                  icon: Icon(Icons.search),
                ),
                ButtonSegment(
                  value: true,
                  label: Text('Manual'),
                  icon: Icon(Icons.edit),
                ),
              ],
              selected: {_manualMode},
              onSelectionChanged: (s) =>
                  setState(() => _manualMode = s.first),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                child: _manualMode ? _manualForm() : _searchForm(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mealSelector() {
    return Wrap(
      spacing: 8,
      children: MealType.values.map((m) {
        return ChoiceChip(
          label: Text(m.label),
          selected: _meal == m,
          selectedColor: Theme.of(context).colorScheme.primaryContainer,
          onSelected: (_) => setState(() => _meal = m),
        );
      }).toList(),
    );
  }

  // --- Modo buscar ---
  Widget _searchForm() {
    final results = FoodDatabase.search(_searchController.text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Buscar alimento (pollo, arroz, avena...)',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        if (_selectedItem != null) _selectedItemEditor() else _resultsList(results),
      ],
    );
  }

  Widget _resultsList(List<FoodItem> results) {
    if (results.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Sin resultados. Usa el modo Manual para un alimento propio.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: results.length,
      itemBuilder: (context, i) {
        final item = results[i];
        return ListTile(
          dense: true,
          leading: Icon(
            Icons.restaurant,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text(item.name),
          subtitle: Text(
            '${item.caloriesPer100g.round()} kcal · '
            'P ${item.proteinPer100g.round()}g · '
            'C ${item.carbsPer100g.round()}g · '
            'G ${item.fatPer100g.round()}g  (por 100 g)',
            style: const TextStyle(fontSize: 11),
          ),
          onTap: () => setState(() => _selectedItem = item),
        );
      },
    );
  }

  Widget _selectedItemEditor() {
    final item = _selectedItem!;
    final macros = _grams > 0 ? item.forGrams(_grams) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => setState(() => _selectedItem = null),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Cambiar'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _gramsController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Cantidad (g)',
            border: OutlineInputBorder(),
            suffixText: 'g',
          ),
        ),
        const SizedBox(height: 12),
        if (macros != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Para ${_grams.round()} g:\n'
              '${macros.calories.round()} kcal · '
              'P ${macros.protein.round()}g · '
              'C ${macros.carbs.round()}g · '
              'G ${macros.fat.round()}g',
              style: const TextStyle(fontSize: 14),
            ),
          ),
        const SizedBox(height: 12),
        _addButton(onPressed: _grams > 0 ? _submitFromDatabase : null),
      ],
    );
  }

  // --- Modo manual ---
  Widget _manualForm() {
    return Column(
      children: [
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Nombre del alimento',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _calController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Calorías (kcal)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _proController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Prot. (g)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _carbController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Carbs (g)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _fatController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Grasa (g)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _addButton(onPressed: _submitManual),
      ],
    );
  }

  Widget _addButton({required VoidCallback? onPressed}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
        ),
        icon: const Icon(Icons.check),
        label: const Text('Agregar'),
      ),
    );
  }
}
