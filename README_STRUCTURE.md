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
```dart
// ✅ Bom
import 'package:sambura_core/domain/entities/entities.dart';
import 'package:sambura_core/domain/factories/factories.dart';
import 'package:sambura_core/application/usecase/usecases.dart';

// ❌ Evite
import 'package:sambura_core/domain/entities/account_entity.dart';
import 'package:sambura_core/domain/entities/artifact_entity.dart';
```

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
- [ ] Adicionar testes para cada camada
- [ ] Implementar eventos de domínio
- [ ] Adicionar observabilidade (tracing, metrics)
- [ ] Criar documentação automática das APIs
