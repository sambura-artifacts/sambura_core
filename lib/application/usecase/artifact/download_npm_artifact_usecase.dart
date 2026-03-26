import 'dart:async';
import 'package:logging/logging.dart';
import 'package:sambura_core/application/usecase/artifact/get_artifact_download_stream_usecase.dart';
import 'package:sambura_core/application/usecase/artifact/package_handler/package_handler_factory.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/domain/repositories/repository_repository.dart';
import 'package:sambura_core/infrastructure/api/dtos/artifact_input.dart';

class DownloadNpmArtifactUsecase {
  final GetArtifactDownloadStreamUsecase _getArtifactDownloadStreamUsecase;
  final RepositoryRepository _repositoryRepository;
  final PackageHandlerFactory _packageHandlerFactory;
  final Logger _log = LoggerConfig.getLogger('DownloadAndProxyArtifactUsecase');

  DownloadNpmArtifactUsecase(
    this._getArtifactDownloadStreamUsecase,
    this._repositoryRepository,
    this._packageHandlerFactory,
  );

  Future<Stream<List<int>>?> execute(ArtifactInput input) async {
    try {
      // 1. Tenta buscar o artefato localmente
      _log.info(
        '🔍 [Fase 1] Buscando artefato localmente: ${input.namespace}/${input.packageName}@${input.version}',
      );
      final localArtifact = await _getArtifactDownloadStreamUsecase.execute(
        namespace: input.namespace,
        name: input.packageName,
        version: input.version,
      );

      if (localArtifact != null) {
        _log.info(
          '✅ [Cache Hit] Artefato encontrado localmente. Iniciando stream...',
        );
        return localArtifact.stream;
      }

      _log.info(
        '⚠️ [Cache Miss] Artefato não encontrado localmente, tentando proxy...',
      );

      // 2. Se não encontrar, busca as configurações do repositório
      _log.fine(
        '[Fase 2] Carregando configuração do repositório: ${input.namespace}',
      );
      final repository = await _repositoryRepository.getByName(input.namespace);

      if (repository == null) {
        _log.severe('❌ Repositório não encontrado: ${input.namespace}');
        throw Exception('Repositório ${input.namespace} não encontrado');
      }

      _log.fine(
        '✓ Repositório carregado: type=${repository.type}, isPublic=${repository.isPublic}',
      );

      // 3. Usa a Factory para obter o handler correto e delega
      _log.fine('[Fase 3] Criando handler para tipo: ${repository.type}');
      final handler = _packageHandlerFactory.create(repository.type);
      _log.info('✓ Handler criado com sucesso para ${repository.type}');

      _log.info(
        '🌐 [Fase 4] Iniciando proxy via ${repository.type} handler...',
      );
      final result = await handler.handle(input);
      _log.info('✅ Proxy concluído para ${input.packageName}@${input.version}');

      return result;
    } catch (e, stackTrace) {
      _log.severe(
        '❌ Falha ao processar ${input.packageName}@${input.version}',
        e,
        stackTrace,
      );
      rethrow;
    }
  }
}
