# Observabilidade no Samburá Core

## Visão Geral

O Samburá Core implementa observabilidade completa através de três pilares:

1. **Logs**: Rastreamento detalhado de operações (logging estruturado)
2. **Métricas**: Monitoramento em tempo real (Prometheus)
3. **Health Checks**: Verificação automatizada de componentes

## Arquitetura de Observabilidade

```
┌─────────────────────────────────────────┐
│         Application Layer               │
│                                         │
│  ┌────────────┐      ┌───────────────┐ │
│  │ MetricsPort│      │HealthCheckPort│ │
│  └────────────┘      └───────────────┘ │
│        ▲                     ▲          │
└────────┼─────────────────────┼──────────┘
         │                     │
┌────────┼─────────────────────┼──────────┐
│        │  Infrastructure Layer│         │
│        │                     │          │
│  ┌─────▼──────────┐   ┌─────▼─────────┐│
│  │ Prometheus     │   │ Health Check  ││
│  │ Metrics Adapter│   │   Adapters    ││
│  └────────────────┘   └───────────────┘│
│                                         │
│  • PostgresHealthCheck                  │
│  • RedisHealthCheck                     │
│  • BlobStorageHealthCheck               │
└─────────────────────────────────────────┘
         │                     │
         ▼                     ▼
    Prometheus             Health API
     Scraper              /system/health
```

## 1. Métricas com Prometheus

### MetricsPort (Interface)

```dart
/// Port para registro de métricas de observabilidade.
/// 
/// Segue Ports & Adapters (Hexagonal Architecture).
abstract class MetricsPort {
  // Health metrics
  void recordHealthStatus(String component, bool isHealthy);
  void recordHealthLatency(String component, double latencyMs);
  
  // Security metrics
  void recordSecurityViolation(String type);
  void recordAuthFailure(String reason);
  
  // Cache metrics
  void recordCacheHit(String cacheType);
  void recordCacheMiss(String cacheType);
}
```

### PrometheusMetricsAdapter (Implementação)

```dart
class PrometheusMetricsAdapter implements MetricsPort {
  final prometheus.CollectorRegistry registry;
  
  // Gauges - valores instantâneos
  late final prometheus.Gauge _healthStatus;
  late final prometheus.Gauge _healthLatency;
  
  // Counters - valores acumulativos
  late final prometheus.Counter _securityViolations;
  late final prometheus.Counter _authFailures;
  late final prometheus.Counter _cacheHits;
  late final prometheus.Counter _cacheMisses;
  
  PrometheusMetricsAdapter(this.registry) {
    _initializeMetrics();
  }
  
  void _initializeMetrics() {
    _healthStatus = prometheus.Gauge(
      name: 'sambura_health_status',
      help: 'Component health status (1=UP, 0=DOWN)',
      labelNames: ['component'],
    )..register(registry);
    
    _healthLatency = prometheus.Gauge(
      name: 'sambura_health_latency_ms',
      help: 'Component check latency in milliseconds',
      labelNames: ['component'],
    )..register(registry);
    
    // ... outros registros
  }
  
  @override
  void recordHealthStatus(String component, bool isHealthy) {
    _healthStatus.labels([component]).set(isHealthy ? 1 : 0);
  }
  
  @override
  void recordHealthLatency(String component, double latencyMs) {
    _healthLatency.labels([component]).set(latencyMs);
  }
  
  // ... outras implementações
}
```

### Métricas Disponíveis

#### 1. Health Metrics

| Métrica | Tipo | Labels | Descrição |
|---------|------|--------|-----------|
| `sambura_health_status` | Gauge | component | Status do componente (1=UP, 0=DOWN) |
| `sambura_health_latency_ms` | Gauge | component | Latência do health check em ms |

**Componentes monitorados:**
- `postgres`: Banco de dados PostgreSQL
- `redis`: Cache Redis
- `minio`: Object storage MinIO

#### 2. Security Metrics

| Métrica | Tipo | Labels | Descrição |
|---------|------|--------|-----------|
| `sambura_security_violations_total` | Counter | type | Total de violações de segurança |
| `sambura_auth_failures_total` | Counter | reason | Total de falhas de autenticação |

**Tipos de violações:**
- `path_traversal`: Tentativa de path traversal
- `invalid_package_name`: Nome de pacote inválido
- `invalid_version`: Versão inválida

**Razões de falha de auth:**
- `invalid_token`: Token inválido
- `expired_token`: Token expirado
- `missing_token`: Token ausente

#### 3. Cache Metrics

