import 'package:flutter/material.dart';
import 'package:nutrimotion/screens/training/workout_form_screen.dart';
import 'package:nutrimotion/screens/training/workout_list_screen.dart';
import 'package:nutrimotion/screens/training/empty_workout_screen.dart';
import 'package:nutrimotion/screens/training/workout_session_screen.dart'; // Usar la Session Screen para el entrenamiento vacío

class TrainingScreen extends StatelessWidget {
  const TrainingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Widget auxiliar para crear las tarjetas de opción estilizadas
    Widget _buildOptionCard({
      required String title,
      required String subtitle,
      required IconData icon,
      required Color iconColor,
      required VoidCallback onTap,
    }) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.only(bottom: 15),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              title: Text(
                title,
                style: theme.textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(subtitle, style: theme.textTheme.bodyMedium),
              trailing: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: theme.colorScheme.outline,
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Entrenamiento 🏃"),
        backgroundColor: theme.colorScheme.surfaceContainer,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 🚀 Sección: Empezar Entrenamiento
          Text(
            "Empezar Entrenamiento",
            style: theme.textTheme.titleLarge!.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),

          // Entrenamiento vacío / Rápido
          _buildOptionCard(
            title: "Entrenamiento rápido (vacío)",
            subtitle: "Comienza un entrenamiento sin plantilla",
            icon: Icons.timer_outlined,
            iconColor: theme.colorScheme.tertiary,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const WorkoutSessionScreen(startAutomatically: true),
                ),
              );
            },
          ),

          // Rutinas creadas
          _buildOptionCard(
            title: "Usar rutina guardada",
            subtitle: "Elige una de tus rutinas creadas",
            icon: Icons.list_alt_rounded,
            iconColor: theme.colorScheme.primary,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WorkoutListScreen()),
              );
            },
          ),

          const SizedBox(height: 30),

          // 🛠️ Sección: Gestión de Rutinas
          Text(
            "Gestión de Rutinas",
            style: theme.textTheme.titleLarge!.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),

          // Crear rutina
          _buildOptionCard(
            title: "Crear nueva rutina",
            subtitle: "Diseña tu rutina de ejercicios personalizada",
            icon: Icons.add_box_rounded,
            iconColor: Colors.orange.shade700,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WorkoutFormScreen()),
              );
            },
          ),

          // Ver/Editar rutinas (Redundante con "Usar rutina guardada", pero mantiene la lógica anterior)
          _buildOptionCard(
            title: "Ver mis rutinas",
            subtitle: "Edita o elimina tus rutinas guardadas",
            icon: Icons.folder_copy_rounded,
            iconColor: Colors.purple.shade700,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WorkoutListScreen()),
              );
            },
          ),

          // Explorar rutinas (placeholder)
          _buildOptionCard(
            title: "Explorar rutinas (Comunidad)",
            subtitle: "Descubre rutinas prediseñadas por expertos",
            icon: Icons.explore_rounded,
            iconColor: Colors.teal.shade700,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    "🚧 Desarrollo pendiente: ¡Próximamente rutinas de la comunidad!",
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
