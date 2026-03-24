import 'package:sambura_core/domain/exceptions/domain_exception.dart';
import 'package:test/test.dart';

void main() {
  group('DomainException', () {
    test('RepositoryNotFoundException deve ter mensagem formatada', () {
      // Arrange
      const repoName = 'my-repo';

      // Act
      final exception = RepositoryNotFoundException(repoName);

      // Assert
      expect(
        exception.message,
        equals('Repositório "my-repo" não encontrado.'),
      );
      expect(exception, isA<DomainException>());
    });

    test('ArtifactNotFoundException deve ter mensagem formatada', () {
      // Arrange
      const packageName = 'my-package';

      // Act
      final exception = ArtifactNotFoundException(packageName);

      // Assert
      expect(
        exception.message,
        equals('Artefato "my-package" não encontrado.'),
      );
      expect(exception, isA<DomainException>());
    });

    test('ExternalIdInvalidException deve ter mensagem formatada', () {
      // Arrange
      const externalId = 'invalid-id';

      // Act
      final exception = ExternalIdInvalidException(externalId);

      // Assert
      expect(exception.message, equals('ExternalId inválido invalid-id'));
      expect(exception, isA<DomainException>());
    });

    test('UsernameException deve ter mensagem personalizada', () {
      // Arrange
      const message = 'Username inválido';

      // Act
      final exception = UsernameException(message);

      // Assert
      expect(exception.message, equals(message));
      expect(exception, isA<DomainException>());
    });

    test('PasswordException deve ter mensagem personalizada', () {
      // Arrange
      const message = 'Password muito curta';

      // Act
      final exception = PasswordException(message);

      // Assert
      expect(exception.message, equals(message));
      expect(exception, isA<DomainException>());
    });

    test('EmailException deve ter mensagem personalizada', () {
      // Arrange
      const message = 'Email inválido';

      // Act
      final exception = EmailException(message);

      // Assert
      expect(exception.message, equals(message));
      expect(exception, isA<DomainException>());
    });

    test('RoleException deve ter mensagem personalizada', () {
      // Arrange
      const message = 'Role não permitida';

      // Act
      final exception = RoleException(message);

      // Assert
      expect(exception.message, equals(message));
      expect(exception, isA<DomainException>());
    });

    test('PackageNameException deve ter mensagem personalizada', () {
      // Arrange
      const message = 'Package name inválido';

      // Act
      final exception = PackageNameException(message);

      // Assert
      expect(exception.message, equals(message));
      expect(exception, isA<DomainException>());
    });

    test('SemVerException deve ter mensagem personalizada', () {
      // Arrange
      const message = 'Versão semântica inválida';

      // Act
      final exception = SemVerException(message);

      // Assert
      expect(exception.message, equals(message));
      expect(exception, isA<DomainException>());
    });
  });
}
