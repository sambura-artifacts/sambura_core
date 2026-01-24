import 'package:prometheus_client/prometheus_client.dart';
import 'package:sambura_core/application/ports/ports.dart';

class PrometheusMetricsAdapter implements MetricsPort {
  static final packageProcessingDuration = Histogram(
    name: 'sambura_package_processing_duration_seconds',
    help: 'Tempo de processamento de pacotes NPM em segundos',
    buckets: [0.1, 0.5, 1, 2, 5, 10, 30], // Ajuste conforme seu gargalo
  );

  static final npmProxyDownloadDuration = Histogram(
    name: 'sambura_npm_proxy_resolution_duration_ms',
    help: 'Tempo para resolver e iniciar o stream do NPM em milissegundos.',
    labelNames: ['package'],
  );

  static final _securityViolations = Counter(
    name: 'sambura_security_violations_total',
    help: 'Total de violações de segurança interceptadas.',
    labelNames: ['reason'],
  );

  static final _authFailures = Counter(
    name: 'sambura_auth_failures_total',
    help: 'Total de tentativas de autenticação que falharam.',
    labelNames: ['type'],
  );

  static final _blockedIps = Gauge(
    name: 'sambura_security_blocked_ips_count',
    help: 'Número total de IPs atualmente na blacklist.',
  )..register();

  static final healthStatus = Gauge(
    name: 'sambura_health_status',
    help: 'Status geral do sistema (1=HEALTHY, 0=UNHEALTHY)',
  );

  static final componentStatus = Gauge(
    name: 'sambura_health_component_status',
    help: 'Status do componente (1=UP, 0=DOWN)',
    labelNames: ['component'],
  );

  static final componentLatency = Gauge(
    name: 'sambura_health_component_latency_ms',
    help: 'Latência do health check em milissegundos',
    labelNames: ['component'],
  );

  static final authCacheCounter = Counter(
    name: 'sambura_auth_cache_total',
    help: 'Total de verificações de autenticação no cache.',
    labelNames: ['result', 'type'],
  );

  static final httpRequestDuration = Histogram(
    name: 'sambura_http_request_duration_seconds',
    help: 'Duração das requisições HTTP em segundos.',
    labelNames: ['method', 'path', 'status'],
  );

  static final _concurrencyWaits = Counter(
    name: 'sambura_download_concurrency_waits_total',
    help: 'Total de vezes que uma requisição esperou por um lock de download.',
  );

  static final _proxyErrors = Counter(
    name: 'sambura_npm_proxy_errors_total',
    help: 'Total de erros de rede/conexão com o registro externo.',
  );

  static final _persistenceErrors = Counter(
    name: 'sambura_artifact_persistence_errors_total',
    help: 'Total de falhas ao salvar o artefato no storage/banco.',
  );

  static void initialize() {
    try {
      final registry = CollectorRegistry.defaultRegistry;
      registry.register(healthStatus);
      registry.register(componentStatus);
      registry.register(componentLatency);
      registry.register(authCacheCounter);
      registry.register(httpRequestDuration);
      registry.register(_securityViolations);
      registry.register(npmProxyDownloadDuration);
      registry.register(_concurrencyWaits);
      registry.register(_proxyErrors);
      registry.register(_persistenceErrors);
      registry.register(packageProcessingDuration);
      _securityViolations.labels(['unauthorized']).inc(0);
      _securityViolations.labels(['insufficient_permissions']).inc(0);
    } catch (_) {}
  }

  @override
  void reportHealthStatus(bool isAllHealthy) {
    healthStatus.value = isAllHealthy ? 1.0 : 0.0;
  }

  @override
  void reportComponentStatus(String name, bool isHealthy, Duration latency) {
    componentStatus.labels([name]).value = isHealthy ? 1.0 : 0.0;
    componentLatency.labels([name]).value = latency.inMilliseconds.toDouble();
  }

  @override
  void recordAuthCache(String result, String type) {
    authCacheCounter.labels([result, type]).inc();
  }

  @override
  void recordViolation(String reason) =>
      _securityViolations.labels([reason]).inc();

  @override
  void recordAuthFailure(String type) => _authFailures.labels([type]).inc();

  @override
  void updateBlockedIpsCount(int count) => _blockedIps.value = count.toDouble();

  @override
  void recordProxyLatency(String packageName, double ms) =>
      npmProxyDownloadDuration.labels([packageName]).observe(ms);

  @override
  void recordHttpDuration(
    String method,
    String path,
    int status,
    double durationSeconds,
  ) => httpRequestDuration
      .labels([method, path, status.toString()])
      .observe(durationSeconds);

  @override
  void incrementCounter(String name) {
    switch (name) {
      case 'sambura_download_concurrency_waits_total':
        _concurrencyWaits.inc();
        break;
      case 'sambura_npm_proxy_errors_total':
        _proxyErrors.inc();
        break;
      case 'sambura_artifact_persistence_errors_total':
        _persistenceErrors.inc();
        break;
    }
  }

  @override
  void observeHistogram(
    String name,
    double value, {
    Map<String, String>? labels,
  }) {
    if (name == 'sambura_npm_proxy_resolution_duration_ms') {
      npmProxyDownloadDuration
          .labels([labels?['package'] ?? 'unknown'])
          .observe(value);
    }
  }

  @override
  Future<T> observeProcessingTime<T>(Future<T> Function() action) async {
    final stopwatch = Stopwatch()..start();
    try {
      return await action();
    } finally {
      stopwatch.stop();
      final duration = stopwatch.elapsedMilliseconds / 1000.0;
      packageProcessingDuration.observe(duration);
    }
  }
}
