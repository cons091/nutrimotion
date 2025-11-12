import 'package:flutter/material.dart';
import 'package:nutrimotion/screens/training/training_screen.dart';
import 'package:nutrimotion/screens/nutrition/nutrition_screen.dart';
import 'package:nutrimotion/screens/progress/progress_screen.dart';
import 'package:nutrimotion/screens/profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    TrainingScreen(),
    NutritionScreen(),
    ProgressScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // El cuerpo simplemente muestra la página seleccionada.
      body: _pages[_selectedIndex],

      // 🔑 Reemplazamos BottomNavigationBar por NavigationBar (Material 3)
      bottomNavigationBar: NavigationBar(
        // Indicador de destino flotante
        indicatorColor: theme.colorScheme.secondaryContainer,

        // El color seleccionado se gestiona por el tema M3
        // La elevación (sombra) es sutil por defecto en M3
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,

        destinations: const [
          // 🏋️ Entrenamiento
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center),
            label: "Entrenamiento",
          ),

          // 🍎 Nutrición
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu),
            label: "Nutrición",
          ),

          // 📈 Progreso
          NavigationDestination(
            icon: Icon(Icons.show_chart_outlined),
            selectedIcon: Icon(Icons.show_chart),
            label: "Progreso",
          ),

          // 👤 Perfil
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: "Perfil",
          ),
        ],
      ),
    );
  }
}
