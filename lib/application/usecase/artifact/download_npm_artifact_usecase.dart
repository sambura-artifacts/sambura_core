import 'dart:async';
import 'dart:typed_data';
import 'package:logging/logging.dart';
import 'package:sambura_core/application/exceptions/application_exception.dart';
import 'package:sambura_core/application/ports/composition_analysis_port.dart';
import 'package:sambura_core/application/ports/ports.dart';
import 'package:sambura_core/application/usecase/artifact/get_artifact_download_stream_usecase.dart';
import 'package:sambura_core/application/usecase/artifact/package_handler/package_handler_factory.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/domain/repositories/repository_repository.dart';
import 'package:sambura_core/infrastructure/api/dtos/artifact_input.dart';

class DownloadNpmArtifactUsecase {
  final GetArtifactDownloadStreamUsecase _getArtifactDownloadStreamUsecase;
  final RepositoryRepository _repositoryRepository;
  final PackageHandlerFactory _packageHandlerFactory;
  final CompositionAnalysisPort _scaPort;
  final CachePort _cache;
  final Logger _log = LoggerConfig.getLogger('DownloadNpmArtifactUsecase');

  DownloadNpmArtifactUsecase(
    this._getArtifactDownloadStreamUsecase,
    this._repositoryRepository,
    this._packageHandlerFactory,
    this._scaPort,
    this._cache,
  );

  Future<Stream<List<int>>?> execute(ArtifactInput input) async {
    try {
      final repository = await _repositoryRepository.getByName(input.namespace);

      _log.info(
        'Repositório ${input.namespace} encontrado: ${repository != null}, URL remota configurada: ${repository?.remoteUrl != null}',
      );

      final cacheKey = 'sambura:sec:${input.packageName}:${input.version}';

      // 1. Verifica o Cache
      final cachedStatus = await _cache.get(cacheKey);

      if (cachedStatus == 'INSECURE') {
        _log.warning(
          'Bloqueio via Cache: ${input.packageName}@${input.version}',
        );
        throw InsecureArtifactException(input.packageName, input.version);
      } else if (cachedStatus == 'SECURE') {
        _log.info('Liberado via Cache: ${input.packageName}@${input.version}');

        return _getArtifactStream(
          ArtifactInput(
            remoteUrl: repository!.remoteUrl,
            namespace: input.namespace,
            packageName: input.packageName,
            version: input.version,
          ),
        );
      }

      // 1. Verifica se o projeto já existe e se é seguro
      // Se existsAnalysis retornar falso, entramos no modo de criação reativa
      final bool exists = await _scaPort.existsAnalysis(
        input.packageName,
        input.version,
      );

      if (!exists) {
        _log.info(
          '🚀 [SCA] Projeto novo detectado: ${input.packageName}@${input.version}. Criando análise em tempo de download...',
        );
        return await _handleFirstDownloadWithSecurityAnalysis(
          ArtifactInput(
            remoteUrl: repository!.remoteUrl,
            namespace: input.namespace,
            packageName: input.packageName,
            version: input.version,
          ),
        );
      }

      // 2. Se já existe, aplica o Gate de Segurança normal
      final bool isSecure = await _scaPort.isSecure(
        input.packageName,
        input.version,
      );

      if (!isSecure) {
        throw InsecureArtifactException(
          input.packageName,
          input.version,
          details:
              'O artefato falhou na análise de segurança (Vulnerabilidades Críticas/Altas).',
        );
      }

      // 3. Fluxo normal de busca (Cache -> Proxy)
      return _getArtifactStream(
        ArtifactInput(
          remoteUrl: repository!.remoteUrl,
          namespace: input.namespace,
          packageName: input.packageName,
          version: input.version,
        ),
      );
    } catch (e, stackTrace) {
      _log.severe(
        '❌ Falha ao processar ${input.packageName}@${input.version}',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  Future<Stream<List<int>>?> _getArtifactStream(ArtifactInput input) async {
    // 1. Tenta o cache local primeiro
    _log.fine('Tentando obter stream local para ${input.packageName}');
    final localArtifact = await _getArtifactDownloadStreamUsecase.execute(
      namespace: input.namespace,
      name: input.packageName,
      version: input.version,
    );

    if (localArtifact != null) {
      return localArtifact.stream;
    }

    // 2. Se não houver cache, utiliza o Handler (Proxy)
    _log.info('Cache miss para ${input.packageName}. Buscando via Proxy...');
    final repository = await _repositoryRepository.getByName(input.namespace);

    if (repository == null) return null;

    final handler = _packageHandlerFactory.create(repository.type);

    // O handler vai buscar no npmjs.com (ou outro registry)
    // e retornar o stream dos bytes originais.
    return await handler.handle(input);
  }

  Future<Stream<List<int>>?> _handleFirstDownloadWithSecurityAnalysis(
    ArtifactInput input,
  ) async {
    try {
      // Busca o stream do artefato (seja local ou via proxy)
      final Stream<List<int>>? originalStream = await _getArtifactStream(input);

      if (originalStream == null) return null;

      // Converte o stream em bytes para poder analisar (e gerar o SBOM)
      final List<int> bytes = await originalStream.fold<List<int>>(
        [],
        (p, e) => p..addAll(e),
      );

      // Dispara a análise assíncrona para o D-Track
      // Nota: Como é o 1º download, podemos assumir 'safe' ou aguardar.
      // Aqui enviamos para criar o projeto e armazenar o SBOM.
      await _scaPort.analyze(
        packageName: input.packageName,
        version: input.version,
        projectType: 'npm',
        fileBytes: Uint8List.fromList(bytes),
      );

      return Stream.value(bytes);
    } catch (e) {
      _log.severe(
        'Erro ao baixar artefato para análise de segurança: ${input.packageName}@${input.version}',
        e,
      );
      return null;
    }
  }
}
