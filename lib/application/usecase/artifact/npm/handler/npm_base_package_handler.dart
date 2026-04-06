import 'dart:async';
import 'dart:typed_data';
import 'package:async/async.dart';
import 'package:logging/logging.dart';

import 'package:sambura_core/application/barrel.dart';
import 'package:sambura_core/domain/barrel.dart';
import 'package:sambura_core/infrastructure/barrel.dart';

abstract class NpmBasePackageHandler implements NpmPackageHandler {
  final HttpClientPort httpClient;
  final CreateArtifactUsecase createArtifact;
  final GetArtifactDownloadStreamUsecase getArtifactDownloadStreamUsecase;
  final NamespaceRepository namespaceRepository;
  final CachePort cache;
  final MetricsPort metrics;
  final Logger log;

  final String handlerName; // e.g., 'npm', 'maven'

  NpmBasePackageHandler({
    required this.httpClient,
    required this.createArtifact,
    required this.getArtifactDownloadStreamUsecase,
    required this.namespaceRepository,
    required this.cache,
    required this.metrics,
    required this.log,
    required this.handlerName,
  });

  @override
  Future<Stream<Uint8List>> handle(ApplicationArtifactInput input) async {
    // =========================================================================
    // 1. HAPPY PATH: Verifica se já temos o artefato antes de qualquer Lock
    // =========================================================================
    final localStream = await getArtifactDownloadStreamUsecase.execute(
      namespace: input.namespace,
      name: input.packageName,
      version: input.version,
    );

    if (localStream != null) {
      log.info(
        '📦 Servindo do storage local: ${input.packageName}@${input.version}',
      );
      return localStream.stream;
    }

    // =========================================================================
    // 2. FLUXO DE PROXY (COM LOCK)
    // =========================================================================
    final lockKey =
        'lock:download:$handlerName:${input.packageName}:${input.version}';
    final acquired = await cache.acquireLock(lockKey);

    // Tratamento de concorrência: Se outro request já está baixando esse pacote
    if (!acquired) {
      metrics.incrementCounter('sambura_download_concurrency_waits_total');
      log.info(
        '⏳ Aguardando download paralelo: ${input.packageName}@${input.version}',
      );

      // Fallback: Fica checando o storage local a cada 1s
      for (var i = 0; i < 3; i++) {
        await Future.delayed(const Duration(seconds: 1));
        final retryLocal = await getArtifactDownloadStreamUsecase.execute(
          namespace: input.namespace,
          name: input.packageName,
          version: input.version,
        );
        if (retryLocal != null) return retryLocal.stream;
      }
      throw ExternalServiceUnavailableException(
        'Recurso sendo processado por outro nó.',
      );
    }

    // =========================================================================
    // 3. EXECUÇÃO DO PROXY (Internet)
    // =========================================================================
    final stopwatch = Stopwatch()..start();
    final remoteUrl = buildRemoteUrl(input);

    try {
      // REMOVIDO: O delay de 150ms que destruiria a performance do proxy.

      log.info('🌐 Iniciando download via Proxy $handlerName: $remoteUrl');
      final response = await httpClient.stream(remoteUrl);
      log.info('✓ Stream obtido do remoto (${response.length} bytes)');

      metrics.observeHistogram(
        'sambura_${handlerName}_proxy_resolution_duration_ms',
        stopwatch.elapsedMilliseconds.toDouble(),
        labels: {'package': input.packageName},
      );

      // =========================================================================
      // 4. MULTIPLEXAÇÃO E BACKGROUND PERSISTENCE
      // =========================================================================
      final splitter = StreamSplitter(response.stream);
      final streamToReturn = splitter.split();
      final streamToSave = splitter.split();

      final inputDto = InfraestructureArtifactInput(
        packageManager: 'npm',
        namespace: input.namespace,
        packageName: input.packageName,
        version: input.version,
        remoteUrl: input.remoteUrl,
      ).sanitize();

      // Processamento em Background (Não bloqueia o dev)
      unawaited(
        createArtifact
            .execute(inputDto, streamToSave)
            .then((_) {
              metrics.observeHistogram(
                'sambura_package_processing_duration_seconds',
                stopwatch.elapsedMilliseconds / 1000.0,
                labels: {'package': input.packageName, 'status': 'success'},
              );
              log.info(
                '✅ Artefato persistido: ${input.packageName}@${input.version}',
              );
            })
            .catchError((e, stackTrace) {
              metrics.incrementCounter(
                'sambura_artifact_persistence_errors_total',
              );
              log.severe(
                '❌ Erro ao persistir: ${input.packageName}',
                e,
                stackTrace,
              );
            })
            .whenComplete(() async {
              // Libera o lock INDEPENDENTE de dar sucesso ou erro no MinIO
              await cache.releaseLock(lockKey);
              stopwatch.stop();
            }),
      );

      // Retorna o stream Imediatamente para o pnpm não ficar esperando
      return streamToReturn;
    } on ExternalServiceUnavailableException catch (e) {
      await cache.releaseLock(lockKey);
      metrics.incrementCounter('sambura_${handlerName}_proxy_errors_total');
      log.severe('🚨 Falha de conectividade no proxy: ${e.message}', e);
      rethrow;
    } catch (e, stackTrace) {
      await cache.releaseLock(lockKey);
      metrics.incrementCounter('sambura_${handlerName}_proxy_errors_total');
      log.severe('❌ Erro inesperado no proxy para $remoteUrl', e, stackTrace);
      rethrow;
    }
  }
}
