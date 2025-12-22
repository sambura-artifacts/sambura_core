import 'package:logging/logging.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/domain/entities/artifact_entity.dart';
import 'package:sambura_core/domain/exceptions/domain_exception.dart';
import 'package:sambura_core/domain/repositories/artifact_repository.dart';
import 'package:sambura_core/domain/repositories/blob_repository.dart';
import 'package:sambura_core/domain/repositories/package_repository.dart';
import 'package:sambura_core/domain/repositories/repository_repository.dart';
import 'package:sambura_core/infrastructure/api/dtos/artifact_input.dart';

class CreateArtifactUsecase {
  final ArtifactRepository _artifactRepository;
  final PackageRepository _packageRepository;
  final BlobRepository _blobRepository;
  final RepositoryRepository _repositoryRepository;
  final Logger _log = LoggerConfig.getLogger('CreateArtifactUsecase');

  CreateArtifactUsecase(
    this._artifactRepository,
    this._packageRepository,
    this._blobRepository,
    this._repositoryRepository,
  );

  Future<ArtifactEntity?> execute(
    ArtifactInput input,
    Stream<List<int>> fileStream,
  ) async {
    _log.info(
      'Iniciando criação de artefato: ${input.packageName}@${input.version}',
    );

    final repo = await _repositoryRepository.getByName(input.repositoryName);

    if (repo == null) {
      throw RepositoryNotFoundException(input.repositoryName);
    }

    _log.fine('Salvando blob a partir do stream de dados');
    final blob = await _blobRepository.saveFromStream(fileStream);

    _log.info('Blob salvo: ${blob.hashValue.substring(0, 12)}...');

    _log.fine('Buscando package: ${input.packageName}');
    final package = await _packageRepository.findByGlobalName(
      input.packageName,
    );

    _log.fine('Criando entidade Artifact');
    final artifact = ArtifactEntity.create(
      packageId: package!.id!,
      packageName: package.name,
      namespace: input.namespace,
      version: input.version,
      path: input.path,
      blob: blob,
    );

    _log.fine('Salvando artefato no banco de dados');
    final result = await _artifactRepository.save(artifact);

    if (result.isPersisted) throw Error();

    _log.info(
      'Artifact ${input.version} salvo com sucesso! ID: ${result.externalId}',
    );

    return result;
  }
}
