import 'dart:async';
import 'package:logging/logging.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/application/artifact/ports/ports.dart';
import 'package:sambura_core/domain/entities/entities.dart';
import 'package:sambura_core/domain/exceptions/exceptions.dart';
import 'package:sambura_core/domain/repositories/repositories.dart';

class GetArtifactUseCase {
  final ArtifactRepository _artifactRepository;
  final PackageRepository _packageRepository;
  final RepositoryRepository _repositoryRepository;
  final RegistryProxyPort _proxyPort;
  final Logger _log = LoggerConfig.getLogger('GetArtifactUseCase');

  GetArtifactUseCase(
    this._artifactRepository,
    this._packageRepository,
    this._repositoryRepository,
    this._proxyPort,
  );

  Future<ArtifactEntity?> execute({
    required String repositoryName,
    required String packageName,
    required String version,
  }) async {
    _log.info('Buscando: $repositoryName/$packageName@$version');

    // 1. Tenta buscar direto pelo novo método (Substitui busca por path e namespace fixo)
    _log.fine('Verificando se o artefato já existe no Samburá');
    final local = await _artifactRepository.findOne(
      repositoryName,
      packageName,
      version,
    );

    if (local != null) {
      _log.info('📦 Cache Hit! Artefato encontrado: ${local.path}');
      return local;
    }

    // 2. Se não achou local, precisamos do Repo para ver se ele é Proxy
    final repository = await _repositoryRepository.getByName(repositoryName);
    if (repository == null) {
      _log.warning('Repositório $repositoryName não existe');
      throw RepositoryNotFoundException(repositoryName);
    }

    // 3. Lógica de Proxy (Só entra se não for um repo privado sem o arquivo)
    if (repository.isPublic && repository.namespace == 'npm') {
      _log.info(
        '🌐 Cache Miss. Iniciando busca no Proxy NPM para $packageName@$version',
      );
      try {
        final package = await _packageRepository.ensurePackage(
          repositoryId: repository.id!,
          name: packageName,
        );

        final blob = await _proxyPort.fetchAndStore(packageName, version);

        final newArtifact = ArtifactEntity.create(
          packageId: package.id!,
          namespace: repository.namespace,
          packageName: package.name,
          version: version,
          path: "$packageName-$version.tgz",
          blob: blob.blob!,
        );

        final saved = await _artifactRepository.save(newArtifact);
        _log.info('✅ Artefato sincronizado via proxy');
        return saved;
      } catch (e, stack) {
        _log.severe('Falha crítica no proxy NPM', e, stack);
        return null;
      }
    }

    _log.warning(
      '🚫 Artefato não encontrado e o repositório "$repositoryName" não possui upstream.',
    );
    return null;
  }
}