| Métrica | Tipo | Labels | Descrição |
|---------|------|--------|-----------|
| `sambura_cache_hits_total` | Counter | cache_type | Total de cache hits |
| `sambura_cache_misses_total` | Counter | cache_type | Total de cache misses |

**Tipos de cache:**
- `auth`: Cache de autenticação (Redis)

### Endpoint de Métricas

**URL:** `GET /metrics`

**Formato:** Prometheus Text Format

**Exemplo de resposta:**
```
# HELP sambura_health_status Component health status (1=UP, 0=DOWN)
# TYPE sambura_health_status gauge
sambura_health_status{component="postgres"} 1
sambura_health_status{component="redis"} 1
sambura_health_status{component="minio"} 1

# HELP sambura_health_latency_ms Component check latency in milliseconds
# TYPE sambura_health_latency_ms gauge
sambura_health_latency_ms{component="postgres"} 2.345
sambura_health_latency_ms{component="redis"} 0.812
sambura_health_latency_ms{component="minio"} 5.123

# HELP sambura_security_violations_total Security violations by type
# TYPE sambura_security_violations_total counter
sambura_security_violations_total{type="path_traversal"} 3
sambura_security_violations_total{type="invalid_package_name"} 1

# HELP sambura_auth_failures_total Authentication failures by reason
# TYPE sambura_auth_failures_total counter
sambura_auth_failures_total{reason="invalid_token"} 12
sambura_auth_failures_total{reason="expired_token"} 5

# HELP sambura_cache_hits_total Cache hits by type
# TYPE sambura_cache_hits_total counter
sambura_cache_hits_total{cache_type="auth"} 8542

# HELP sambura_cache_misses_total Cache misses by type
# TYPE sambura_cache_misses_total counter
sambura_cache_misses_total{cache_type="auth"} 234
```

## 2. Health Checks

### HealthCheckPort (Interface)

```dart
/// Port para verificações de saúde de componentes.
abstract class HealthCheckPort {
  String get name;
  Future<HealthCheckResult> check();
}

/// Resultado de uma verificação de saúde.
class HealthCheckResult {
  final bool isHealthy;
  final double latencyMs;
  final String? errorMessage;
  
  const HealthCheckResult({
    required this.isHealthy,
    required this.latencyMs,
    this.errorMessage,
  });
}
```

### HealthCheckService

```dart
class HealthCheckService {
  final List<HealthCheckPort> _healthChecks;
  final MetricsPort _metrics;
  
  HealthCheckService(this._healthChecks, this._metrics);
  
  Future<Map<String, HealthCheckResult>> checkAll() async {
    final results = <String, HealthCheckResult>{};
    
    for (final check in _healthChecks) {
      try {
        final result = await check.check();
        results[check.name] = result;
        
        // Reporta métricas
        _metrics.recordHealthStatus(check.name, result.isHealthy);
        _metrics.recordHealthLatency(check.name, result.latencyMs);
      } catch (e) {
        results[check.name] = HealthCheckResult(
          isHealthy: false,
          latencyMs: 0,
          errorMessage: e.toString(),
        );
        _metrics.recordHealthStatus(check.name, false);
      }
    }
    
    return results;
  }
  
  Future<bool> isAllHealthy() async {
    final results = await checkAll();
    return results.values.every((r) => r.isHealthy);
  }
}
```

### Implementações de Health Check

#### PostgresHealthCheck

```dart
class PostgresHealthCheck implements HealthCheckPort {
  final PostgresConnector _connector;
  
  @override
  String get name => 'postgres';
  
  @override
  Future<HealthCheckResult> check() async {
    final stopwatch = Stopwatch()..start();
    
    try {
      await _connector.query('SELECT 1');
      
      return HealthCheckResult(
        isHealthy: true,
        latencyMs: stopwatch.elapsedMilliseconds.toDouble(),
      );
    } catch (e) {
      return HealthCheckResult(
        isHealthy: false,
        latencyMs: stopwatch.elapsedMilliseconds.toDouble(),
        errorMessage: e.toString(),
      );
    }
  }
}
```

#### RedisHealthCheck

```dart
class RedisHealthCheck implements HealthCheckPort {
  final RedisAdapter _redis;
  
  @override
  String get name => 'redis';
  
  @override
  Future<HealthCheckResult> check() async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final isAlive = await _redis.isAlive();
      
      return HealthCheckResult(
        isHealthy: isAlive,
        latencyMs: stopwatch.elapsedMilliseconds.toDouble(),
      );
    } catch (e) {
      return HealthCheckResult(
        isHealthy: false,
        latencyMs: stopwatch.elapsedMilliseconds.toDouble(),
        errorMessage: e.toString(),
      );
    }
  }
}
```

