import '../models/workout_model.dart';

List<SeriesEntry> generateSeries(int count, int reps) {
  return List.generate(count, (_) => SeriesEntry(reps: reps, weight: null));
}

class WorkoutTemplates {
  static List<Workout> getTemplates(String day) {
    const int defaultRest = 90;
    switch (day) {
      case "Piernas":
        return [
          Workout(
            id: "template_piernas_1",
            title: "Piernas - Fuerza",
            day: "Piernas",
            exercises: [
              Exercise(name: "Sentadilla", series: generateSeries(4, 6)),
              Exercise(
                name: "Peso muerto rumano",
                series: generateSeries(4, 8),
              ),
              Exercise(name: "Prensa", series: generateSeries(3, 10)),
              Exercise(name: "Zancadas", series: generateSeries(3, 12)),
            ],
            restTimeSeconds: defaultRest,
          ),
          Workout(
            id: "template_piernas_2",
            title: "Piernas - Hipertrofia",
            day: "Piernas",
            exercises: [
              Exercise(
                name: "Sentadilla frontal",
                series: generateSeries(4, 10),
              ),
              Exercise(name: "Peso muerto sumo", series: generateSeries(3, 12)),
              Exercise(name: "Hip Thrust", series: generateSeries(4, 12)),
              Exercise(
                name: "Extensión de cuádriceps",
                series: generateSeries(3, 15),
              ),
            ],
            restTimeSeconds: defaultRest,
          ),
        ];

      case "Pecho":
        return [
          Workout(
            id: "template_pecho_1",
            title: "Pecho - Fuerza",
            day: "Pecho",
            exercises: [
              Exercise(name: "Press banca plano", series: generateSeries(4, 5)),
              Exercise(
                name: "Press inclinado con mancuernas",
                series: generateSeries(4, 8),
              ),
              Exercise(name: "Fondos", series: generateSeries(3, 10)),
            ],
            restTimeSeconds: defaultRest,
          ),
          Workout(
            id: "template_pecho_2",
            title: "Pecho - Hipertrofia",
            day: "Pecho",
            exercises: [
              Exercise(
                name: "Press banca plano",
                series: generateSeries(4, 10),
              ),
              Exercise(
                name: "Press inclinado con barra",
                series: generateSeries(3, 12),
              ),
              Exercise(
                name: "Aperturas en banco",
                series: generateSeries(3, 12),
              ),
              Exercise(name: "Cruces en polea", series: generateSeries(3, 15)),
            ],
            restTimeSeconds: defaultRest,
          ),
        ];

      case "Espalda":
        return [
          Workout(
            id: "template_espalda_1",
            title: "Espalda - Fuerza",
            day: "Espalda",
            exercises: [
              Exercise(
                name: "Peso muerto convencional",
                series: generateSeries(4, 5),
              ),
              Exercise(
                name: "Dominadas lastradas",
                series: generateSeries(4, 6),
              ),
              Exercise(name: "Remo con barra", series: generateSeries(4, 8)),
            ],
            restTimeSeconds: defaultRest,
          ),
          Workout(
            id: "template_espalda_2",
            title: "Espalda - Hipertrofia",
            day: "Espalda",
            exercises: [
              Exercise(name: "Jalón en polea", series: generateSeries(3, 12)),
              Exercise(
                name: "Remo con mancuernas",
                series: generateSeries(3, 12),
              ),
              Exercise(name: "Face Pulls", series: generateSeries(3, 15)),
              Exercise(
                name: "Pull-over con mancuerna",
                series: generateSeries(3, 12),
              ),
            ],
            restTimeSeconds: defaultRest,
          ),
        ];

      case "Hombros":
        return [
          Workout(
            id: "template_hombros_1",
            title: "Hombros - Fuerza",
            day: "Hombros",
            exercises: [
              Exercise(name: "Press militar", series: generateSeries(4, 6)),
              Exercise(name: "Push Press", series: generateSeries(3, 5)),
              Exercise(name: "Remo al mentón", series: generateSeries(3, 8)),
            ],
            restTimeSeconds: defaultRest,
          ),
          Workout(
            id: "template_hombros_2",
            title: "Hombros - Hipertrofia",
            day: "Hombros",
            exercises: [
              Exercise(
                name: "Press militar con mancuernas",
                series: generateSeries(3, 12),
              ),
              Exercise(
                name: "Elevaciones laterales",
                series: generateSeries(3, 15),
              ),
              Exercise(
                name: "Elevaciones frontales",
                series: generateSeries(3, 12),
              ),
              Exercise(name: "Pájaros", series: generateSeries(3, 15)),
            ],
            restTimeSeconds: defaultRest,
          ),
        ];

      case "Brazos":
        return [
          Workout(
            id: "template_brazos_1",
            title: "Brazos - Fuerza",
            day: "Brazos",
            exercises: [
              Exercise(name: "Curl con barra", series: generateSeries(4, 6)),
              Exercise(
                name: "Press francés con barra",
                series: generateSeries(4, 6),
              ),
              Exercise(name: "Curl martillo", series: generateSeries(4, 8)),
            ],
            restTimeSeconds: defaultRest,
          ),
          Workout(
            id: "template_brazos_2",
            title: "Brazos - Hipertrofia",
            day: "Brazos",
            exercises: [
              Exercise(name: "Curl alternado", series: generateSeries(3, 12)),
              Exercise(
                name: "Extensiones en polea",
                series: generateSeries(3, 12),
              ),
              Exercise(name: "Curl concentrado", series: generateSeries(3, 12)),
              Exercise(
                name: "Patada de tríceps",
                series: generateSeries(3, 15),
              ),
            ],
            restTimeSeconds: defaultRest,
          ),
        ];

      case "FullBody":
        return [
          Workout(
            id: "template_fullbody_1",
            title: "FullBody - Fuerza",
            day: "FullBody",
            exercises: [
              Exercise(name: "Sentadilla", series: generateSeries(4, 5)),
              Exercise(name: "Press banca", series: generateSeries(4, 5)),
              Exercise(name: "Peso muerto", series: generateSeries(3, 5)),
              Exercise(name: "Press militar", series: generateSeries(3, 6)),
            ],
            restTimeSeconds: defaultRest,
          ),
          Workout(
            id: "template_fullbody_2",
            title: "FullBody - Hipertrofia",
            day: "FullBody",
            exercises: [
              Exercise(
                name: "Sentadilla frontal",
                series: generateSeries(3, 10),
              ),
              Exercise(
                name: "Press banca inclinado",
                series: generateSeries(3, 12),
              ),
              Exercise(
                name: "Peso muerto rumano",
                series: generateSeries(3, 12),
              ),
              Exercise(name: "Dominadas", series: generateSeries(3, 10)),
            ],
            restTimeSeconds: defaultRest,
          ),
        ];

      default:
        return [];
    }
  }
}
