class AppUser {
  final String uid;
  final String email;
  final double? peso;
  final double? altura;
  final int? edad;
  final String? sexo;
  final String? actividad;
  final String? objetivo;

  AppUser({
    required this.uid,
    required this.email,
    this.peso,
    this.altura,
    this.edad,
    this.sexo,
    this.actividad,
    this.objetivo,
  });

  Map<String, dynamic> toMap() {
    return {
      "uid": uid,
      "email": email,
      "peso": peso,
      "altura": altura,
      "edad": edad,
      "sexo": sexo,
      "actividad": actividad,
      "objetivo": objetivo,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map["uid"],
      email: map["email"],
      peso: map["peso"]?.toDouble(),
      altura: map["altura"]?.toDouble(),
      edad: map["edad"],
      sexo: map["sexo"],
      actividad: map["actividad"],
      objetivo: map["objetivo"],
    );
  }
}
