import 'package:sambura_core/domain/exceptions/domain_exception.dart';
import 'package:sambura_core/domain/value_objects/username.dart';
import 'package:test/test.dart';

void main() {
  group('Username', () {
    test('deve aceitar username válido', () {
      // Arrange & Act
      final username = Username('valid_user-123');

      // Assert
      expect(username.value, equals('valid_user-123'));
    });

    test('deve rejeitar username vazio', () {
      // Act & Assert
      expect(() => Username(''), throwsA(isA<UsernameException>()));
    });

    test('deve rejeitar username com apenas espaços', () {
      // Act & Assert
      expect(() => Username('   '), throwsA(isA<UsernameException>()));
    });

    test('deve rejeitar username muito curto (menos de 3 caracteres)', () {
      // Act & Assert
      expect(() => Username('ab'), throwsA(isA<UsernameException>()));
    });

    test('deve rejeitar username muito longo (mais de 30 caracteres)', () {
      // Act & Assert
      expect(() => Username('a' * 31), throwsA(isA<UsernameException>()));
    });

    test('deve rejeitar username com caracteres inválidos', () {
      // Act & Assert
      expect(() => Username('user@invalid'), throwsA(isA<UsernameException>()));

      expect(() => Username('user name'), throwsA(isA<UsernameException>()));

      expect(() => Username('user#123'), throwsA(isA<UsernameException>()));
    });

    test('deve permitir username com underscores e hífens', () {
      // Act
      final username1 = Username('user_name');
      final username2 = Username('user-name');
      final username3 = Username('user_name-123');

      // Assert
      expect(username1.value, equals('user_name'));
      expect(username2.value, equals('user-name'));
      expect(username3.value, equals('user_name-123'));
    });

    test('deve implementar toString corretamente', () {
      // Arrange
      final username = Username('testuser');

      // Act & Assert
      expect(username.toString(), equals('testuser'));
    });

    test('deve implementar equality corretamente', () {
      // Arrange
      final username1 = Username('testuser');
      final username2 = Username('testuser');
      final username3 = Username('different');

      // Assert
      expect(username1, equals(username2));
      expect(username1, isNot(equals(username3)));
      expect(username1.hashCode, equals(username2.hashCode));
    });
  });
}
