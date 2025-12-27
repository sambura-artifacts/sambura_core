# Estrutura do Projeto Sambura Core

## 📁 Organização das Pastas

Este projeto segue os princípios da **Clean Architecture** com uma estrutura bem definida:

### 🎯 `/lib/domain`
Camada de domínio - regras de negócio puras, independentes de frameworks

- **`entities/`** - Entidades do domínio (Account, Artifact, Package, etc.)
- **`factories/`** - Factories para criação de entidades
- **`value_objects/`** - Objetos de valor (Email, Password, Version, etc.)
- **`repositories/`** - Interfaces dos repositórios (contratos)
- **`services/`** - Serviços de domínio
- **`exceptions/`** - Exceções customizadas do domínio

### 🔧 `/lib/application`
Camada de aplicação - casos de uso e lógica de orquestração

- **`usecase/`** - Casos de uso organizados por domínio:
  - `account/` - Casos de uso relacionados a contas
  - `auth/` - Casos de uso de autenticação
  - `api_key/` - Gerenciamento de API keys
  - `artifact/` - Operações com artefatos
  - `package/` - Operações com pacotes
  - `health/` - ✨ Verificações de saúde
- **`dtos/`** - Data Transfer Objects
- **`ports/`** - Interfaces para infraestrutura (contratos):
  - `IStoragePort`, `ICachePort`, `IAuthPort`, etc.
  - `MetricsPort` - ✨ Porta para métricas (Prometheus)
  - `HealthCheckPort` - ✨ Porta para health checks
- **`services/`** - ✨ Serviços de aplicação:
  - `health/` - `HealthCheckService` orquestra health checks

### 🏗️ `/lib/infrastructure`
Camada de infraestrutura - implementações concretas

#### `/infrastructure/adapters`
Adaptadores para serviços externos organizados por tipo:
- **`auth/`** - JWT adapter, Bcrypt hash adapter
- **`cache/`** - Redis adapter
- **`crypto/`** - Crypto adapter
- **`secrets/`** - Vault adapter
- **`storage/`** - MinIO adapter
- **`health/`** - ✨ Health check adapters:
  - `PostgresHealthCheck` - Valida conexão com Postgres
  - `RedisHealthCheck` - Valida conexão com Redis
  - `BlobStorageHealthCheck` - Valida conexão com MinIO
- **`observability/`** - ✨ Adapters de observabilidade:
  - `PrometheusMetricsAdapter` - Implementação de MetricsPort

#### `/infrastructure/api`
Camada HTTP (Controllers, Routers, Middleware):
- **`controller/`** - Controllers organizados por domínio:
  - `admin/` - Controllers administrativos (API keys)
  - `auth/` - Controllers de autenticação
  - `artifact/` - Controllers de artefatos, pacotes, repositórios
  - `system/` - ✨ SystemController (health), MetricsController (Prometheus)
- **`presenter/`** - Presenters para formatação de respostas:
  - `admin/` - Presenters administrativos
  - `artifact/` - Presenters de artefatos
- **`middleware/`** - Middlewares:
  - `auth_middleware.dart` - ✨ Resolve identidade e registra métricas de cache
  - `require_auth_middleware.dart` - Valida autenticação
  - `error_handler_middleware.dart` - ✨ Captura exceções e registra métricas de segurança
  - `structured_log_middleware.dart` - Logging estruturado
- **`routes/`** - Definição de rotas:
  - `public_router.dart` - ✨ Rotas públicas (incluindo /metrics)
  - `protected_router.dart` - Rotas protegidas
  - `main_router.dart` - Router principal
- **`dtos/`** - DTOs específicos da API

#### `/infrastructure/repositories`
Implementações de repositórios organizadas por tipo:
- **`postgres/`** - Repositórios PostgreSQL
- **`blob/`** - Repositórios de armazenamento de blobs

#### `/infrastructure/services`
Serviços de infraestrutura organizados por categoria:
- **`auth/`** - Serviços de autenticação e hash
- **`cache/`** - Serviço Redis
- **`secrets/`** - Serviço Vault
- **`storage/`** - Serviço de arquivos

#### `/infrastructure/database`
Conectores e configurações de banco de dados

#### `/infrastructure/proxies`
Proxies para serviços externos (npm, etc.)

