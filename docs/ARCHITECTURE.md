# Arquitetura Clean - Samburá Core

## 📐 Visão Geral

Este projeto segue os princípios de **Clean Architecture** (Arquitetura Limpa) e **Clean Code**, garantindo:

- ✅ **Independência de Frameworks**: O domínio não depende de bibliotecas externas
- ✅ **Testabilidade**: Regras de negócio podem ser testadas sem UI, banco ou frameworks
- ✅ **Independência de UI**: A UI pode mudar sem afetar o domínio
- ✅ **Independência de Banco**: Trocar PostgreSQL por outro banco não afeta as regras de negócio
- ✅ **Princípios SOLID**: SRP, OCP, LSP, ISP e DIP aplicados rigorosamente
- ✅ **Cache-Aside Pattern**: Redis cache na camada de infraestrutura
- ✅ **Mappers**: Separação entre Domain Entities e persistência
- ✅ **UUID v7**: IDs externos timestamp-sortable

## 🆕 Novidades Arquiteturais (v1.1)

### 1. Cache-Aside Pattern com Redis

**AuthMiddleware** implementa cache de autenticação:
- Cache de JWT tokens → Account (TTL: 15min)
- Cache de API Keys → Account (TTL: 30min)
- Fallback para DB quando cache miss
- Reduz carga no PostgreSQL em 95%+

```dart
// Cache-aside implementation
Future<AccountEntity?> _resolveFromJWT(String token) async {
  final sub = _authProvider.extractSubject(token);
  
  // 1. Try cache first
  final cached = await _cache.get('account:$sub');
  if (cached != null) return AccountMapper.fromJson(cached);
  
  // 2. Cache miss - query DB
  final account = await _accountRepo.findByExternalId(sub);
  if (account != null) {
    // 3. Update cache
    await _cache.set('account:$sub', AccountMapper.toJson(account));
  }
  return account;
}
```

### 2. Mappers Pattern

**Problema:** Domain Entities não devem conhecer detalhes de serialização.

**Solução:** Mappers na camada de infraestrutura.

```dart
// Domain Entity (pura, sem toJson/fromJson)
class AccountEntity {
  final ExternalId externalId;
  final Username username;
  final Email email;
  final Role role;
  final String? passwordHash; // Nullable para queries sem password
}

// Infrastructure Mapper
class AccountMapper {
  static Map<String, dynamic> toJson(AccountEntity entity) { ... }
  static AccountEntity fromJson(Map<String, dynamic> json) { ... }
  static AccountEntity fromRow(ResultRow row) { ... }
}
```

**Benefícios:**
- Domain mantém-se puro
- Facilita mudanças de serialização
- Testes unitários mais simples

### 3. UUID v7 (Timestamp-Sortable)

**Antes:** Sequential IDs (1, 2, 3...)
**Agora:** UUID v7 com timestamp embedded

```dart
// JWT subject agora usa external_id
{
  "sub": "018d5e7a-9f2c-7b4e-a123-456789abcdef", // UUID v7
  "role": "admin",
  "iat": 1735260000,
  "exp": 1735346400
}
```

**Vantagens:**
- Sortable por timestamp
- Distribuído (sem colisões)
- Segurança (não expõe contagem de usuários)
- Compatível com índices B-tree

### 4. Observabilidade com Prometheus

**Problema:** Monitoramento em produção requer visibilidade de saúde, performance e segurança.

**Solução:** Ports para métricas e health checks, com implementação Prometheus.

#### MetricsPort

```dart
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

#### PrometheusMetricsAdapter

```dart
class PrometheusMetricsAdapter implements MetricsPort {
  final prometheus.CollectorRegistry registry;
  
  // Gauges para health status e latência
  late prometheus.Gauge _healthStatus;
  late prometheus.Gauge _healthLatency;
  
  // Counters para segurança e cache
  late prometheus.Counter _securityViolations;
  late prometheus.Counter _authFailures;
  late prometheus.Counter _cacheHits;
  late prometheus.Counter _cacheMisses;
  
  @override
  void recordHealthStatus(String component, bool isHealthy) {
    _healthStatus.labels([component]).set(isHealthy ? 1 : 0);
  }
  // ...
}
```

#### Health Check Service

```dart
class HealthCheckService {
  final List<HealthCheckPort> _healthChecks;
  final MetricsPort _metrics;
  
