import 'package:flutter_test/flutter_test.dart';
import 'package:nutrimotion/models/user_model.dart';
import 'package:nutrimotion/utils/nutrition_calculator.dart';
import 'package:nutrimotion/utils/user_options.dart';

/// Verifica que las opciones canónicas del perfil (UserOptions) y la lógica
/// de cálculo (NutritionCalculator) estén sincronizadas: si se añade una
/// opción que el calculador no entiende, este caería silenciosamente al
/// valor por defecto y estos tests fallarían.
void main() {
  AppUser makeUser({String? sexo, String? actividad, String? objetivo}) {
    return AppUser(
      uid: 'u1',
      email: 'a@a.com',
      peso: 80,
      altura: 180,
      edad: 30,
      sexo: sexo ?? 'Hombre',
      actividad: actividad ?? 'Sedentario',
      objetivo: objetivo ?? 'Mantenimiento',
    );
  }

  test('cada nivel de actividad produce un TDEE estrictamente mayor', () {
    final niveles = UserOptions.actividades.keys.toList();
    double? anterior;
    for (final nivel in niveles) {
      final goals = NutritionCalculator.forUser(makeUser(actividad: nivel))!;
      if (anterior != null) {
        expect(
          goals.maintenanceCalories,
          greaterThan(anterior),
          reason:
              'El nivel "$nivel" debería dar más TDEE que el anterior; '
              'si no, el calculador no lo reconoce y usa el default.',
        );
      }
      anterior = goals.maintenanceCalories;
    }
  });

  test('los objetivos ordenan las calorías: Déficit < Recomp. < Mant. < Superávit', () {
    double caloriesFor(String objetivo) =>
        NutritionCalculator.forUser(makeUser(objetivo: objetivo))!.calories;

    // Todos los objetivos canónicos deben ser reconocidos.
    expect(UserOptions.objetivos.keys, contains('Recomposición'));

    final deficit = caloriesFor('Déficit');
    final recomp = caloriesFor('Recomposición');
    final mant = caloriesFor('Mantenimiento');
    final superavit = caloriesFor('Superávit');

    expect(deficit, lessThan(recomp));
    expect(recomp, lessThan(mant));
    expect(mant, lessThan(superavit));
  });

  test('ambos sexos son reconocidos (BMR hombre > mujer a igual cuerpo)', () {
    final hombre = NutritionCalculator.forUser(makeUser(sexo: 'Hombre'))!;
    final mujer = NutritionCalculator.forUser(makeUser(sexo: 'Mujer'))!;
    // Mifflin-St Jeor: +5 vs -161 → diferencia exacta de 166 kcal.
    expect(hombre.bmr - mujer.bmr, closeTo(166, 0.001));
  });

  test('validOrNull filtra valores desconocidos y conserva los válidos', () {
    expect(
      UserOptions.validOrNull('Recomposición', UserOptions.objetivos.keys),
      'Recomposición',
    );
    expect(
      UserOptions.validOrNull('valor-viejo', UserOptions.objetivos.keys),
      isNull,
    );
    expect(UserOptions.validOrNull(null, UserOptions.objetivos.keys), isNull);
  });
}
