import 'dart:async';

import 'package:async/async.dart';
import 'package:logging/logging.dart';
import 'package:sambura_core/application/exceptions/application_exception.dart';
import 'package:sambura_core/application/ports/cache_port.dart';
import 'package:sambura_core/application/ports/http_client_port.dart';
import 'package:sambura_core/application/ports/metrics_port.dart';
import 'package:sambura_core/application/usecase/usecases.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/infrastructure/api/dtos/artifact_input.dart';

class DownloadArtifactTarballUseCase {
  final HttpClientPort _httpClient;
  final CreateArtifactUsecase _createArtifact;
  final GetArtifactDownloadStreamUsecase _getArtifactStream; // Adicionado
  final CachePort _cache; // Adicionado
  final MetricsPort _metrics;
  final Logger _log = LoggerConfig.getLogger('DownloadArtifactTarballUseCase');

  DownloadArtifactTarballUseCase(
    this._httpClient,
    this._createArtifact,
    this._getArtifactStream,
    this._cache,
    this._metrics,
  );

  Future<Stream<List<int>>> executeProxyStream({
    required String remoteUrl,
    required ArtifactInput input,
  }) async {
    final lockKey = 'lock:download:${input.packageName}:${input.version}';

    // 1. Medir tentativa de Lock e Concorrência
    final acquired = await _cache.acquireLock(lockKey);

    if (!acquired) {
      _metrics.incrementCounter('sambura_download_concurrency_waits_total');
      _log.info(
        '⏳ Aguardando download paralelo: ${input.packageName}@${input.version}',
      );

      for (var i = 0; i < 3; i++) {
        await Future.delayed(Duration(seconds: 1));
        final local = await _getArtifactStream.execute(
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
        _createArtifact.execute(input, streamToSave).catchError((e) {
          _metrics.incrementCounter(
            'sambura_artifact_persistence_errors_total',
          );
          _log.severe('❌ Erro ao persistir artefato em background: $e');
          return null;
        }),
      );

      return streamToReturn;
    } catch (e) {
      _metrics.incrementCounter('sambura_npm_proxy_errors_total');
      rethrow;
    } finally {
      await _cache.releaseLock(lockKey);
    }
  }
}
