import 'dart:async';
import 'package:logging/logging.dart';
import 'package:sambura_core/application/usecase/artifact/get_artifact_download_stream_usecase.dart';
import 'package:sambura_core/application/usecase/artifact/package_handler/package_handler_factory.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/domain/repositories/repository_repository.dart';
import 'package:sambura_core/infrastructure/api/dtos/artifact_input.dart';

class DownloadAndProxyArtifactUsecase {
  final GetArtifactDownloadStreamUsecase _getArtifactDownloadStreamUsecase;
  final RepositoryRepository _repositoryRepository;
  final PackageHandlerFactory _packageHandlerFactory;
  final Logger _log = LoggerConfig.getLogger('DownloadAndProxyArtifactUsecase');

  DownloadAndProxyArtifactUsecase(
    this._getArtifactDownloadStreamUsecase,
    this._repositoryRepository,
    this._packageHandlerFactory,
  );

  Future<Stream<List<int>>?> execute(ArtifactInput input) async {
    // 1. Tenta buscar o artefato localmente
    _log.info(
      'Buscando artefato localmente: ${input.namespace}/${input.packageName}@${input.version}',
    );
    final localArtifact = await _getArtifactDownloadStreamUsecase.execute(
      namespace: input.namespace,
      name: input.packageName,
      version: input.version,
    );

    if (localArtifact != null) {
      _log.info('Artefato encontrado localmente. Iniciando stream...');
      return localArtifact.stream;
    }

    _log.info('Artefato não encontrado localmente, tentando proxy...');
    // 2. Se não encontrar, busca as configurações do repositório
    final repository = await _repositoryRepository.getByName(input.namespace);
    if (repository == null) {
      throw Exception('Repositório ${input.namespace} não encontrado');
    }
    if (repository.remoteUrl == null) {
      _log.warning(
        'Repositório ${input.namespace} não possui URL remota configurada. Download não será possível.',
      );
      return null;
    }

    // 3. Usa a Factory para obter o handler correto e delega
    final handler = _packageHandlerFactory.create(repository.type);
    return handler.handle(input);
  }
}
