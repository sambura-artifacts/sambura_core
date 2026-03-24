import 'dart:async';
import 'package:async/async.dart';
import 'package:logging/logging.dart';
import 'package:sambura_core/application/ports/ports.dart';
import 'package:sambura_core/application/usecase/artifact/create_artifact_usecase.dart';
import 'package:sambura_core/application/usecase/artifact/get_artifact_download_stream_usecase.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/infrastructure/api/dtos/artifact_input.dart';

class DownloadNugetArtifactUseCase {
  final HttpClientPort _httpClient;
  final CreateArtifactUsecase _createArtifact;
  final GetArtifactDownloadStreamUsecase _getArtifactDownloadStreamUsecase;
  final CachePort _cache;
  final MetricsPort _metrics;
  final Logger _log = LoggerConfig.getLogger('DownloadNugetArtifactUseCase');

  DownloadNugetArtifactUseCase(
    this._httpClient,
    this._createArtifact,
    this._getArtifactDownloadStreamUsecase,
    this._cache,
    this._metrics,
  );

  Future<Stream<List<int>>> executeProxyStream({
    required String remoteUrl,
    required ArtifactInput input,
  }) async {
    final lockKey =
        'lock:nuget:${input.packageName}:${input.version}:${input.fileName.hashCode}';

    // 1. Controle de Concorrência
    final acquired = await _cache.acquireLock(lockKey);
    if (!acquired) {
      _metrics.incrementCounter('sambura_download_concurrency_waits_total');
      _log.info('⏳ Aguardando download paralelo NuGet: ${input.fileName}');
      await Future.delayed(const Duration(seconds: 2));
      final local = await _getArtifactDownloadStreamUsecase.execute(
        namespace: input.namespace,
        name: input.packageName,
        version: input.version,
      );
      if (local != null) return local.stream;
    }

    final stopwatch = Stopwatch()..start();

    try {
      _log.info('🌐 Mirroring NuGet: $remoteUrl');
      final response = await _httpClient.stream(Uri.parse(remoteUrl));
      _metrics.observeHistogram(
        'sambura_nuget_proxy_resolution_duration_ms',
        stopwatch.elapsedMilliseconds.toDouble(),
        labels: {'package': input.packageName},
      );

      // 2. Splitter para servir e salvar simultaneamente
      final splitter = StreamSplitter(response.stream);
      final streamToReturn = splitter.split();
      final streamToSave = splitter.split();

      // 3. Persistência em background (Lazy Mirroring)
      unawaited(
        _createArtifact
            .execute(input, streamToSave)
            .then((_) {
              _metrics.observeHistogram(
                'sambura_package_processing_duration_seconds',
                stopwatch.elapsedMilliseconds / 1000.0,
                labels: {'package': input.packageName, 'status': 'success'},
              );
              _log.info('✅ NuGet Mirroring concluído: ${input.fileName}');
            })
            .catchError((e) {
              _metrics.incrementCounter(
                'sambura_artifact_persistence_errors_total',
              );
              _metrics.observeHistogram(
                'sambura_package_processing_duration_seconds',
                stopwatch.elapsedMilliseconds / 1000.0,
                labels: {'package': input.packageName, 'status': 'error'},
              );
              _log.severe('❌ Falha ao espelhar NuGet: $e');
            })
            .whenComplete(() {
              _cache.releaseLock(lockKey);
              stopwatch.stop();
            }),
      );

      return streamToReturn;
    } catch (e) {
      await _cache.releaseLock(lockKey);
      _metrics.incrementCounter('sambura_nuget_proxy_errors_total');
      _log.severe('❌ Erro no Proxy NuGet: $e');
      rethrow;
    }
  }
}
