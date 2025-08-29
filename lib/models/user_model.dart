class AppUser {
  final String uid;
  final String email;
  final double? peso;
  final double? altura;
  final String? objetivo; // déficit, mantenimiento, superávit

  AppUser({
    required this.uid,
    required this.email,
    this.peso,
    this.altura,
    this.objetivo,
  });

  Map<String, dynamic> toMap() {
    return {
      "uid": uid,
      "email": email,
      "peso": peso,
      "altura": altura,
      "objetivo": objetivo,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map["uid"],
      email: map["email"],
      peso: map["peso"]?.toDouble(),
      altura: map["altura"]?.toDouble(),
      objetivo: map["objetivo"],
    );
  }
}
