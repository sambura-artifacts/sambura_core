# 🏗️ Reestruturação Completa da Arquitetura - Application Layer

## 📋 Mudanças Realizadas

### 1. Padronização COMPLETA de Todos os Domínios (Domain Alignment)

Todos os domínios da application layer foram reestruturados para seguir o mesmo padrão organizacional:

#### ✅ Account Domain
- **Antes**: `lib/application/usecase/account/`
- **Depois**: `lib/application/account/usecase/`

#### ✅ Auth Domain (Authentication & Authorization)
- **Antes**: `lib/application/usecase/auth/`
- **Depois**: `lib/application/auth/usecase/`
- **API Keys**: `lib/application/auth/api_key/usecase/`
  - API Keys são uma forma de autenticação, por isso estão dentro do domínio Auth

#### ✅ Artifact Domain
- **Antes**: `lib/application/usecase/artifact/`
- **Depois**: `lib/application/artifact/usecase/`

#### ✅ Health Domain
- **Antes**: `lib/application/usecase/health/`
- **Depois**: `lib/application/health/usecase/`

#### ✅ Package Domain
- **Antes**: `lib/application/usecase/package/`
- **Depois**: `lib/application/package/usecase/`

### 2. Compliance Domain Standardization

#### ✅ Extractors
Localização: `lib/application/compliance/extractor/`

- **`MetadataExtractor`** (abstract): Interface base para estratégias de extração
- **`NpmMetadataExtractor`**: Implementação concreta para pacotes NPM (.tgz, .tar.gz)

**Strategy Pattern**: Permite adicionar novos extractors para outros ecossistemas (Maven, PyPI, etc.) sem modificar código existente.

#### ✅ Use Cases
Localização: `lib/application/compliance/usecase/`

- **`RegisterComplianceArtifactUseCase`**: Orquestra extração e registro no sistema de compliance

**Responsabilidades**:
1. Seleciona o extrator apropriado baseado no tipo de arquivo
2. Extrai metadados do artefato
3. Delega registro para CompliancePort

### 3. Infrastructure Standard

#### ✅ DependencyTrackAdapter
Localização: `lib/infrastructure/adapters/compliance/dependency_track_adapter.dart`

**Mudanças**:
- ❌ **Removido**: Lógica de parsing de tarball/zip (violava SRP)
- ✅ **Adicionado**: Recebe metadados já extraídos via CompliancePort
- ✅ **Responsabilidade Única**: Apenas comunicação com Dependency-Track API

### 4. Decoupling

#### ✅ Separação de Responsabilidades
- **Extractors** (Application Layer): Conhecimento de domínio sobre formatos de pacotes
- **Adapter** (Infrastructure Layer): Conhecimento técnico sobre APIs externas
- **Use Cases**: Orquestração do fluxo de negócio

#### ✅ Clean Architecture Boundaries Mantidas
```
Domain (Entities, Value Objects)
    ↑
Application (Use Cases, Ports, DTOs, Extractors)
    ↑
Infrastructure (Adapters, Repositories, Services)
```

### 5. Ports & DTOs

#### ✅ CompliancePort Updated
**Antes**:
```dart
Future<void> ingestArtifact(
  String name,
  String version,
  List<int> tarballBytes,
);
```

**Depois**:
```dart
Future<void> registerArtifact({
  required String packageMetadata,
  required String purlNamespace,
  required String name,
  required String version,
});
```

**Vantagens**:
- Desacoplamento de formatos de arquivo
- Suporte multi-ecosystem
- Testabilidade aprimorada

## 🎯 Benefícios da Reestruturação

### 1. **Consistência Arquitetural**
Todos os domínios (Account, Artifact, Package, Compliance) seguem o mesmo padrão de organização.

### 2. **Extensibilidade**
Adicionar suporte a novos ecossistemas (Maven, PyPI, Cargo, etc.) requer apenas:
- Criar novo extractor implementando `MetadataExtractor`
- Registrar na lista de extractors

### 3. **Testabilidade**
- Extractors podem ser testados isoladamente
- Adapter não precisa mockar parsing de arquivos
- Use cases testam apenas orquestração