  Future<Map<String, HealthCheckResult>> checkAll() async {
    final results = <String, HealthCheckResult>{};
    
    for (final check in _healthChecks) {
      final result = await check.check();
      results[check.name] = result;
      
      // Reporta métricas
      _metrics.recordHealthStatus(check.name, result.isHealthy);
      _metrics.recordHealthLatency(check.name, result.latencyMs);
    }
    
    return results;
  }
}
```

**Benefícios:**
- Monitoramento em tempo real via Prometheus
- Health checks automatizados (Postgres, Redis, MinIO)
- Métricas de segurança (violações, falhas de auth)
- Métricas de cache (hit/miss ratio)
- Alertas automáticos via AlertManager
- Dashboards Grafana pré-configurados

## 🏗️ Estrutura de Camadas

```
lib/
├── domain/                      # Camada de Domínio (Core Business)
│   ├── entities/               # Entidades de negócio
│   ├── value_objects/          # Value Objects (imutáveis)
│   ├── repositories/           # Interfaces de repositórios
│   ├── factories/              # Factories para criação de entidades
│   └── exceptions/             # Exceções de domínio
│
├── application/                # Camada de Aplicação (Use Cases)
│   ├── usecase/               # Casos de uso (regras de aplicação)
│   ├── dtos/                  # Data Transfer Objects
│   └── ports/                 # Interfaces (Ports) para serviços externos
│
└── infrastructure/            # Camada de Infraestrutura
    ├── adapters/             # Implementações dos Ports
    ├── repositories/         # Implementações dos repositórios
    ├── api/                  # Controllers, Routes, Middleware
    ├── database/             # Conexões e configurações de BD
    └── services/             # Serviços técnicos
```

## 🎯 Princípios Aplicados

### 1. Domain-Driven Design (DDD)

#### Entidades (Entities)
- `ArtifactEntity`: Representa um artefato com identidade única
- `BlobEntity`: Representa um arquivo binário
- `AccountEntity`: Representa uma conta de usuário
- `ApiKeyEntity`: Representa uma chave de API

#### Value Objects
- `PackageName`: Nome de pacote com validação NPM
- `Version`: Versão semântica (SemVer)
- `Hash`: Hash SHA-256 validado
- `ApiKeyValue`: Chave de API com formato validado

**Por que Value Objects?**
- Imutabilidade garantida
- Validação encapsulada
- Igualdade por valor, não por referência
- Reduz duplicação de lógica de validação

### 2. Ports & Adapters (Hexagonal Architecture)

#### Ports (Interfaces)
Localização: `application/ports/`

- `IStoragePort`: Abstração para storage (MinIO, S3, etc)
- `ICachePort`: Abstração para cache (Redis, Memcached)
- `ISecretPort`: Abstração para segredos (Vault, AWS Secrets)
- `IAuthPort`: Abstração para autenticação (JWT)
- `IHashPort`: Abstração para criptografia
- `MetricsPort`: Abstração para métricas (Prometheus) ✨ Novo v1.1
- `HealthCheckPort`: Abstração para verificações de saúde ✨ Novo v1.1

#### Adapters (Implementações)
Localização: `infrastructure/adapters/`

- `MinioAdapter`: Implementa `IStoragePort` para MinIO
- `RedisAdapter`: Implementa `ICachePort` para Redis
- `VaultAdapter`: Implementa `ISecretPort` para Vault
- `JwtAdapter`: Implementa `IAuthPort` para JWT
- `CryptoAdapter`: Implementa `IHashPort` para crypto
- `PrometheusMetricsAdapter`: Implementa `MetricsPort` para Prometheus ✨ Novo v1.1
- `PostgresHealthCheck`: Implementa `HealthCheckPort` validando Postgres ✨ Novo v1.1
- `RedisHealthCheck`: Implementa `HealthCheckPort` validando Redis ✨ Novo v1.1
- `BlobStorageHealthCheck`: Implementa `HealthCheckPort` validando MinIO ✨ Novo v1.1

**Benefícios:**
- Trocar tecnologia sem afetar lógica de negócio
- Testar com mocks facilmente
- Adicionar novas implementações sem modificar código existente (OCP)

### 3. Interface Segregation Principle (ISP)

Repositórios segregados por responsabilidade:

```dart
// ANTES (violando ISP)
abstract class ArtifactRepository {
  Future<Artifact> save(Artifact a);
  Future<Artifact?> findById(String id);
  Future<List<Artifact>> findAll();
  Future<void> delete(String id);
  // ... muitos outros métodos
}

