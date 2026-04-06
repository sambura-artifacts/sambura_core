import 'dart:async';
import 'package:logging/logging.dart';

import 'package:sambura_core/config/barrel.dart';
import 'package:sambura_core/domain/barrel.dart';
import 'package:sambura_core/application/barrel.dart';

class NpmGetArtifactUseCase {
  final ArtifactRepository _artifactRepository;
  final PackageRepository _packageRepository;
  final NamespaceRepository _namespaceRepository;
  final RegistryProxyPort _proxyPort;
  final Logger _log = LoggerConfig.getLogger('NpmGetArtifactUseCase');

  NpmGetArtifactUseCase(
    this._artifactRepository,
    this._packageRepository,
    this._namespaceRepository,
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
    final repository = await _namespaceRepository.getByName(repositoryName);
    if (repository == null) {
      _log.warning('Repositório $repositoryName não existe');
      throw RepositoryNotFoundException(repositoryName);
    }

    // 3. Lógica de Proxy (Só entra se não for um repo privado sem o arquivo)
    if (repository.isPublic && repository.escope == 'npm') {
      _log.info(
        '🌐 Cache Miss. Iniciando busca no Proxy NPM para $packageName@$version',
      );
      try {
        final package = await _packageRepository.ensurePackage(
          namespaceId: repository.id!,
          name: packageName,
        );

        final blob = await _proxyPort.fetchAndStore(packageName, version);

        final newArtifact = ArtifactEntity.create(
          packageId: package.id!,
          namespace: repository.escope,
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
