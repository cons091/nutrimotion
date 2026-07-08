import 'package:flutter_test/flutter_test.dart';
import 'package:nutrimotion/utils/exercise_list.dart';

/// Guarda de consistencia de la fuente única de ejercicios.
///
/// Antes había 3 listas desincronizadas: los selectores ofrecían
/// "Brazos"/"FullBody" pero el picker no los conocía (pantalla vacía) y
/// Progreso usaba nombres distintos a los del picker (gráfica sin datos).
void main() {
  test('cada grupo del selector tiene lista de ejercicios no vacía', () {
    for (final group in ExerciseList.groups) {
      final exercises = ExerciseList.exercisesByGroup[group];
      expect(
        exercises,
        isNotNull,
        reason:
            'El grupo "$group" se ofrece en los selectores pero no existe '
            'en exercisesByGroup (esto dejaba el picker vacío).',
      );
      expect(exercises, isNotEmpty, reason: 'Grupo "$group" sin ejercicios');
    }
  });

  test('no hay grupos huérfanos en el mapa (todo grupo es seleccionable)', () {
    for (final key in ExerciseList.exercisesByGroup.keys) {
      expect(
        ExerciseList.groups,
        contains(key),
        reason:
            'El grupo "$key" tiene ejercicios pero no aparece en groups, '
            'así que ninguna pantalla puede llegar a él.',
      );
    }
  });

  test('los ejercicios de FullBody existen en sus grupos de origen', () {
    // Así Progreso encuentra el histórico del ejercicio sin importar si se
    // entrenó desde FullBody o desde su grupo específico.
    final specificGroups = ExerciseList.groups.where((g) => g != 'FullBody');
    final allSpecific = specificGroups
        .expand((g) => ExerciseList.exercisesByGroup[g]!)
        .toSet();

    for (final exercise in ExerciseList.exercisesByGroup['FullBody']!) {
      expect(
        allSpecific,
        contains(exercise),
        reason:
            '"$exercise" (FullBody) no existe en ningún grupo específico: '
            'usaría un nombre distinto y partiría el histórico en dos.',
      );
    }
  });

  test('sin nombres duplicados dentro de un mismo grupo', () {
    for (final entry in ExerciseList.exercisesByGroup.entries) {
      expect(
        entry.value.toSet().length,
        entry.value.length,
        reason: 'Ejercicio duplicado dentro del grupo "${entry.key}"',
      );
    }
  });

  test('labelFor solo embellece FullBody', () {
    expect(ExerciseList.labelFor('FullBody'), 'Full Body');
    expect(ExerciseList.labelFor('Pecho'), 'Pecho');
  });
}
