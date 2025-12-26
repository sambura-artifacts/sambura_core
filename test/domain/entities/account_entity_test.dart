import 'package:sambura_core/domain/entities/account_entity.dart';
import 'package:test/test.dart';

void main() {
  group('AccountEntity', () {
    group('create', () {
      test('deve criar conta com valores corretos', () {
        // Arrange
        const username = 'testuser';
        const password = 'Pass123!Word';
        const email = 'test@example.com';
        const role = 'admin';

        // Act
        final account = AccountEntity.create(
          username: username,
          password: password,
          email: email,
          role: role,
        );

        // Assert
        expect(account.id, isNull);
        expect(account.username.value, equals(username));
        expect(account.password!.value, equals(password));
        expect(account.email.value, equals(email));
        expect(account.role.value, equals(role));
        expect(account.externalId.value, isNotEmpty);
        expect(account.createdAt, isNotNull);
        expect(account.lastLoginAt, isNull);
      });

      test('deve usar role padrão developer quando não especificado', () {
        // Act
        final account = AccountEntity.create(
          username: 'testuser',
          password: 'Pass123!Word',
          email: 'test@example.com',
        );

        // Assert
        expect(account.role.value, equals('developer'));
      });

      test('deve gerar externalId único', () {
        // Act
        final account1 = AccountEntity.create(
          username: 'user1',
          password: 'Pass123!Word',
          email: 'user1@example.com',
        );
        final account2 = AccountEntity.create(
          username: 'user2',
          password: 'Pass123!Word',
          email: 'user2@example.com',
        );

        // Assert
        expect(
          account1.externalId.value,
          isNot(equals(account2.externalId.value)),
        );
      });
    });

    group('restore', () {
      test('deve restaurar conta completa do banco de dados', () {
        // Arrange
        const id = 1;
        const externalId = '01936d3c-8f4a-7890-b123-456789abcdef';
        const username = 'restored-user';
        const password = 'Hash123!Xyz@';
        const email = 'restored@example.com';
        const role = 'admin';
        final createdAt = DateTime.parse('2024-01-01T10:00:00Z');
        final lastLoginAt = DateTime.parse('2024-01-15T10:00:00Z');

        // Act
        final account = AccountEntity.restore(
          id: id,
          externalId: externalId,
          username: username,
          password: password,
          email: email,
          role: role,
          createdAt: createdAt,
          lastLoginAt: lastLoginAt,
        );

        // Assert
        expect(account.id, equals(id));
        expect(account.externalId.value, equals(externalId));
        expect(account.username.value, equals(username));
        expect(account.password!.value, equals(password));
        expect(account.email.value, equals(email));
        expect(account.role.value, equals(role));
        expect(account.createdAt, equals(createdAt));
        expect(account.lastLoginAt, equals(lastLoginAt));
      });

      test('deve restaurar conta sem lastLoginAt', () {
        // Arrange
        final createdAt = DateTime.now();

        // Act
        final account = AccountEntity.restore(
          id: 1,
          externalId: '01936d3c-8f4a-7890-b123-456789abcdef',
          username: 'user',
          password: 'Hash123!Xyz@',
          email: 'user@example.com',
          role: 'developer',
          createdAt: createdAt,
        );

        // Assert
        expect(account.id, equals(1));
        expect(account.lastLoginAt, isNull);
      });
    });

    group('changePassword', () {
      test('deve criar nova instância com senha alterada', () {
        // Arrange
        final originalAccount = AccountEntity.restore(
          id: 1,
          externalId: '01936d3c-8f4a-7890-b123-456789abcdef',
          username: 'user',
          password: 'OldHash123!',
          email: 'user@example.com',
          role: 'developer',
          createdAt: DateTime.now(),
        );
        const newPassword = 'NewHash456!';

        // Act
        final updatedAccount = originalAccount.changePassword(newPassword);

        // Assert
        expect(updatedAccount.password!.value, equals(newPassword));
        expect(updatedAccount.id, equals(originalAccount.id));
        expect(
          updatedAccount.username.value,
          equals(originalAccount.username.value),
        );
        expect(updatedAccount.email.value, equals(originalAccount.email.value));
        expect(
          updatedAccount.externalId.value,
          equals(originalAccount.externalId.value),
        );
      });

      test('deve manter imutabilidade - conta original não deve mudar', () {
        // Arrange
        const originalPassword = 'OldHash123!';
        final originalAccount = AccountEntity.restore(
          id: 1,
          externalId: '01936d3c-8f4a-7890-b123-456789abcdef',
          username: 'user',
          password: originalPassword,
          email: 'user@example.com',
          role: 'developer',
          createdAt: DateTime.now(),
        );

        // Act
        originalAccount.changePassword('NewHash456!');

        // Assert
        expect(originalAccount.password!.value, equals(originalPassword));
      });
    });

    group('getters', () {
      test('isAdmin deve retornar true para role admin', () {
        // Arrange
        final account = AccountEntity.create(
          username: 'admin',
          password: 'Pass123!Word',
          email: 'admin@example.com',
          role: 'admin',
        );

        // Act & Assert
        expect(account.isAdmin, isTrue);
      });

      test('isAdmin deve retornar false para role não-admin', () {
        // Arrange
        final developer = AccountEntity.create(
          username: 'dev',
          password: 'Pass123!Word',
          email: 'dev@example.com',
          role: 'developer',
        );
        final viewer = AccountEntity.create(
          username: 'viewer',
          password: 'Pass123!Word',
          email: 'viewer@example.com',
          role: 'viewer',
        );

        // Act & Assert
        expect(developer.isAdmin, isFalse);
        expect(viewer.isAdmin, isFalse);
      });

      test('passwordHash deve retornar o valor da senha', () {
        // Arrange
        const password = 'Hash123!Xyz@';
        final account = AccountEntity.restore(
          id: 1,
          externalId: '01936d3c-8f4a-7890-b123-456789abcdef',
          username: 'user',
          password: password,
          email: 'user@example.com',
          role: 'developer',
          createdAt: DateTime.now(),
        );

        // Act & Assert
        expect(account.password!.value, equals(password));
      });

      test('usernameValue deve retornar o valor do username', () {
        // Arrange
        const username = 'testuser';
        final account = AccountEntity.create(
          username: username,
          password: 'Pass123!Word',
          email: 'test@example.com',
        );

        // Act & Assert
        expect(account.username.value, equals(username));
      });

      test('externalIdValue deve retornar o valor do externalId', () {
        // Arrange
        const externalId = '01936d3c-8f4a-7890-b123-456789abcdef';
        final account = AccountEntity.restore(
          id: 1,
          externalId: externalId,
          username: 'user',
          password: 'Hash123!Xyz@',
          email: 'user@example.com',
          role: 'developer',
          createdAt: DateTime.now(),
        );

        // Act & Assert
        expect(account.externalId.value, equals(externalId));
      });

      test('roleValue deve retornar o valor da role', () {
        // Arrange
        const role = 'admin';
        final account = AccountEntity.create(
          username: 'admin',
          password: 'Pass123!Word',
          email: 'admin@example.com',
          role: role,
        );

        // Act & Assert
        expect(account.role.value, equals(role));
      });
    });
  });
}
