import 'package:sambura_core/domain/entities/account_entity.dart';
import 'package:sambura_core/domain/factories/account_factory.dart';
import 'package:test/test.dart';

void main() {
  group('AccountFactory', () {
    group('create', () {
      test('deve criar nova conta com campos obrigatórios', () {
        // Arrange
        const username = 'testuser';
        const password = 'Pass123!Word';
        const email = 'test@example.com';

        // Act
        final account = AccountFactory.create(
          username: username,
          password: password,
          email: email,
        );

        // Assert
        expect(account, isA<AccountEntity>());
        expect(account.username.value, equals(username));
        expect(account.password!.value, equals(password));
        expect(account.email.value, equals(email));
        expect(account.role.value, equals('developer')); // role padrão
        expect(account.externalId, isNotNull);
        expect(account.createdAt, isNotNull);
        expect(account.id, isNull);
      });

      test('deve criar conta com role personalizada', () {
        // Act
        final account = AccountFactory.create(
          username: 'admin',
          password: 'Pass123!',
          email: 'admin@example.com',
          role: 'admin',
        );

        // Assert
        expect(account.role.value, equals('admin'));
      });

      test('deve gerar externalId único', () {
        // Act
        final account1 = AccountFactory.create(
          username: 'user1',
          password: 'Pass123!',
          email: 'user1@example.com',
        );

        final account2 = AccountFactory.create(
          username: 'user2',
          password: 'Pass123!',
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
        final account = AccountFactory.restore(
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
        // Act
        final account = AccountFactory.restore(
          id: 1,
          externalId: '01936d3c-8f4a-7890-b123-456789abcdef',
          username: 'user',
          password: 'Hash123!Xyz@',
          email: 'user@example.com',
          role: 'developer',
          createdAt: DateTime.now(),
        );

        // Assert
        expect(account.id, equals(1));
        expect(account.lastLoginAt, isNull);
      });
    });

    group('diferença entre create e restore', () {
      test(
        'create deve gerar novo externalId, restore deve usar o fornecido',
        () {
          // Arrange
          const restoredExternalId =
              '01936d3c-8f4a-7890-b123-456789abcdef'; // UUID v7 válido

          // Act
          final created = AccountFactory.create(
            username: 'user',
            password: 'Pass123!',
            email: 'user@example.com',
          );

          final restored = AccountFactory.restore(
            id: 1,
            externalId: restoredExternalId,
            username: 'user',
            password: 'Hash123!Xyz',
            email: 'user@example.com',
            role: 'developer',
            createdAt: DateTime.now(),
          );

          // Assert
          expect(created.externalId.value, isNot(equals(restoredExternalId)));
          expect(restored.externalId.value, equals(restoredExternalId));
        },
      );

      test('create deve usar password sem hash, restore password', () {
        // Arrange
        const plainPassword = 'Pass123!Word';
        const hashedPassword = 'Hash123!Xyz';

        // Act
        final created = AccountFactory.create(
          username: 'user',
          password: plainPassword,
          email: 'user@example.com',
        );

        final restored = AccountFactory.restore(
          id: 1,
          externalId: '01936d3c-8f4a-7890-b123-456789abcdef',
          username: 'user',
          password: hashedPassword,
          email: 'user@example.com',
          role: 'developer',
          createdAt: DateTime.now(),
        );

        // Assert
        // Note: create não faz hash, apenas armazena como está
        expect(created.password!.value, equals(plainPassword));
        expect(restored.password!.value, equals(hashedPassword));
      });

      test('create não deve ter ID, restore deve ter', () {
        // Act
        final created = AccountFactory.create(
          username: 'user',
          password: 'Pass123!',
          email: 'user@example.com',
        );

        final restored = AccountFactory.restore(
          id: 42,
          externalId: '01936d3c-8f4a-7890-b123-456789abcdef',
          username: 'user',
          password: 'Hash123!Xyz',
          email: 'user@example.com',
          role: 'developer',
          createdAt: DateTime.now(),
        );

        // Assert
        expect(created.id, isNull);
        expect(restored.id, equals(42));
      });
    });
  });
}
