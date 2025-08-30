import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:nutrimotion/models/workout_model.dart';
import 'package:nutrimotion/services/workout_service.dart';

class WorkoutFormScreen extends StatefulWidget {
  const WorkoutFormScreen({super.key});

  @override
  State<WorkoutFormScreen> createState() => _WorkoutFormScreenState();
}

class _WorkoutFormScreenState extends State<WorkoutFormScreen> {
  final _titleController = TextEditingController();
  final List<Exercise> _exercises = [];
  final _formKey = GlobalKey<FormState>();

  void _addExercise() {
    final nameController = TextEditingController();
    final setsController = TextEditingController();
    final repsController = TextEditingController();
    final weightController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Nuevo Ejercicio"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Nombre"),
              ),
              TextField(
                controller: setsController,
                decoration: const InputDecoration(labelText: "Series"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: repsController,
                decoration: const InputDecoration(labelText: "Reps"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: weightController,
                decoration: const InputDecoration(labelText: "Peso (kg)"),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _exercises.add(
                    Exercise(
                      name: nameController.text,
                      sets: int.tryParse(setsController.text) ?? 0,
                      reps: int.tryParse(repsController.text) ?? 0,
                      weight: double.tryParse(weightController.text),
                    ),
                  );
                });
                Navigator.pop(context);
              },
              child: const Text("Añadir"),
            ),
          ],
        );
      },
    );
  }

  void _saveWorkout() async {
    if (_formKey.currentState!.validate() && _exercises.isNotEmpty) {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final workoutService = WorkoutService();

      final workout = Workout(
        id: const Uuid().v4(),
        title: _titleController.text,
        exercises: _exercises,
      );

      await workoutService.addWorkout(userId, workout);

      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nueva Rutina")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: "Nombre de la Rutina",
                ),
                validator: (value) => value!.isEmpty ? "Campo requerido" : null,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: _exercises.length,
                  itemBuilder: (context, index) {
                    final ex = _exercises[index];
                    return ListTile(
                      title: Text(ex.name),
                      subtitle: Text(
                        "${ex.sets}x${ex.reps} - ${ex.weight ?? 0} kg",
                      ),
                    );
                  },
                ),
              ),
              ElevatedButton.icon(
                onPressed: _addExercise,
                icon: const Icon(Icons.add),
                label: const Text("Añadir Ejercicio"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveWorkout,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text("Guardar Rutina"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
