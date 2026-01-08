import 'package:sambura_core/domain/exceptions/exceptions.dart';

class ArtifactNotFoundException extends DomainException {
  ArtifactNotFoundException(String package)
    : super('Artefato "$package" não encontrado.');
}