#### BlobStorageHealthCheck

```dart
class BlobStorageHealthCheck implements HealthCheckPort {
  final MinioAdapter _storage;
  
  @override
  String get name => 'minio';
  
  @override
  Future<HealthCheckResult> check() async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final exists = await _storage.bucketExists();
      
      return HealthCheckResult(
        isHealthy: exists,
        latencyMs: stopwatch.elapsedMilliseconds.toDouble(),
      );
    } catch (e) {
      return HealthCheckResult(
        isHealthy: false,
        latencyMs: stopwatch.elapsedMilliseconds.toDouble(),
        errorMessage: e.toString(),
      );
    }
  }
}
```

### Endpoint de Health

**URL:** `GET /api/v1/system/health`

**Response (200 OK):**
```json
{
  "status": "UP",
  "checks": {
    "postgres": {
      "status": "UP",
      "latency_ms": 2.34
    },
    "redis": {
      "status": "UP",
      "latency_ms": 0.81
    },
    "minio": {
      "status": "UP",
      "latency_ms": 5.12
    }
  },
  "timestamp": "2025-12-26T10:30:00Z"
}
```

**Response (503 Service Unavailable):**
```json
{
  "status": "DOWN",
  "checks": {
    "postgres": {
      "status": "DOWN",
      "latency_ms": 5000,
      "error": "Connection timeout"
    },
    "redis": {
      "status": "UP",
      "latency_ms": 0.81
    },
    "minio": {
      "status": "UP",
      "latency_ms": 5.12
    }
  },
  "timestamp": "2025-12-26T10:30:00Z"
}
```

## 3. Integração com Middlewares

### AuthMiddleware

```dart
class AuthMiddleware {
  final MetricsPort _metrics;
  
  Future<Response> call(Request request) async {
    try {
      final account = await _resolveAccount(request);
      
      if (account != null) {
        _metrics.recordCacheHit('auth');
      } else {
        _metrics.recordCacheMiss('auth');
      }
      
      return _handler(request);
    } catch (e) {
      _metrics.recordAuthFailure(_getFailureReason(e));
      rethrow;
    }
  }
}
```

### ErrorHandlerMiddleware

```dart
class ErrorHandlerMiddleware {
  final MetricsPort? _metrics;
  
  Future<Response> call(Request request) async {
    try {
      return await _handler(request);
    } on SecurityException catch (e) {
      _metrics?.recordSecurityViolation(e.type);
      return Response.forbidden(jsonEncode({
        'error': e.message,
        'type': e.type,
      }));
    }
  }
}
```

## 4. Configuração do Prometheus

### prometheus.yml

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'sambura_app'
    scrape_interval: 15s
    static_configs:
      - targets: ['sambura_app:8080']
    metrics_path: '/metrics'
```

### Queries PromQL Úteis

**Taxa de Cache Hit (últimos 5min):**
```promql
rate(sambura_cache_hits_total[5m]) / 
(rate(sambura_cache_hits_total[5m]) + rate(sambura_cache_misses_total[5m]))
```

**Latência Média por Componente:**
```promql
avg(sambura_health_latency_ms) by (component)
```

**Taxa de Violações de Segurança:**
```promql
rate(sambura_security_violations_total[5m])
```

**Taxa de Falhas de Autenticação:**
```promql
rate(sambura_auth_failures_total[5m])
```

**Componentes com Problemas:**
```promql
sambura_health_status < 1
```

**Latência P95 de Health Checks:**
```promql
histogram_quantile(0.95, 
  rate(sambura_health_latency_ms[5m])
)
```

## 5. Dashboards Grafana

### Dashboard Principal

**Painéis recomendados:**

1. **Status Geral**
   - Gauge: `min(sambura_health_status)` (0=DOWN, 1=UP)
   - Cor verde se todos UP, vermelho se algum DOWN

2. **Latência por Componente**
   - Graph: `sambura_health_latency_ms`
   - Linha para cada componente (postgres, redis, minio)

3. **Taxa de Cache Hit**
   - Graph: Taxa de cache hit calculada
   - Target: > 90%

4. **Segurança**
   - Counter: `sambura_security_violations_total`
   - Counter: `sambura_auth_failures_total`

5. **Cache Performance**
   - Counter: `sambura_cache_hits_total`
   - Counter: `sambura_cache_misses_total`

### Alertas Recomendados

```yaml
groups:
  - name: sambura_alerts
    rules:
      # Componente down
      - alert: ComponentDown
        expr: sambura_health_status < 1
        for: 1m
        annotations:
          summary: "{{ $labels.component }} is DOWN"
          description: "Component {{ $labels.component }} has been DOWN for more than 1 minute."
      
      # Latência alta
      - alert: HighLatency
        expr: sambura_health_latency_ms > 100
        for: 5m
        annotations:
          summary: "High latency on {{ $labels.component }}"
          description: "{{ $labels.component }} latency is {{ $value }}ms"
      
      # Taxa de cache hit baixa
      - alert: LowCacheHitRate
        expr: |
          rate(sambura_cache_hits_total[5m]) / 
          (rate(sambura_cache_hits_total[5m]) + rate(sambura_cache_misses_total[5m])) < 0.8
        for: 10m
        annotations:
          summary: "Low cache hit rate"
          description: "Cache hit rate is below 80%"
      
      # Muitas violações de segurança
      - alert: HighSecurityViolations
        expr: rate(sambura_security_violations_total[5m]) > 0.1
        for: 5m
        annotations:
          summary: "High security violation rate"
          description: "Security violations rate is {{ $value }}/s"
