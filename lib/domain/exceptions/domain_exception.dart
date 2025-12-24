abstract class DomainException implements Exception {
  final String message;
  DomainException(this.message);
}

class RepositoryNotFoundException extends DomainException {
  RepositoryNotFoundException(String repository)
    : super('Repositório "$repository" não encontrado.');
}

class ArtifactNotFoundException extends DomainException {
  ArtifactNotFoundException(String package)
    : super('Artefato "$package" não encontrado.');
}

class ExternalIdInvalidException extends DomainException {
  ExternalIdInvalidException(String externalId)
    : super("ExternalId inválido $externalId");
}

class UsernameException extends DomainException {
  UsernameException(super.message);
}

class PasswordException extends DomainException {
  PasswordException(super.message);
}

class EmailException extends DomainException {
  EmailException(super.message);
}

class RoleException extends DomainException {
  RoleException(super.message);
}

class PackageNameException extends DomainException {
  PackageNameException(super.message);
}

class SemVerException extends DomainException {
  SemVerException(super.message);
}
