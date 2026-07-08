/// Validadores y parsers reutilizables para formularios.
///
/// Centraliza la validación numérica para evitar crashes por
/// `double.parse`/`int.parse` sobre texto libre y unifica los mensajes.
class Validators {
  const Validators._();

  // ---------------------------------------------------------------------------
  // Parsers seguros
  // ---------------------------------------------------------------------------

  /// Convierte texto a double aceptando coma o punto decimal ("70,5" == "70.5").
  /// Devuelve `null` si no es un número válido.
  static double? parseDouble(String? raw) {
    if (raw == null) return null;
    final cleaned = raw.trim().replaceAll(',', '.');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  /// Convierte texto a int. Devuelve `null` si no es un entero válido.
  static int? parseInt(String? raw) {
    if (raw == null) return null;
    return int.tryParse(raw.trim());
  }

  // ---------------------------------------------------------------------------
  // Validadores para TextFormField (devuelven null si el valor es válido)
  // ---------------------------------------------------------------------------

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Ingresa tu correo';
    // Suficiente para UI; la validación real la hace FirebaseAuth.
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!regex.hasMatch(v)) return 'Correo no válido';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Ingresa tu contraseña';
    if (value.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }

  /// Edad: entero entre 12 y 100 años.
  static String? edad(String? value) {
    final n = parseInt(value);
    if (n == null) return 'Ingresa una edad válida';
    if (n < 12 || n > 100) return 'Edad entre 12 y 100 años';
    return null;
  }

  /// Peso: número entre 25 y 400 kg (acepta coma o punto).
  static String? peso(String? value) {
    final n = parseDouble(value);
    if (n == null) return 'Ingresa un peso válido';
    if (n < 25 || n > 400) return 'Peso entre 25 y 400 kg';
    return null;
  }

  /// Altura: número entre 90 y 250 cm (acepta coma o punto).
  static String? altura(String? value) {
    final n = parseDouble(value);
    if (n == null) return 'Ingresa una altura válida';
    if (n < 90 || n > 250) return 'Altura entre 90 y 250 cm';
    return null;
  }
}