```

## 6. Dependency Injection

```dart
class DependencyInjection {
  static Future<Dependencies> initialize() async {
    // 1. Inicializar Prometheus registry
    final prometheusRegistry = prometheus.CollectorRegistry();
    
    // 2. Criar adapter de métricas
    final metricsAdapter = PrometheusMetricsAdapter(prometheusRegistry);
    
    // 3. Criar health check adapters
    final healthChecks = [
      PostgresHealthCheck(postgresConnector),
      RedisHealthCheck(redisAdapter),
      BlobStorageHealthCheck(minioAdapter),
    ];
    
    // 4. Criar health check service
    final healthCheckService = HealthCheckService(
      healthChecks,
      metricsAdapter,
    );
    
    // 5. Injetar em middlewares e controllers
    final authMiddleware = AuthMiddleware(
      // ...
      metrics: metricsAdapter,
    );
    
    final errorHandlerMiddleware = ErrorHandlerMiddleware(
      metrics: metricsAdapter,
    );
    
    // 6. Criar controllers
    final systemController = SystemController(healthCheckService);
    final metricsController = MetricsController(prometheusRegistry);
    
    return Dependencies(
      metricsAdapter: metricsAdapter,
      healthCheckService: healthCheckService,
      // ...
    );
  }
}
```

## 7. Testes

### Testando MetricsPort

```dart
class MockMetricsPort implements MetricsPort {
  final recordedCalls = <String>[];
  
  @override
  void recordHealthStatus(String component, bool isHealthy) {
    recordedCalls.add('healthStatus:$component:$isHealthy');
  }
  
  // ... outros métodos
}

test('AuthMiddleware registra cache hit', () async {
  final mockMetrics = MockMetricsPort();
  final middleware = AuthMiddleware(metrics: mockMetrics);
  
  // ... executa middleware com cache hit
  
  expect(
    mockMetrics.recordedCalls,
    contains('cacheHit:auth'),
  );
});
```

### Testando Health Checks

```dart
test('PostgresHealthCheck retorna UP quando conectado', () async {
  final mockConnector = MockPostgresConnector();
  when(() => mockConnector.query('SELECT 1'))
      .thenAnswer((_) async => []);
  
  final healthCheck = PostgresHealthCheck(mockConnector);
  final result = await healthCheck.check();
  
  expect(result.isHealthy, isTrue);
  expect(result.latencyMs, greaterThan(0));
});
```

## 8. Best Practices

### ✅ DO

- Registre métricas em pontos críticos (auth, cache, segurança)
- Mantenha health checks leves (< 100ms)
- Use labels consistentes (sempre minúsculas)
- Configure alertas para componentes críticos
- Monitore latência e disponibilidade
- Use counters para valores acumulativos
- Use gauges para valores instantâneos

### ❌ DON'T

- Não registre métricas em loops (use batching)
- Não crie labels com alta cardinalidade (evite IDs únicos)
- Não faça queries pesadas em health checks
- Não ignore erros de health checks
- Não exponha informações sensíveis em métricas

## Referências

- [Prometheus Best Practices](https://prometheus.io/docs/practices/)
- [Grafana Dashboards](https://grafana.com/docs/grafana/latest/dashboards/)
- [Clean Architecture - Observability](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
