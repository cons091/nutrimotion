import 'package:flutter/material.dart';

/// Opciones canónicas del perfil de usuario (sexo, actividad, objetivo).
///
/// Fuente única para registro y perfil: antes cada pantalla tenía su propia
/// lista hardcodeada y se desincronizaron (el registro ofrecía
/// "Recomposición" pero el perfil no, así que se perdía al editar).
///
/// Las claves (`value`) son las que se guardan en Firestore y las que
/// entiende [NutritionCalculator]; las etiquetas son solo para la UI.
class UserOptions {
  const UserOptions._();

  static const List<String> sexos = ['Hombre', 'Mujer'];

  /// valor guardado → etiqueta visible
  static const Map<String, String> actividades = {
    'Sedentario': 'Sedentario',
    'Ligero': 'Actividad ligera (1-3x/sem)',
    'Moderado': 'Actividad moderada (3-5x/sem)',
    'Alto': 'Actividad alta (6-7x/sem)',
    'Muy alto': 'Actividad muy alta (trabajo físico)',
  };

  /// valor guardado → etiqueta visible
  static const Map<String, String> objetivos = {
    'Déficit': 'Déficit calórico',
    'Mantenimiento': 'Mantenimiento',
    'Recomposición': 'Recomposición corporal',
    'Superávit': 'Superávit calórico',
  };

  /// Convierte un mapa valor→etiqueta en items de dropdown.
  static List<DropdownMenuItem<String>> items(Map<String, String> options) {
    return options.entries
        .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
        .toList();
  }

  static List<DropdownMenuItem<String>> sexoItems() => sexos
      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
      .toList();

  /// Devuelve [value] solo si está entre las opciones válidas; si no, `null`.
  ///
  /// Evita el assert de `DropdownButtonFormField` cuando Firestore trae un
  /// valor antiguo o desconocido que no está en la lista de items.
  static String? validOrNull(String? value, Iterable<String> valid) =>
      value != null && valid.contains(value) ? value : null;
}
