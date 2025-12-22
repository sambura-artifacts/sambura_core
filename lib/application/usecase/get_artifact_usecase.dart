import 'dart:async';
import 'package:logging/logging.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/domain/entities/artifact_entity.dart';
import 'package:sambura_core/domain/repositories/artifact_repository.dart';
import 'package:sambura_core/domain/repositories/package_repository.dart';
import 'package:sambura_core/domain/repositories/repository_repository.dart';
import 'package:sambura_core/infrastructure/services/npm_proxy_service.dart';

class GetArtifactUseCase {
  final ArtifactRepository _artifactRepository;
  final PackageRepository _packageRepository;
  final RepositoryRepository _repositoryRepository;
  final NpmProxyService _npmProxyService;
  final Logger _log = LoggerConfig.getLogger('GetArtifactUseCase');

  GetArtifactUseCase(
    this._artifactRepository,
    this._packageRepository,
    this._repositoryRepository,
    this._npmProxyService,
  );

  Future<ArtifactEntity?> execute({
    required String repositoryName,
    required String packageName,
    required String version,
  }) async {
    _log.info('Buscando: $repositoryName/$packageName@$version');

    final repository = await _repositoryRepository.getByName(repositoryName);

    if (repository == null) {
      _log.warning('Repositório $repositoryName não existe');
      throw Exception("Repositório '$repositoryName' não encontrado.");
    }

    final String namespace = repository.namespace;
    final String expectedPath = "$packageName-$version.tgz";

    _log.fine('Verificando cache local');
    final local = await _artifactRepository.getByPath(namespace, expectedPath);
    if (local != null) {
      _log.info('Cache Hit! Retornando arquivo local');
      return local;
    }

    if (repository.isPublic && namespace == 'npm') {
      _log.info('Cache Miss. Iniciando busca no Proxy NPM');
      try {
        final package = await _packageRepository.ensurePackage(
          repositoryId: repository.id!,
          name: packageName,
        );
        _log.fine('Pacote garantido: ID ${package.id}');

        _log.info('Baixando de upstream: $packageName@$version');
        final blob = await _npmProxyService.fetchAndStore(packageName, version);

        _log.fine('Blob obtido. Criando entidade Artifact');

        final newArtifact = ArtifactEntity.create(
          packageId: package.id!,
          namespace: namespace,
          packageName: package.name,
          version: version,
          path: expectedPath,
          blob: blob,
        );

        _log.fine('Salvando metadados do artefato no banco');
        final saved = await _artifactRepository.save(newArtifact);

        _log.info('Artefato sincronizado com sucesso via proxy');
        return saved;
      } catch (e, stack) {
        _log.severe(
          'Falha crítica no proxy NPM para $packageName@$version',
          e,
          stack,
        );
        return null;
      }
    }

    _log.warning('Artefato não encontrado e repositório não é proxy');
    return null;
  }
}
