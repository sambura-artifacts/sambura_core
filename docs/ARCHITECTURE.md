# Arquitetura Clean - Samburá Core

## 📐 Visão Geral

Este projeto segue os princípios de **Clean Architecture** (Arquitetura Limpa) e **Clean Code**, garantindo:

- ✅ **Independência de Frameworks**: O domínio não depende de bibliotecas externas
- ✅ **Testabilidade**: Regras de negócio podem ser testadas sem UI, banco ou frameworks
- ✅ **Independência de UI**: A UI pode mudar sem afetar o domínio
- ✅ **Independência de Banco**: Trocar PostgreSQL por outro banco não afeta as regras de negócio
- ✅ **Princípios SOLID**: SRP, OCP, LSP, ISP e DIP aplicados rigorosamente

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

#### Adapters (Implementações)
Localização: `infrastructure/adapters/`

- `MinioAdapter`: Implementa `IStoragePort` para MinIO
- `RedisAdapter`: Implementa `ICachePort` para Redis
- `VaultAdapter`: Implementa `ISecretPort` para Vault
- `JwtAdapter`: Implementa `IAuthPort` para JWT
- `CryptoAdapter`: Implementa `IHashPort` para crypto

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
2. Controller chama UseCase com DTO
   ↓
3. UseCase valida através de Value Objects
   ↓
4. UseCase usa Factory para criar Entidade
   ↓
5. UseCase chama Repository (interface)
   ↓
6. Adapter implementa Repository usando Port (Storage)
   ↓
7. UseCase retorna Output DTO
   ↓
8. Controller converte DTO em Response
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

## 📚 Referências

- [Clean Architecture - Uncle Bob](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Domain-Driven Design - Eric Evans](https://www.domainlanguage.com/ddd/)
- [Hexagonal Architecture - Alistair Cockburn](https://alistair.cockburn.us/hexagonal-architecture/)
- [SOLID Principles](https://en.wikipedia.org/wiki/SOLID)
