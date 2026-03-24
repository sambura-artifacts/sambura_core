import 'package:sambura_core/domain/exceptions/domain_exception.dart';
import 'package:sambura_core/domain/value_objects/email.dart';
import 'package:test/test.dart';

void main() {
  group('Email', () {
    test('deve aceitar email válido', () {
      // Arrange & Act
      final email = Email('user@example.com');

      // Assert
      expect(email.value, equals('user@example.com'));
    });

    test('deve converter email para lowercase', () {
      // Arrange & Act
      final email = Email('User@Example.COM');

      // Assert
      expect(email.value, equals('user@example.com'));
    });

    test('deve remover espaços em branco', () {
      // Arrange & Act
      final email = Email('  user@example.com  ');

      // Assert
      expect(email.value, equals('user@example.com'));
    });

    test('deve rejeitar email vazio', () {
      // Act & Assert
      expect(() => Email(''), throwsA(isA<EmailException>()));
    });

    test('deve rejeitar email com apenas espaços', () {
      // Act & Assert
      expect(() => Email('   '), throwsA(isA<EmailException>()));
    });

    test('deve rejeitar email muito longo (mais de 255 caracteres)', () {
      // Arrange
      final longEmail = '${'a' * 250}@example.com';

      // Act & Assert
      expect(() => Email(longEmail), throwsA(isA<EmailException>()));
    });

    test('deve rejeitar email sem @', () {
      // Act & Assert
      expect(() => Email('invalid.email.com'), throwsA(isA<EmailException>()));
    });

    test('deve rejeitar email sem domínio', () {
      // Act & Assert
      expect(() => Email('user@'), throwsA(isA<EmailException>()));
    });

    test('deve rejeitar email sem nome de usuário', () {
      // Act & Assert
      expect(() => Email('@example.com'), throwsA(isA<EmailException>()));
    });

    test('deve aceitar emails com caracteres especiais válidos', () {
      // Act
      final email1 = Email('user.name@example.com');
      final email2 = Email('user+tag@example.com');
      final email3 = Email('user_name@example.co.uk');

      // Assert
      expect(email1.value, equals('user.name@example.com'));
      expect(email2.value, equals('user+tag@example.com'));
      expect(email3.value, equals('user_name@example.co.uk'));
    });

    test('deve implementar toString corretamente', () {
      // Arrange
      final email = Email('test@example.com');

      // Act & Assert
      expect(email.toString(), equals('test@example.com'));
    });

    test('deve implementar equality corretamente', () {
      // Arrange
      final email1 = Email('test@example.com');
      final email2 = Email('TEST@EXAMPLE.COM');
      final email3 = Email('different@example.com');

      // Assert
      expect(email1, equals(email2)); // Case-insensitive
      expect(email1, isNot(equals(email3)));
      expect(email1.hashCode, equals(email2.hashCode));
    });
  });
}
