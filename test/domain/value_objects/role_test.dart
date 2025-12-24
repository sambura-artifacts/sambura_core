import 'package:sambura_core/domain/exceptions/domain_exception.dart';
import 'package:sambura_core/domain/value_objects/role.dart';
import 'package:test/test.dart';

void main() {
  group('Role', () {
    test('deve aceitar role admin', () {
      // Act
      final role = Role('admin');

      // Assert
      expect(role.value, equals('admin'));
      expect(role.isAdmin, isTrue);
      expect(role.isDeveloper, isFalse);
    });

    test('deve aceitar role developer', () {
      // Act
      final role = Role('developer');

      // Assert
      expect(role.value, equals('developer'));
      expect(role.isAdmin, isFalse);
      expect(role.isDeveloper, isTrue);
    });

    test('deve aceitar role viewer', () {
      // Act
      final role = Role('viewer');

      // Assert
      expect(role.value, equals('viewer'));
      expect(role.isAdmin, isFalse);
      expect(role.isDeveloper, isFalse);
    });

    test('deve converter para lowercase', () {
      // Act
      final role = Role('ADMIN');

      // Assert
      expect(role.value, equals('admin'));
    });

    test('deve remover espaços em branco', () {
      // Act
      final role = Role('  developer  ');

      // Assert
      expect(role.value, equals('developer'));
    });

    test('deve rejeitar role inválida', () {
      // Act & Assert
      expect(() => Role('invalid'), throwsA(isA<RoleException>()));

      expect(() => Role('superuser'), throwsA(isA<RoleException>()));
    });

    test('deve implementar toString corretamente', () {
      // Arrange
      final role = Role('admin');

      // Act & Assert
      expect(role.toString(), equals('admin'));
    });

    test('deve implementar equality corretamente', () {
      // Arrange
      final role1 = Role('admin');
      final role2 = Role('ADMIN');
      final role3 = Role('developer');

      // Assert
      expect(role1, equals(role2)); // Case-insensitive
      expect(role1, isNot(equals(role3)));
      expect(role1.hashCode, equals(role2.hashCode));
    });

    test('deve usar constantes de Role', () {
      // Assert
      expect(Role.admin, equals('admin'));
      expect(Role.developer, equals('developer'));
      expect(Role.viewer, equals('viewer'));
    });
  });
}
