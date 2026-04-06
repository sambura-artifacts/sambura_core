import 'dart:async';
import 'dart:typed_data';
import 'package:logging/logging.dart';

import 'package:sambura_core/config/barrel.dart';
import 'package:sambura_core/domain/barrel.dart';
import 'package:sambura_core/application/barrel.dart';
import 'package:sambura_core/infrastructure/barrel.dart';

class NpmDownloadArtifactUsecase {
  final GetArtifactDownloadStreamUsecase _getArtifactDownloadStreamUsecase;
  final NamespaceRepository _namespaceRepository;
  final PackageHandlerFactory _packageHandlerFactory;
  final CompositionAnalysisPort _scaPort;
  final CachePort _cache;
  final Logger _log = LoggerConfig.getLogger('NpmDownloadArtifactUsecase');

  NpmDownloadArtifactUsecase(
    this._getArtifactDownloadStreamUsecase,
    this._namespaceRepository,
    this._packageHandlerFactory,
    this._scaPort,
    this._cache,
  );

  Future<Stream<Uint8List>?> execute(
    InfraestructureArtifactInput inputDto,
  ) async {
    try {
      final repository = await _namespaceRepository.getByName(
        inputDto.namespace,
      );

      final input = ApplicationArtifactInput(
        packageManager: 'npm',
        remoteUrl: repository!.remoteUrl,
        namespace: inputDto.namespace,
        packageName: inputDto.packageName,
        version: inputDto.version!,
      ).sanitize();

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

        return _getArtifactStream(input);
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
        return await _handleFirstDownloadWithSecurityAnalysis(input);
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
      return _getArtifactStream(input);
    } catch (e, stackTrace) {
      _log.severe(
        '❌ Falha ao processar ${inputDto.packageName}@${inputDto.version}',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  Future<Stream<Uint8List>?> _getArtifactStream(
    ApplicationArtifactInput input,
  ) async {
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
    final repository = await _namespaceRepository.getByName(input.namespace);

    if (repository == null) return null;

    final handler = _packageHandlerFactory.create();

    // O handler vai buscar no npmjs.com (ou outro registry)
    // e retornar o stream dos bytes originais.
    return await handler.handle(input);
  }

  Future<Stream<Uint8List>?> _handleFirstDownloadWithSecurityAnalysis(
    ApplicationArtifactInput input,
  ) async {
    try {
      // Busca o stream do artefato (seja local ou via proxy)
      final Stream<Uint8List>? originalStream = await _getArtifactStream(input);

      if (originalStream == null) return null;

      // Converte o stream em bytes para poder analisar (e gerar o SBOM)
      final Uint8List bytes = await originalStream.fold<Uint8List>(
        Uint8List(0),
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
