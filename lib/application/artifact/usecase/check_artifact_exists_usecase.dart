import 'package:sambura_core/domain/repositories/repositories.dart';

class CheckArtifactExistsUseCase {
  final ArtifactRepository _artifactRepository;

  CheckArtifactExistsUseCase(this._artifactRepository);

  Future<bool> execute({
    required String namespace,
    required String name,
    required String version,
  }) async {
    // Busca no banco se já existe esse registro
    final artifact = await _artifactRepository.findByNameAndVersion(
      namespace,
      name,
      version,
    );

    return artifact != null;
  }
}
