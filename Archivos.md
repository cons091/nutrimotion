# Explicacion de Archivos

1. lib/models:
    - user_model.dart = datos extra del usuario (peso, altura, objetivo, etc)
    - workout_model.dart = Modelo de rutina y ejercicio
2. lib/providers: 
    - soy texto
## Pantallas Principales
3. lib/screens:
    - auth
        - login_screen.dart = Inicio de sesion
        - register_screen.dart = Registro de usuario
        - splash_screen.dart = Pantalla que detecta si hay sesion activa
    - home
        - home_screen.dart = Inicio
    - nutrition
        - nutrition_screen.dart = 
    - profile
        - profile_screen.dart = 
    - progress
        - progress_screen.dart = 
    - training
        - training_screen.dart = 
        - workout_list_screen: Lista de rutinas, permite crear, eliminar y abrir rutinas.
        - workout_detail_screen: Visualiza una rutina, permite editarla.
        - workout_form_screen.dart = Crear o editar una rutina, añadir/eliminar ejercicios, editar series.
        - workout_session_screen: Iniciar entrenamiento, registrar series y pesos, luego guardar.
### Logica de Firebase
4. lib/services:
    - auth_service.dart = aquí va login/register con FirebaseAuth
    - firestore_service.dart = 
    - storage_service.dart = 
    - workout_service.dart = 
5. lib/utils:
    - validators.dart = 
6. lib/widgets
    - custom_button.dart = 
    - custom_textfield.dart = 
7. firebase_options.dart = 
8. main.dart = 


- lib/services/auth_service.dart → manejar registro y login con Firebase.
- lib/models/user_model.dart → clase para guardar datos extra del usuario.
- lib/screens/auth/register_screen.dart → formulario de registro.


## **IDEAS A CONSIDERAR:**

Propuesta extra tabs o secciones diferenciales
1. Tab habitos / Bienestar : 
    - Registro de sueño (horas/dia) 
    - Registro de agua consumida 
    - Checklist de habitos (hice cardio, comi verduras, etc..)
2. Comunidad :
    - Feed donde los usuarios pueden compartir logros
    - Ranking de progreso
3. Tab asistente IA:
    - Recomendaciones de comidas o rutina segun progreso