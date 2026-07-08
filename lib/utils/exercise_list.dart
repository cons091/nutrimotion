/// Fuente única de grupos musculares y ejercicios.
///
/// La consumen:
/// - `ExercisePickerScreen` (elegir ejercicio al entrenar/crear rutina)
/// - los selectores de grupo de `empty_workout_screen` y `workout_form_screen`
/// - `progress_screen` (filtro de la gráfica de progreso)
///
/// Antes cada pantalla tenía su propia lista hardcodeada y estaban
/// desincronizadas: los diálogos ofrecían "Brazos"/"FullBody" pero el picker
/// solo conocía "Bíceps"/"Tríceps" (picker vacío), y Progreso comparaba por
/// nombre exacto contra una lista distinta a la del picker (gráfica sin
/// datos). Los nombres de ejercicio son la CLAVE con la que se guardan las
/// sesiones en Firestore: cambiar uno aquí "desconecta" el histórico previo.
class ExerciseList {
  const ExerciseList._();

  /// Grupos canónicos, en el orden en que se muestran.
  /// "Brazos" agrupa bíceps y tríceps; los datos guardados usan estas claves.
  static const List<String> groups = [
    "Pecho",
    "Espalda",
    "Piernas",
    "Hombros",
    "Brazos",
    "FullBody",
  ];

  /// Etiqueta visible para un grupo (solo difiere en FullBody).
  static String labelFor(String group) =>
      group == "FullBody" ? "Full Body" : group;

  static const Map<String, List<String>> exercisesByGroup = {
    "Pecho": [
      "Press de banca con barra",
      "Press inclinado con mancuernas",
      "Press declinado con barra",
      "Press en máquina Smith",
      "Aperturas con mancuernas en banco plano",
      "Aperturas en banco inclinado",
      "Peck deck (contractora)",
      "Cruces en polea alta",
      "Fondos en paralelas (inclinados hacia adelante)",
      "Push-ups con peso",
    ],
    "Espalda": [
      "Dominadas (pull-ups o chin-ups)",
      "Remo con barra",
      "Remo con mancuerna",
      "Remo en máquina Hammer",
      "Remo en polea baja",
      "Jalón al pecho con agarre amplio",
      "Jalón tras nuca",
      "Peso muerto convencional",
      "Peso muerto rumano",
      "Pull-over en polea",
    ],
    "Piernas": [
      "Sentadilla con barra (back squat)",
      "Sentadilla frontal",
      "Sentadilla en Smith",
      "Prensa inclinada",
      "Zancadas caminando con mancuernas",
      "Step-up al cajón",
      "Peso muerto rumano (femorales)",
      "Curl femoral en máquina",
      "Extensiones de cuádriceps en máquina",
      "Elevaciones de talones (gemelos)",
    ],
    "Hombros": [
      "Press militar con barra",
      "Press militar con mancuernas",
      "Press Arnold",
      "Press tras nuca",
      "Elevaciones laterales con mancuernas",
      "Elevaciones frontales",
      "Pájaros (elevaciones posteriores)",
      "Remo al mentón con barra",
      "Face pulls en polea",
      "Encogimientos con mancuernas (trapecios)",
    ],
    // Bíceps + tríceps unificados: los selectores de grupo siempre
    // ofrecieron "Brazos" y así se guarda en las rutinas existentes.
    "Brazos": [
      "Curl con barra recta",
      "Curl con barra Z",
      "Curl con mancuernas alterno",
      "Curl martillo",
      "Curl concentrado",
      "Curl en banco Scott",
      "Curl en polea baja con barra recta",
      "Curl en polea con cuerda",
      "Fondos en paralelas",
      "Press cerrado con barra",
      "Extensión con mancuerna tras nuca",
      "Extensión en polea con barra recta",
      "Extensión en polea con cuerda",
      "Press francés con barra Z",
      "Press francés con mancuernas",
      "Kickbacks con mancuernas",
      "Skull crushers con barra",
    ],
    // Básicos compuestos. Mismos nombres que en sus grupos de origen para
    // que Progreso encuentre el ejercicio sin importar cómo se entrenó.
    "FullBody": [
      "Sentadilla con barra (back squat)",
      "Sentadilla frontal",
      "Press de banca con barra",
      "Peso muerto convencional",
      "Peso muerto rumano",
      "Press militar con barra",
      "Dominadas (pull-ups o chin-ups)",
      "Remo con barra",
      "Zancadas caminando con mancuernas",
    ],
  };
}