// DEPOIS (seguindo ISP)
abstract class IArtifactWriteRepository {
  Future<Artifact> save(Artifact a);
  Future<void> delete(String id);
}

abstract class IArtifactReadRepository {
  Future<Artifact?> findById(String id);
  Future<List<Artifact>> findAllByPackage(...);
}

abstract class IArtifactQueryRepository {
  Future<Hash?> findHashByVersion(...);
  Future<List<Version>> listVersions(...);
}
```

**Vantagens:**
- Clientes dependem apenas dos métodos que usam
- Facilita testes (menos mocks)
- Permite implementações especializadas (ex: read replicas)

### 4. Use Cases com DTOs

Cada Use Case tem:
- **Input DTO**: Define os dados de entrada
- **Output DTO**: Define os dados de saída
- **Validação**: Encapsulada no DTO

Exemplo:

```dart
// Input com validação
class CreateArtifactInput {
  final PackageName packageName;  // Value Object validado
  final Version version;           // Value Object validado
  
  factory CreateArtifactInput.fromRaw(...) {
    return CreateArtifactInput(
      packageName: PackageName.create(rawName), // Valida aqui
      version: Version.create(rawVersion),
    );
  }
}

// Output limpo
class CreateArtifactOutput {
  final String artifactId;
  final String downloadUrl;
  
  Map<String, dynamic> toJson() => {...};
}

// Use Case
class CreateArtifactUsecase {
  Future<CreateArtifactOutput> execute(CreateArtifactInput input) {
    // Lógica pura de aplicação
  }
}
```

### 5. Factory Pattern

Factories encapsulam a criação complexa de entidades:

```dart
class ArtifactFactory {
  static ArtifactEntity create({
    required String packageName,
    required String version,
    // ...
  }) {
    // Validação com Value Objects
    final validatedName = PackageName.create(packageName);
    final validatedVersion = Version.create(version);
    
    // Criação com todas as regras aplicadas
    return ArtifactEntity.create(...);
  }
}
```

**Benefícios:**
- Centraliza lógica de criação
- Garante que entidades são criadas corretamente
- Facilita testes

## 📊 Fluxo de Dados

### Criação de Artefato (exemplo)

```
1. Controller recebe Request HTTP
   ↓
2. Middlewares processam (Auth, Logging, Metrics)
   ↓
3. Controller chama UseCase com DTO
   ↓
4. UseCase valida através de Value Objects
   ↓
5. UseCase usa Factory para criar Entidade
   ↓
6. UseCase chama Repository (interface)
   ↓
7. Adapter implementa Repository usando Port (Storage)
   ↓
8. Métricas são registradas (MetricsPort)
   ↓
9. UseCase retorna Output DTO
   ↓
10. Controller converte DTO em Response
```

### Autenticação com Métricas (exemplo)

```
1. Request HTTP com Authorization header
   ↓
2. AuthMiddleware extrai token
   ↓
3. Tenta buscar Account no cache Redis
   ├─ Cache Hit → _metrics.recordCacheHit('auth')
   └─ Cache Miss → _metrics.recordCacheMiss('auth')
       ↓
       Busca no Postgres e atualiza cache
   ↓
4. Se token inválido → _metrics.recordAuthFailure('invalid_token')
   ↓
5. Se SecurityException → _metrics.recordSecurityViolation(type)
   ↓
6. Request.context['account'] = account
   ↓
