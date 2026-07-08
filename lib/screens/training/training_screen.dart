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
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          _sectionTitle(context, "Empezar entrenamiento"),
          const SizedBox(height: 8),

          _actionCard(
            context,
            icon: Icons.bolt,
            iconColor: Colors.blue,
            title: "Entrenamiento rápido",
            subtitle: "Comienza un entrenamiento desde cero",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EmptyWorkoutScreen()),
              );
            },
          ),
          _actionCard(
            context,
            icon: Icons.play_circle_outline,
            iconColor: Theme.of(context).colorScheme.primary,
            title: "Usar rutina creada",
            subtitle: "Accede a tus rutinas guardadas",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WorkoutListScreen()),
              );
            },
          ),

          const SizedBox(height: 24),
          _sectionTitle(context, "Rutinas"),
          const SizedBox(height: 8),

          _actionCard(
            context,
            icon: Icons.add,
            iconColor: Colors.orange,
            title: "Crear rutina",
            subtitle: "Crea una nueva rutina personalizada",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WorkoutFormScreen()),
              );
            },
          ),
          _actionCard(
            context,
            icon: Icons.folder_outlined,
            iconColor: Colors.purple,
            title: "Ver mis rutinas",
            subtitle: "Edita o elimina tus rutinas",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WorkoutListScreen()),
              );
            },
          ),
          _actionCard(
            context,
            icon: Icons.explore_outlined,
            iconColor: Colors.teal,
            title: "Explorar rutinas",
            subtitle: "Descubre rutinas prediseñadas",
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("🚧 Desarrollo pendiente para explorar rutinas"),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1B3B1F),
      ),
    );
  }

  /// Tarjeta de acción moderna: icono en contenedor tintado + título +
  /// subtítulo + chevron.
  Widget _actionCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
        onTap: onTap,
      ),
    );
  }
}
