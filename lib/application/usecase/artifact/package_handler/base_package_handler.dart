import 'dart:async';
import 'package:async/async.dart';
import 'package:logging/logging.dart';
import 'package:sambura_core/application/exceptions/application_exception.dart';
import 'package:sambura_core/application/ports/ports.dart';
import 'package:sambura_core/application/usecase/usecases.dart';
import 'package:sambura_core/infrastructure/api/dtos/artifact_input.dart';
import 'package:sambura_core/application/usecase/artifact/package_handler/package_handler.dart';

abstract class BasePackageHandler implements PackageHandler {
  final HttpClientPort httpClient;
  final CreateArtifactUsecase createArtifact;
  final GetArtifactDownloadStreamUsecase getArtifactDownloadStreamUsecase;
  final CachePort cache;
  final MetricsPort metrics;
  final Logger log;

  final String handlerName; // e.g., 'npm', 'maven'

  BasePackageHandler({
    required this.httpClient,
    required this.createArtifact,
    required this.getArtifactDownloadStreamUsecase,
    required this.cache,
    required this.metrics,
    required this.log,
    required this.handlerName,
  });

  @override
  Future<Stream<List<int>>> handle(ArtifactInput input) async {
    final lockKey =
        'lock:download:$handlerName:${input.packageName}:${input.version}';

    final acquired = await cache.acquireLock(lockKey);

    if (!acquired) {
      metrics.incrementCounter('sambura_download_concurrency_waits_total');
      log.info(
        '⏳ Aguardando download paralelo: ${input.packageName}@${input.version}',
      );

      for (var i = 0; i < 3; i++) {
        await Future.delayed(const Duration(seconds: 1));
        final local = await getArtifactDownloadStreamUsecase.execute(
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
    final remoteUrl = buildRemoteUrl(input);

    try {
      log.info('🌐 Iniciando download via Proxy $handlerName: $remoteUrl');
      final response = await httpClient.stream(remoteUrl);

      metrics.observeHistogram(
        'sambura_${handlerName}_proxy_resolution_duration_ms',
        stopwatch.elapsedMilliseconds.toDouble(),
        labels: {'package': input.packageName},
      );

      final splitter = StreamSplitter(response.stream);
      final streamToReturn = splitter.split();
      final streamToSave = splitter.split();

      unawaited(
        createArtifact
            .execute(input, streamToSave)
            .then((_) {
              metrics.observeHistogram(
                'sambura_package_processing_duration_seconds',
                stopwatch.elapsedMilliseconds / 1000.0,
                labels: {'package': input.packageName, 'status': 'success'},
              );
              log.info(
                '✅ Artefato ($handlerName) persistido com sucesso: ${input.packageName}',
              );
            })
            .catchError((e) {
              metrics.incrementCounter(
                'sambura_artifact_persistence_errors_total',
              );
              metrics.observeHistogram(
                'sambura_package_processing_duration_seconds',
                stopwatch.elapsedMilliseconds / 1000.0,
                labels: {'package': input.packageName, 'status': 'error'},
              );
              log.severe('❌ Erro ao persistir artefato ($handlerName): $e');
            })
            .whenComplete(() async {
              await cache.releaseLock(lockKey);
              stopwatch.stop();
            }),
      );

      return streamToReturn;
    } catch (e) {
      await cache.releaseLock(lockKey);
      metrics.incrementCounter('sambura_${handlerName}_proxy_errors_total');
      log.severe('❌ Falha na resolução do proxy ($handlerName): $e');
      rethrow;
    }
  }
}
