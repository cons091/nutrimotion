import 'package:flutter_test/flutter_test.dart';
import 'package:nutrimotion/services/auth_service.dart';

void main() {
  group('AuthService.messageForCode', () {
    test('credenciales incorrectas agrupa los tres códigos equivalentes', () {
      const esperado = 'Correo o contraseña incorrectos';
      expect(AuthService.messageForCode('invalid-credential'), esperado);
      expect(AuthService.messageForCode('wrong-password'), esperado);
      expect(AuthService.messageForCode('user-not-found'), esperado);
    });

    test('códigos comunes tienen mensaje propio en español', () {
      expect(
        AuthService.messageForCode('email-already-in-use'),
        contains('Ya existe una cuenta'),
      );
      expect(
        AuthService.messageForCode('weak-password'),
        contains('contraseña'),
      );
      expect(
        AuthService.messageForCode('network-request-failed'),
        contains('conexión'),
      );
      expect(
        AuthService.messageForCode('too-many-requests'),
        contains('intentos'),
      );
    });

    test('código desconocido devuelve mensaje genérico con el código', () {
      final msg = AuthService.messageForCode('algo-raro');
      expect(msg, contains('Error de autenticación'));
      expect(msg, contains('algo-raro'));
    });
  });

  group('AuthException', () {
    test('toString devuelve el mensaje legible', () {
      final e = AuthException('Mensaje amigable', code: 'x');
      expect(e.toString(), 'Mensaje amigable');
      expect(e.code, 'x');
    });
  });
}
