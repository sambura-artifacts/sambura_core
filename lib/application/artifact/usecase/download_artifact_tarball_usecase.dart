import 'dart:async';

import 'package:async/async.dart';
import 'package:logging/logging.dart';
import 'package:sambura_core/application/shared/exceptions/application_exception.dart';
import 'package:sambura_core/application/usecase/usecases.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/infrastructure/artifact/api/dtos/artifact_input.dart';
import 'package:sambura_core/application/shared/ports/ports.dart';

class DownloadArtifactTarballUseCase {
  final HttpClientPort _httpClient;
  final CreateArtifactUsecase _createArtifact;
  final GetArtifactDownloadStreamUsecase _getArtifactDownloadStreamUsecase;
  final RegisterComplianceArtifactUseCase _registerCompliance;
  final CachePort _cache;
  final MetricsPort _metrics;
  final Logger _log = LoggerConfig.getLogger('DownloadArtifactTarballUseCase');

  DownloadArtifactTarballUseCase(
    this._httpClient,
    this._createArtifact,
    this._getArtifactDownloadStreamUsecase,
    this._registerCompliance,
    this._cache,
    this._metrics,
  );

  Future<Stream<List<int>>> executeProxyStream({
    required String remoteUrl,
    required ArtifactInput input,
  }) async {
    final lockKey = 'lock:download:${input.packageName}:${input.version}';

    final acquired = await _cache.acquireLock(lockKey);

    if (!acquired) {
      _metrics.incrementCounter('sambura_download_concurrency_waits_total');
      _log.info(
        '⏳ Aguardando download paralelo: ${input.packageName}@${input.version}',
      );

      for (var i = 0; i < 3; i++) {
        await Future.delayed(const Duration(seconds: 1));
        final local = await _getArtifactDownloadStreamUsecase.execute(
          namespace: input.namespace,
          name: input.packageName,
          version: input.version,
        );
        if (local != null) return local.stream;
      }
      throw ExternalServiceUnavailableException(
        'Recurso sendo processado por outro nó.',
      );
    }

    final stopwatch = Stopwatch()..start();

    try {
      _log.info('🌐 Iniciando download via Proxy: $remoteUrl');
      final response = await _httpClient.stream(Uri.parse(remoteUrl));

      _metrics.observeHistogram(
        'sambura_npm_proxy_resolution_duration_ms',
        stopwatch.elapsedMilliseconds.toDouble(),
        labels: {'package': input.packageName},
      );

      final splitter = StreamSplitter(response.stream);
      final streamToReturn = splitter.split();
      final streamToSave = splitter.split();

      unawaited(
        _createArtifact
            .execute(input, streamToSave)
            .then((_) async {
              _metrics.observeHistogram(
                'sambura_package_processing_duration_seconds',
                stopwatch.elapsedMilliseconds / 1000.0,
                labels: {'package': input.packageName, 'status': 'success'},
              );
              _log.info(
                '✅ Artefato persistido com sucesso: ${input.packageName}',
              );

              // --- INTEGRAÇÃO DEPENDENCY-TRACK ---
              // 1. Buscamos os bytes para análise (Compliance)
              final artifactData = await _getArtifactDownloadStreamUsecase
                  .execute(
                    namespace: input.namespace,
                    name: input.packageName,
                    version: input.version,
                  );

              if (artifactData != null) {
                final bytes = await artifactData.stream
                    .expand((x) => x)
                    .toList();

                // 2. Disparamos a auditoria sem aguardar (Fire and Forget)
                unawaited(
                  _registerCompliance.execute(
                    name: input.packageName,
                    version: input.version,
                    filename: '${input.packageName}-${input.version}.tgz',
                    bytes: bytes,
                  ),
                );
              }
              // ----------------------------------
            })
            .catchError((e) {
              _metrics.incrementCounter(
                'sambura_artifact_persistence_errors_total',
              );
              _log.severe('❌ Erro ao persistir artefato: $e');
            })
            .whenComplete(() async {
              await _cache.releaseLock(lockKey);
              stopwatch.stop();
            }),
      );

      return streamToReturn;
    } catch (e) {
      await _cache.releaseLock(lockKey);
      _metrics.incrementCounter('sambura_npm_proxy_errors_total');
      _log.severe('❌ Falha na resolução do proxy: $e');
      rethrow;
    }
  }
}
