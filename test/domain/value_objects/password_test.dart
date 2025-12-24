import 'package:sambura_core/domain/exceptions/domain_exception.dart';
import 'package:sambura_core/domain/value_objects/password.dart';
import 'package:test/test.dart';

void main() {
  group('Password', () {
    test('deve aceitar password válida', () {
      // Arrange & Act
      final password = Password('Pass123!Word');

      // Assert
      expect(password.value, equals('Pass123!Word'));
    });

    test('deve rejeitar password muito curta (menos de 8 caracteres)', () {
      // Act & Assert
      expect(() => Password('Pass1!'), throwsA(isA<PasswordException>()));
    });

    test('deve rejeitar password muito longa (mais de 72 caracteres)', () {
      // Arrange
      final longPassword = 'A1a!' + ('x' * 70);

      // Act & Assert
      expect(() => Password(longPassword), throwsA(isA<PasswordException>()));
    });

    test('deve rejeitar password sem letra maiúscula', () {
      // Act & Assert
      expect(() => Password('password123!'), throwsA(isA<PasswordException>()));
    });

    test('deve rejeitar password sem letra minúscula', () {
      // Act & Assert
      expect(() => Password('PASSWORD123!'), throwsA(isA<PasswordException>()));
    });

    test('deve rejeitar password sem números', () {
      // Act & Assert
      expect(() => Password('Password!'), throwsA(isA<PasswordException>()));
    });

    test('deve rejeitar password sem caracteres especiais', () {
      // Act & Assert
      expect(() => Password('Password123'), throwsA(isA<PasswordException>()));
    });

    test('deve aceitar password com diferentes caracteres especiais', () {
      // Act
      final password1 = Password('Pass123@word');
      final password2 = Password('Pass123#word');
      final password3 = Password(r'Pass123$word');
      final password4 = Password('Pass123%word');

      // Assert
      expect(password1.value, equals('Pass123@word'));
      expect(password2.value, equals('Pass123#word'));
      expect(password3.value, equals(r'Pass123$word'));
      expect(password4.value, equals('Pass123%word'));
    });

    test('deve aceitar password no limite mínimo (8 caracteres)', () {
      // Act
      final password = Password('Pass123!');

      // Assert
      expect(password.value, equals('Pass123!'));
    });

    test('deve aceitar password no limite máximo (72 caracteres)', () {
      // Arrange
      final maxPassword = 'A1a!' + ('x' * 68);

      // Act
      final password = Password(maxPassword);

      // Assert
      expect(password.value.length, equals(72));
    });

    test('toString deve ocultar a senha por segurança', () {
      // Arrange
      final password = Password('Pass123!Word');

      // Act & Assert
      expect(password.toString(), equals('********'));
      expect(password.toString(), isNot(contains('Pass123!Word')));
    });
  });
}
