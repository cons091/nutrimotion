# Explicación de Archivos

Estructura de `lib/` y qué hace cada archivo. Actualizado: 2026-07-07.

## 1. Modelos (`lib/models/`)

- `user_model.dart` — `AppUser`: datos del usuario (peso, altura, edad, sexo, actividad, objetivo).
- `workout_model.dart` — `Workout` → `Exercise` → `SeriesEntry`: rutinas y ejercicios.
- `training_session_model.dart` — `TrainingSession`: sesión de entrenamiento registrada (fecha, duración, ejercicios).
- `food_entry.dart` — `FoodEntry` + enum `MealType`: alimento registrado en el diario de nutrición.
- `nutrition_goals.dart` — `NutritionGoals`: objetivos diarios calculados (kcal + macros).
- `nutrition_summary.dart` — `NutritionSummary`: agrega lo consumido en un día y lo compara con los objetivos.

## 2. Pantallas (`lib/screens/`)

### auth
- `login_screen.dart` — inicio de sesión.
- `register_screen.dart` — registro con datos corporales y objetivo.
- `splash_screen.dart` — detecta si hay sesión activa (stream de FirebaseAuth) y redirige.

### home
- `home_screen.dart` — contenedor con la barra de navegación de 4 tabs.

### nutrition
- `nutrition_screen.dart` — dashboard diario: anillo de calorías, barras de macros, navegación por día, comidas (desayuno/almuerzo/cena/snacks), swipe para eliminar.
- `add_food_sheet.dart` — hoja inferior para agregar alimento: buscar en la base local (macros automáticos por gramos) o entrada manual.

### profile
- `profile_screen.dart` — ver/editar perfil completo (peso, altura, edad, sexo, actividad, objetivo), foto de perfil (Firebase Storage) y cerrar sesión.

### progress
- `progress_screen.dart` — gráfica de evolución de peso por ejercicio (fl_chart), filtrada por grupo muscular.

### training
- `training_screen.dart` — menú del módulo: empezar entrenamiento, rutinas.
- `workout_list_screen.dart` — lista de rutinas: crear, eliminar, abrir.
- `workout_detail_screen.dart` — ver una rutina, ir a editarla.
- `workout_form_screen.dart` — crear/editar rutina: título, grupo, ejercicios y series.
- `workout_session_screen.dart` — entrenar (con rutina o libre): cronómetro, registrar series/pesos, guardar sesión.
- `empty_workout_screen.dart` — entrenamiento rápido desde cero con cronómetro.
- `exercise_picker_screen.dart` — selector de ejercicio de un grupo muscular.

## 3. Servicios / lógica de Firebase (`lib/services/`)

- `auth_service.dart` — registro/login/logout con FirebaseAuth. Lanza `AuthException` con mensajes en español; hace rollback si el registro falla a medias.
- `workout_service.dart` — CRUD de rutinas en `users/{uid}/workouts`.
- `training_session_service.dart` — guardar/leer sesiones en `users/{uid}/training_sessions`.
- `nutrition_service.dart` — diario de nutrición en `users/{uid}/nutrition_entries` (consultas por día).

## 4. Utilidades (`lib/utils/`)

- `validators.dart` — validadores de formularios y parsers numéricos seguros (aceptan coma decimal).
- `user_options.dart` — **fuente única** de opciones de perfil: sexos, niveles de actividad y objetivos (valor guardado → etiqueta).
- `exercise_list.dart` — **fuente única** de grupos musculares y ejercicios. ⚠️ Los nombres de ejercicio son la clave del histórico en Firestore: no renombrar a la ligera.
- `nutrition_calculator.dart` — lógica pura de nutrición: BMR (Mifflin-St Jeor) → TDEE por actividad → ajuste por objetivo → reparto de macros.
- `food_database.dart` — base local de alimentos comunes (valores por 100 g).

## 5. Widgets compartidos (`lib/widgets/`)

- `custom_button.dart` / `custom_textfield.dart` — componentes básicos reutilizables.
- `series_config_dialog.dart` — diálogo para configurar series (reps/peso) de un ejercicio; gestiona sus propios controllers.

## 6. Raíz

- `main.dart` — init de Firebase (con pantalla de error si falla), **tema centralizado** (colores de marca aquí, no en las pantallas) y rutas.
- `firebase_options.dart` — generado por `flutterfire configure`.

## Seguridad (raíz del repo)

- `firestore.rules` / `storage.rules` — cada usuario solo accede a sus propios datos. Desplegar con `firebase deploy --only firestore:rules,storage`.

## Tests (`test/`)

- `nutrition_calculator_test.dart` — fórmulas de BMR/TDEE/macros.
- `widget_test.dart` — agregación del diario (NutritionSummary).
- `validators_test.dart` — parsers y validadores.
- `auth_service_test.dart` — mapeo de errores de FirebaseAuth a mensajes.
- `user_options_test.dart` — consistencia opciones de perfil ↔ calculador.
- `exercise_list_test.dart` — consistencia de grupos/ejercicios.

Ejecutar: `flutter test` · Análisis estático: `flutter analyze`

---

## **IDEAS A CONSIDERAR:**

Propuesta extra tabs o secciones diferenciales
1. Tab hábitos / Bienestar:
    - Registro de sueño (horas/día)
    - Registro de agua consumida
    - Checklist de hábitos (hice cardio, comí verduras, etc.)
2. Comunidad:
    - Feed donde los usuarios pueden compartir logros
    - Ranking de progreso
3. Tab asistente IA:
    - Recomendaciones de comidas o rutina según progreso
4. Explorar rutinas prediseñadas (placeholder existente en training_screen; usar nombres canónicos de exercise_list.dart)
