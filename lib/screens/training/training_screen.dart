import 'package:flutter/material.dart';
import 'package:nutrimotion/screens/training/workout_form_screen.dart';
import 'package:nutrimotion/screens/training/workout_list_screen.dart';
import 'package:nutrimotion/screens/training/empty_workout_screen.dart';

class TrainingScreen extends StatelessWidget {
  const TrainingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Entrenamiento")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            "Empezar Entrenamiento",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          // Entrenamiento vacío
          Card(
            child: ListTile(
              leading: const Icon(Icons.fitness_center, color: Colors.blue),
              title: const Text("Entrenamiento rápido (vacío)"),
              subtitle: const Text("Comienza un entrenamiento desde cero"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EmptyWorkoutScreen()),
                );
              },
            ),
          ),

          // Rutinas creadas
          Card(
            child: ListTile(
              leading: const Icon(Icons.list, color: Colors.green),
              title: const Text("Usar rutina creada"),
              subtitle: const Text("Accede a tus rutinas guardadas"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WorkoutListScreen()),
                );
              },
            ),
          ),

          const SizedBox(height: 30),
          const Text(
            "Rutinas",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          // Crear rutina
          Card(
            child: ListTile(
              leading: const Icon(Icons.add, color: Colors.orange),
              title: const Text("Crear rutina"),
              subtitle: const Text("Crea una nueva rutina personalizada"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WorkoutFormScreen()),
                );
              },
            ),
          ),

          // Ver mis rutinas
          Card(
            child: ListTile(
              leading: const Icon(Icons.folder, color: Colors.purple),
              title: const Text("Ver mis rutinas"),
              subtitle: const Text("Edita o elimina tus rutinas"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WorkoutListScreen()),
                );
              },
            ),
          ),

          // Explorar rutinas (placeholder)
          Card(
            child: ListTile(
              leading: const Icon(Icons.explore, color: Colors.teal),
              title: const Text("Explorar rutinas"),
              subtitle: const Text("Descubre rutinas prediseñadas"),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "🚧 Desarrollo pendiente para explorar rutinas",
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
