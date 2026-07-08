import 'package:flutter_test/flutter_test.dart';
import 'package:nutrimotion/models/user_model.dart';
import 'package:nutrimotion/utils/nutrition_calculator.dart';

void main() {
  group('NutritionCalculator', () {
    test('devuelve null si faltan datos del perfil', () {
      final user = AppUser(uid: 'u1', email: 'a@a.com'); // sin peso/altura/edad
      expect(NutritionCalculator.forUser(user), isNull);
      expect(NutritionCalculator.forUser(null), isNull);
      expect(NutritionCalculator.hasRequiredData(user), isFalse);
    });

    test('BMR y TDEE correctos para hombre sedentario (Mifflin-St Jeor)', () {
      // Hombre, 80kg, 180cm, 30 años:
      // BMR = 10*80 + 6.25*180 - 5*30 + 5 = 800 + 1125 - 150 + 5 = 1780
      // TDEE sedentario = 1780 * 1.2 = 2136
      final user = AppUser(
        uid: 'u1',
        email: 'a@a.com',
        peso: 80,
        altura: 180,
        edad: 30,
        sexo: 'Hombre',
        actividad: 'Sedentario',
        objetivo: 'Mantenimiento',
      );

      final goals = NutritionCalculator.forUser(user)!;
      expect(goals.bmr, closeTo(1780, 0.01));
      expect(goals.maintenanceCalories, closeTo(2136, 0.01));
      // Mantenimiento => calorías == TDEE
      expect(goals.calories, closeTo(2136, 0.01));
    });

    test('BMR correcto para mujer (constante -161)', () {
      // Mujer, 60kg, 165cm, 25 años:
      // BMR = 10*60 + 6.25*165 - 5*25 - 161 = 600 + 1031.25 - 125 - 161 = 1345.25
      final user = AppUser(
        uid: 'u2',
        email: 'b@b.com',
        peso: 60,
        altura: 165,
        edad: 25,
        sexo: 'Mujer',
        actividad: 'Moderado',
        objetivo: 'Mantenimiento',
      );

      final goals = NutritionCalculator.forUser(user)!;
      expect(goals.bmr, closeTo(1345.25, 0.01));
      // TDEE moderado = 1345.25 * 1.55 = 2085.1375
      expect(goals.maintenanceCalories, closeTo(2085.1375, 0.01));
    });

    test('déficit aplica -20% sobre el TDEE', () {
      final user = AppUser(
        uid: 'u1',
        email: 'a@a.com',
        peso: 80,
        altura: 180,
        edad: 30,
        sexo: 'Hombre',
        actividad: 'Sedentario',
        objetivo: 'Déficit',
      );
      final goals = NutritionCalculator.forUser(user)!;
      // 2136 * 0.8 = 1708.8
      expect(goals.calories, closeTo(1708.8, 0.01));
    });

    test('superávit aplica +10% sobre el TDEE', () {
      final user = AppUser(
        uid: 'u1',
        email: 'a@a.com',
        peso: 80,
        altura: 180,
        edad: 30,
        sexo: 'Hombre',
        actividad: 'Sedentario',
        objetivo: 'Superávit',
      );
      final goals = NutritionCalculator.forUser(user)!;
      // 2136 * 1.10 = 2349.6
      expect(goals.calories, closeTo(2349.6, 0.01));
    });

    test('objetivo tolera mayúsculas y acentos ("deficit" == "Déficit")', () {
      final base = AppUser(
        uid: 'u1',
        email: 'a@a.com',
        peso: 80,
        altura: 180,
        edad: 30,
        sexo: 'Hombre',
        actividad: 'Sedentario',
      );
      final conAcento = NutritionCalculator.forUser(
        AppUser(
          uid: base.uid,
          email: base.email,
          peso: base.peso,
          altura: base.altura,
          edad: base.edad,
          sexo: base.sexo,
          actividad: base.actividad,
          objetivo: 'Déficit',
        ),
      )!;
      final sinAcento = NutritionCalculator.forUser(
        AppUser(
          uid: base.uid,
          email: base.email,
          peso: base.peso,
          altura: base.altura,
          edad: base.edad,
          sexo: base.sexo,
          actividad: base.actividad,
          objetivo: 'deficit',
        ),
      )!;
      expect(conAcento.calories, closeTo(sinAcento.calories, 0.001));
    });

    test('la suma de macros coincide con las calorías objetivo (±5 kcal)', () {
      final user = AppUser(
        uid: 'u1',
        email: 'a@a.com',
        peso: 75,
        altura: 175,
        edad: 28,
        sexo: 'Hombre',
        actividad: 'Alto',
        objetivo: 'Recomposición',
      );
      final g = NutritionCalculator.forUser(user)!;
      final macroCalories = g.proteinCalories + g.carbsCalories + g.fatCalories;
      expect(macroCalories, closeTo(g.calories, 5));
    });

    test('nunca devuelve carbohidratos negativos', () {
      // Perfil extremo: mucha proteína por kg y pocas calorías.
      final user = AppUser(
        uid: 'u1',
        email: 'a@a.com',
        peso: 120,
        altura: 150,
        edad: 60,
        sexo: 'Mujer',
        actividad: 'Sedentario',
        objetivo: 'Déficit',
      );
      final g = NutritionCalculator.forUser(user)!;
      expect(g.carbs, greaterThanOrEqualTo(0));
    });

    test('respeta el mínimo de 1200 kcal de seguridad', () {
      final user = AppUser(
        uid: 'u1',
        email: 'a@a.com',
        peso: 40,
        altura: 140,
        edad: 70,
        sexo: 'Mujer',
        actividad: 'Sedentario',
        objetivo: 'Déficit',
      );
      final g = NutritionCalculator.forUser(user)!;
      expect(g.calories, greaterThanOrEqualTo(1200));
    });

    test('proteína escala con el objetivo (déficit > superávit por kg)', () {
      AppUser make(String obj) => AppUser(
        uid: 'u1',
        email: 'a@a.com',
        peso: 80,
        altura: 180,
        edad: 30,
        sexo: 'Hombre',
        actividad: 'Moderado',
        objetivo: obj,
      );
      final deficit = NutritionCalculator.forUser(make('Déficit'))!;
      final superavit = NutritionCalculator.forUser(make('Superávit'))!;
      // 2.0 g/kg vs 1.8 g/kg sobre 80kg => 160g vs 144g
      expect(deficit.protein, closeTo(160, 0.01));
      expect(superavit.protein, closeTo(144, 0.01));
    });
  });
}
