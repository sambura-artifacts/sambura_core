import 'package:logging/logging.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/domain/entities/artifact_entity.dart';
import 'package:sambura_core/domain/repositories/artifact_repository.dart';

class GetArtifactByIdUseCase {
  final ArtifactRepository _repository;
  final Logger _log = LoggerConfig.getLogger('GetArtifactByIdUseCase');

  GetArtifactByIdUseCase(this._repository);

  Future<ArtifactEntity?> execute(String externalId) async {
    _log.info('Buscando artefato por ID: $externalId');

    final result = await _repository.getByExternalId(externalId);

    if (result == null) {
      _log.warning('Artefato não encontrado: $externalId');
    } else {
      _log.info('Artefato encontrado: ${result.packageName}@${result.version}');
    }

    return result;
  }
}
