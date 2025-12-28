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
      body: _pages[_selectedIndex],

      bottomNavigationBar: NavigationBar(
        indicatorColor: theme.colorScheme.secondaryContainer,
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,

        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center),
            label: "Entrenamiento",
          ),

          NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu),
            label: "Nutrición",
          ),

          NavigationDestination(
            icon: Icon(Icons.show_chart_outlined),
            selectedIcon: Icon(Icons.show_chart),
            label: "Progreso",
          ),

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
