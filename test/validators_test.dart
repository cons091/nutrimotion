import 'package:flutter_test/flutter_test.dart';
import 'package:nutrimotion/utils/validators.dart';

void main() {
  group('Validators.parseDouble', () {
    test('acepta punto y coma decimal', () {
      expect(Validators.parseDouble('70.5'), 70.5);
      expect(Validators.parseDouble('70,5'), 70.5);
      expect(Validators.parseDouble(' 70,5 '), 70.5);
    });

    test('devuelve null para texto no numérico (el bug del crash)', () {
      expect(Validators.parseDouble('abc'), isNull);
      expect(Validators.parseDouble(''), isNull);
      expect(Validators.parseDouble(null), isNull);
      expect(Validators.parseDouble('70kg'), isNull);
    });
  });

  group('Validators.parseInt', () {
    test('parsea enteros y rechaza el resto', () {
      expect(Validators.parseInt('25'), 25);
      expect(Validators.parseInt(' 25 '), 25);
      expect(Validators.parseInt('25.5'), isNull);
      expect(Validators.parseInt('abc'), isNull);
      expect(Validators.parseInt(null), isNull);
    });
  });

  group('validadores de formulario', () {
    test('email', () {
      expect(Validators.email('user@mail.com'), isNull);
      expect(Validators.email('sin-arroba'), isNotNull);
      expect(Validators.email('a@b'), isNotNull); // sin dominio
      expect(Validators.email(''), isNotNull);
    });

    test('password: mínimo 6 caracteres', () {
      expect(Validators.password('123456'), isNull);
      expect(Validators.password('12345'), isNotNull);
      expect(Validators.password(null), isNotNull);
    });

    test('edad: entero entre 12 y 100', () {
      expect(Validators.edad('25'), isNull);
      expect(Validators.edad('11'), isNotNull);
      expect(Validators.edad('101'), isNotNull);
      expect(Validators.edad('abc'), isNotNull);
      expect(Validators.edad('25.5'), isNotNull);
    });

    test('peso: entre 25 y 400 kg, acepta coma', () {
      expect(Validators.peso('70'), isNull);
      expect(Validators.peso('70,5'), isNull);
      expect(Validators.peso('20'), isNotNull);
      expect(Validators.peso('500'), isNotNull);
      expect(Validators.peso('texto'), isNotNull);
    });

    test('altura: entre 90 y 250 cm', () {
      expect(Validators.altura('175'), isNull);
      expect(Validators.altura('175,5'), isNull);
      expect(Validators.altura('80'), isNotNull);
      expect(Validators.altura('260'), isNotNull);
      expect(Validators.altura(''), isNotNull);
    });
  });
}
