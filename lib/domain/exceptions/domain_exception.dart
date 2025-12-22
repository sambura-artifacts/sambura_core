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