### 🔄 `/lib/shared`
Código compartilhado entre camadas
- **`utils/`** - Utilitários diversos (crypto, etc.)
- **`constants/`** - Constantes globais

### ⚙️ `/lib/config`
Configurações da aplicação
- Configuração de ambiente
- Logger
- Constantes de configuração

### 📦 Outros Diretórios

- **`/bin`** - Ponto de entrada da aplicação (`server.dart`)
- **`/test`** - Testes unitários e de integração
- **`/docs`** - Documentação adicional
- **`/sql`** - Scripts SQL de inicialização
- **`/specs`** - Especificações OpenAPI/Swagger
- **`/scripts`** - Scripts utilitários

## 🎨 Convenções

### Imports
Use os arquivos barrel para imports mais limpos:

#### Barrel Files Disponíveis

**Domain Layer:**
- `domain/entities/entities.dart` - Todas as entidades (Account, Artifact, Package, etc)
- `domain/factories/factories.dart` - Todas as factories
- `domain/value_objects/value_objects.dart` - Todos os value objects (Email, Password, etc)
- `domain/repositories/repositories.dart` - Todas as interfaces de repositórios
- `domain/exceptions/exceptions.dart` - Todas as exceções de domínio

**Application Layer:**
- `application/usecase/usecases.dart` - Todos os use cases organizados por domínio
- `application/ports/ports.dart` - Todos os ports (Storage, Cache, Auth, Metrics, etc)
- `application/exceptions/exceptions.dart` - Exceções de aplicação

#### Exemplos de Uso

```dart
// ✅ BOM - Imports limpos usando barrels
import 'package:sambura_core/domain/entities/entities.dart';
import 'package:sambura_core/domain/repositories/repositories.dart';
import 'package:sambura_core/domain/value_objects/value_objects.dart';
import 'package:sambura_core/application/ports/ports.dart';
import 'package:sambura_core/application/usecase/usecases.dart';

// ❌ EVITE - Imports individuais
import 'package:sambura_core/domain/entities/account_entity.dart';
import 'package:sambura_core/domain/entities/artifact_entity.dart';
import 'package:sambura_core/domain/repositories/account_repository.dart';
import 'package:sambura_core/domain/repositories/artifact_repository.dart';

// ✅ BOM - Use case com barrel imports
class CreateArtifactUseCase {
  final ArtifactRepository _artifactRepo;  // do repositories.dart
  final StoragePort _storage;              // do ports.dart
  final PackageEntity _package;            // do entities.dart
  
  CreateArtifactUseCase(this._artifactRepo, this._storage);
}
```

#### Benefícios dos Barrel Files

1. **Menos linhas de import** - Um import ao invés de múltiplos
2. **Manutenibilidade** - Mudanças de estrutura não quebram imports
3. **Legibilidade** - Fica claro de qual camada vem cada classe
4. **Consistência** - Toda equipe usa os mesmos padrões
5. **Refactoring seguro** - IDEs entendem melhor as dependências

### Nomenclatura
- **Entidades**: `*Entity` (ex: `AccountEntity`)
- **Factories**: `*Factory` (ex: `AccountFactory`)
- **Value Objects**: Nome descritivo (ex: `Email`, `Password`)
- **Use Cases**: `*Usecase` (ex: `CreateAccountUsecase`)
- **Repositories**: `*Repository` (ex: `AccountRepository`)
- **Controllers**: `*Controller` (ex: `AuthController`)
- **Presenters**: `*Presenter` (ex: `ApiKeyPresenter`)
- **Services**: `*Service` (ex: `HashService`)

### Organização por Domínio
Sempre que possível, organize por domínio/feature em vez de por tipo técnico:
- ✅ `usecase/account/`, `usecase/auth/`, `usecase/artifact/`
- ❌ Uma única pasta `usecase/` com todos os arquivos misturados

## 🚀 Melhorias Futuras
- [x] Barrel files para imports limpos (v1.1)
- [x] Observabilidade com Prometheus e métricas (v1.1)
- [x] Health checks por componente (v1.1)
- [ ] Adicionar testes para cada camada (80%+ cobertura)
- [ ] Implementar eventos de domínio
- [ ] Criar documentação automática das APIs com Swagger/OpenAPI
- [ ] Dashboard Grafana pré-configurado