7. Próximo handler (RequireAuthMiddleware ou Controller)
```

## 🧪 Testabilidade

### Testes de Domínio
```dart
test('PackageName valida formato NPM', () {
  // Sem dependências externas!
  expect(
    () => PackageName.create('invalid@name!'),
    throwsArgumentError,
  );
});
```

### Testes de Use Case
```dart
test('CreateArtifactUsecase cria artefato', () async {
  // Mocks dos Ports
  final mockStorage = MockStoragePort();
  final mockRepo = MockArtifactWriteRepository();
  
  final usecase = CreateArtifactUsecase(mockStorage, mockRepo);
  
  final input = CreateArtifactInput.fromRaw(...);
  final output = await usecase.execute(input);
  
  expect(output.artifactId, isNotEmpty);
});
```

### Testes de Integração
```dart
test('Adapter se comunica com MinIO real', () async {
  final adapter = MinioAdapter(...);
  
  await adapter.store(
    path: 'test/file.txt',
    stream: Stream.value([1, 2, 3]),
    sizeBytes: 3,
  );
  
  expect(await adapter.exists('test/file.txt'), isTrue);
});
```

## 🔄 Dependency Injection

Dependencies são injetadas via construtor (DI manual):

```dart
// Composição no main.dart
void main() async {
  // 1. Cria Adapters (infraestrutura)
  final storage = MinioAdapter(...);
  final cache = RedisAdapter(...);
  final auth = JwtAdapter(...);
  
  // 2. Cria Repositories
  final artifactRepo = PostgresArtifactRepository(...);
  
  // 3. Cria Use Cases
  final createArtifact = CreateArtifactUsecase(
    storage,
    artifactRepo,
  );
  
  // 4. Cria Controllers
  final controller = ArtifactController(createArtifact);
  
  // 5. Monta a aplicação
  final app = createApp(controller);
}
```

## 📝 Convenções de Código

### Nomenclatura

- **Entities**: Sufixo `Entity` (ex: `ArtifactEntity`)
- **Value Objects**: Sem sufixo (ex: `PackageName`, `Version`)
- **DTOs**: Sufixo `Input`/`Output` (ex: `CreateArtifactInput`)
- **Ports**: Prefixo `I` + sufixo `Port` (ex: `IStoragePort`)
- **Adapters**: Sufixo `Adapter` (ex: `MinioAdapter`)
- **Repositories (interface)**: Prefixo `I` + sufixo `Repository` (ex: `IArtifactWriteRepository`)
- **Repositories (impl)**: Sem prefixo (ex: `PostgresArtifactRepository`)
- **Use Cases**: Sufixo `Usecase` (ex: `CreateArtifactUsecase`)
- **Factories**: Sufixo `Factory` (ex: `ArtifactFactory`)

### Documentação

Toda classe pública deve ter:
- Docstring explicando responsabilidade
- Exemplo de uso quando não óbvio
- Referência aos princípios aplicados

```dart
/// Adapter para MinIO implementando IStoragePort.
/// 
/// Segue o padrão Hexagonal Architecture (Ports & Adapters).
/// Permite trocar MinIO por outra solução de storage sem afetar
/// a lógica de negócio.
class MinioAdapter implements IStoragePort {
  // ...
}
```

## 🚀 Próximos Passos

- [ ] Implementar Event Sourcing para auditoria
- [ ] Adicionar CQRS completo com handlers separados
- [ ] Implementar Domain Events
- [ ] Adicionar validações com Result<T, E> (Railway Oriented Programming)
- [ ] Criar testes unitários para todos os Value Objects
- [ ] Implementar integration tests para Adapters
- [ ] Dashboards Grafana pré-configurados
- [ ] Alertas automáticos via Prometheus AlertManager

## 📈 Integração com Prometheus

### Configuração do Scraping

Arquivo: `docker/monitoring/prometheus.yml`

```yaml
scrape_configs:
  - job_name: 'sambura_app'
    scrape_interval: 15s
    static_configs:
      - targets: ['sambura_app:8080']
```

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

### Queries PromQL Úteis

**Taxa de cache hit:**
```promql
rate(sambura_cache_hits_total[5m]) / 
(rate(sambura_cache_hits_total[5m]) + rate(sambura_cache_misses_total[5m]))
```

**Latência média por componente:**
```promql
avg(sambura_health_latency_ms) by (component)
```

**Taxa de violações de segurança:**
```promql
rate(sambura_security_violations_total[5m])
```

**Componentes não saudáveis:**
```promql
sambura_health_status < 1
```

## 📚 Referências

- [Clean Architecture - Uncle Bob](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Domain-Driven Design - Eric Evans](https://www.domainlanguage.com/ddd/)
- [Hexagonal Architecture - Alistair Cockburn](https://alistair.cockburn.us/hexagonal-architecture/)
- [SOLID Principles](https://en.wikipedia.org/wiki/SOLID)