### 4. **Manutenibilidade**
- Responsabilidades claramente definidas
- Violação de SRP eliminada
- Dependências unidirecionais

### 5. **Compliance Não-Crítico**
`RegisterComplianceArtifactUseCase` captura exceções e não propaga erros, garantindo que falhas em compliance não afetem o fluxo principal.

## 📦 Estrutura Final

```
lib/application/
├── account/
│   └── usecase/                    # Use cases de account
├── artifact/
│   └── usecase/                    # Use cases de artifact
├── auth/                           # Domínio de autenticação
│   ├── api_key/
│   │   └── usecase/                # API Keys (forma de autenticação)
│   └── usecase/                    # Login, autenticação básica
├── compliance/
│   ├── extractor/
│   │   ├── metadata_extractor.dart      # Interface Strategy
│   │   ├── npm_metadata_extractor.dart  # Implementação NPM
│   │   └── extractors.dart              # Barrel file
│   └── usecase/
│       └── register_compliance_artifact_usecase.dart
├── health/
│   └── usecase/                    # Use cases de health
├── package/
│   └── usecase/                    # Use cases de package
├── usecase/
│   └── usecases.dart               # Barrel file (exporta todos)
├── dtos/
├── ports/
│   └── compliance_port.dart        # Interface atualizada
├── exceptions/
└── services/
    ├── auth/
    └── health/

lib/infrastructure/
└── adapters/
    └── compliance/
        └── dependency_track_adapter.dart  # Refatorado
```

## 🔄 Migration Guide

### Para adicionar novo ecosystem (ex: Maven):

1. **Criar Extractor**:
```dart
class MavenMetadataExtractor implements MetadataExtractor {
  @override
  bool canHandle(String filename) => filename.endsWith('.jar');
  
  @override
  Future<String?> extractPackageMetadata(List<int> bytes) async {
    // Parse pom.xml or MANIFEST.MF
  }
  
  @override
  String getPurlNamespace(String name) => 'maven';
}
```

2. **Registrar no DI Container**:
```dart
final extractors = [
  NpmMetadataExtractor(),
  MavenMetadataExtractor(),  // Novo
];

final registerComplianceUseCase = RegisterComplianceArtifactUseCase(
  extractors: extractors,
  compliancePort: dependencyTrackAdapter,
);
```

3. **Usar no CreateArtifactUseCase**:
```dart
await registerComplianceUseCase.execute(
  filename: 'my-lib-1.0.0.jar',
  bytes: jarBytes,
  name: 'my-lib',
  version: '1.0.0',
);
```

## ✅ Compliance Checklist

- [x] Domain alignment (TODOS os domínios seguem o mesmo padrão)
  - [x] Account: `lib/application/account/usecase/`
  - [x] Auth: `lib/application/auth/usecase/`
    - [x] API Key (subdomínio): `lib/application/auth/api_key/usecase/`
  - [x] Artifact: `lib/application/artifact/usecase/`
  - [x] Health: `lib/application/health/usecase/`
  - [x] Package: `lib/application/package/usecase/`
- [x] MetadataExtractor e NpmMetadataExtractor criados
- [x] RegisterComplianceArtifactUseCase implementado
- [x] DependencyTrackAdapter refatorado (sem parsing)
- [x] CompliancePort atualizado
- [x] Imports atualizados em TODOS os arquivos
- [x] Clean Architecture boundaries mantidas
- [x] Análise estática sem erros
- [x] Código formatado

## 📚 Próximos Passos

1. **Testes Unitários**:
   - `NpmMetadataExtractor`
   - `RegisterComplianceArtifactUseCase`
   - `DependencyTrackAdapter` (com novos parâmetros)

2. **Integração**:
   - Chamar `RegisterComplianceArtifactUseCase` no `CreateArtifactUseCase`
   - Adicionar observabilidade (logs, métricas)

3. **Documentação**:
   - Atualizar ARCHITECTURE.md
   - Adicionar exemplos de uso

4. **CI/CD**:
   - Atualizar testes de integração
   - Verificar coverage
