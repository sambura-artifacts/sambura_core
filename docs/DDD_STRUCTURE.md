# DDD Structure - Domain-Driven Design Organization

## Overview

This document describes the final Domain-Driven Design (DDD) structure implemented in Sambura Core following Clean Architecture principles. Each domain is self-contained with its own DTOs, Ports, Services, and Use Cases.

## Project Structure

```
lib/application/
├── account/
│   ├── dtos/
│   │   └── create_account_dto.dart
│   └── usecase/
│       └── create_account_usecase.dart
│
├── artifact/
│   ├── dtos/
│   │   ├── create_artifact_dto.dart
│   │   └── get_artifact_dto.dart
│   ├── ports/
│   │   ├── ports.dart (barrel file)
│   │   ├── registry_proxy_port.dart
│   │   └── storage_port.dart
│   └── usecase/
│       ├── check_artifact_exists_usecase.dart
│       ├── create_artifact_usecase.dart
│       ├── download_artifact_tarball_usecase.dart
│       ├── get_artifact_by_id_usecase.dart
│       ├── get_artifact_download_stream_usecase.dart
│       ├── get_artifact_usecase.dart
│       ├── upload_artifact_usecase.dart
│       └── usecases.dart
│
├── auth/
│   ├── api_key/
│   │   └── usecase/
│   │       ├── generate_api_key_usecase.dart
│   │       ├── list_api_keys_usecase.dart
│   │       ├── revoke_api_key_usecase.dart
│   │       └── usecases.dart
│   ├── dtos/
│   │   ├── generate_api_key_dto.dart
│   │   └── login_dto.dart
│   ├── ports/
│   │   ├── auth_port.dart
│   │   ├── hash_port.dart
│   │   └── ports.dart (barrel file)
│   ├── services/
│   │   └── auth_service.dart
│   └── usecase/
│       └── login_usecase.dart
│
├── compliance/
│   ├── extractor/
│   │   ├── extractors.dart
│   │   ├── metadata_extractor.dart
│   │   └── npm_metadata_extractor.dart
│   ├── ports/
│   │   └── compliance_port.dart
│   └── usecase/
│       └── register_compliance_artifact_usecase.dart
│
├── health/
│   ├── ports/
│   │   ├── health_check.dart
│   │   └── ports.dart (barrel file)
│   ├── services/
│   │   └── health_check_service.dart
│   └── usecase/
│       └── get_server_health_usecase.dart
│
├── package/
│   └── usecase/
│       ├── get_package_metadata_usecase.dart
│       ├── proxy_package_metadata_usecase.dart
│       ├── proxy_package_tarball_usecase.dart
│       └── usecases.dart
│
└── shared/
    ├── exceptions/
    │   ├── application_exception.dart
    │   └── exceptions.dart (barrel file)
    └── ports/
        ├── cache_port.dart
        ├── http_client_port.dart
        ├── metrics_port.dart
        ├── ports.dart (barrel file)
        └── secret_port.dart
```

## Bounded Contexts

### 1. Account Domain
**Responsibility**: User account management

- **Use Cases**: Account creation
- **DTOs**: `CreateAccountDto`
- **Dependencies**: `HashPort` (from Auth domain)

**Import Path**: `package:sambura_core/application/account/...`

---

### 2. Artifact Domain
**Responsibility**: Artifact storage, retrieval, and lifecycle management

- **Use Cases**: Create, upload, download, check existence, get by ID, get download stream
- **DTOs**: `CreateArtifactDto`, `GetArtifactDto`
- **Ports**:
  - `StoragePort`: Blob storage operations (MinIO/S3)
  - `RegistryProxyPort`: External registry proxy operations
- **Dependencies**: Shared ports (cache, http_client, metrics)

**Import Paths**:
- DTOs: `package:sambura_core/application/artifact/dtos/...`
- Ports: `package:sambura_core/application/artifact/ports/ports.dart`
- Use Cases: `package:sambura_core/application/artifact/usecase/...`

---

### 3. Auth Domain
**Responsibility**: Authentication and API Key management

- **Subdomains**:
  - **Core Auth**: Login, token generation
  - **API Key**: Generate, list, revoke API keys
- **DTOs**: `LoginDto`, `GenerateApiKeyDto`
- **Ports**:
  - `AuthPort`: Token operations (generate, validate, decode, revoke)
  - `HashPort`: Password hashing and verification
- **Services**: `AuthService` (internal authentication logic)

**Import Paths**:
- DTOs: `package:sambura_core/application/auth/dtos/...`
- Ports: `package:sambura_core/application/auth/ports/ports.dart`
- Services: `package:sambura_core/application/auth/services/...`
- Use Cases: `package:sambura_core/application/auth/usecase/...`
- API Key Use Cases: `package:sambura_core/application/auth/api_key/usecase/...`

---

### 4. Compliance Domain
**Responsibility**: Vulnerability scanning and compliance tracking via Dependency-Track

- **Strategy Pattern**: `MetadataExtractor` interface with ecosystem-specific implementations
  - `NpmMetadataExtractor` (package.json)
  - Future: MavenMetadataExtractor, PyPIMetadataExtractor, etc.
- **Use Cases**: Register compliance artifacts
- **Ports**: `CompliancePort` (Dependency-Track integration)

**Import Paths**:
- Extractors: `package:sambura_core/application/compliance/extractor/...`
- Ports: `package:sambura_core/application/compliance/ports/...`
- Use Cases: `package:sambura_core/application/compliance/usecase/...`

---

### 5. Health Domain
**Responsibility**: System health monitoring

- **Ports**: `HealthCheckPort` (interface for health checks)
- **Services**: `HealthCheckService` (orchestrates health checks)
- **Use Cases**: Get server health status

**Import Paths**:
- Ports: `package:sambura_core/application/health/ports/ports.dart`
- Services: `package:sambura_core/application/health/services/...`
- Use Cases: `package:sambura_core/application/health/usecase/...`

---

### 6. Package Domain
**Responsibility**: NPM package metadata proxy and tarball operations

- **Use Cases**: Get package metadata, proxy metadata, proxy tarball
- **Dependencies**: Shared ports (http_client), Artifact ports (storage)

**Import Path**: `package:sambura_core/application/package/usecase/...`

---

### 7. Shared (Cross-Cutting Concerns)
**Responsibility**: Cross-domain utilities used by multiple domains

- **Exceptions**: `ApplicationException` and domain-agnostic exceptions
- **Ports** (Infrastructure services):
  - `CachePort`: Redis caching operations
  - `HttpClientPort`: External HTTP requests
  - `MetricsPort`: Prometheus metrics collection
  - `SecretPort`: HashiCorp Vault secret management

**Import Paths**:
- Exceptions: `package:sambura_core/application/shared/exceptions/exceptions.dart`
- Ports: `package:sambura_core/application/shared/ports/ports.dart`

---

## Import Guidelines

### Domain-Specific Imports
Each domain should import from its own namespace:

```dart
// Account domain
import 'package:sambura_core/application/account/dtos/create_account_dto.dart';
import 'package:sambura_core/application/auth/ports/ports.dart'; // HashPort dependency

// Artifact domain
import 'package:sambura_core/application/artifact/ports/ports.dart';
import 'package:sambura_core/application/artifact/dtos/create_artifact_dto.dart';

// Auth domain
import 'package:sambura_core/application/auth/ports/ports.dart';
import 'package:sambura_core/application/auth/dtos/login_dto.dart';
import 'package:sambura_core/application/auth/services/auth_service.dart';

// Health domain
import 'package:sambura_core/application/health/ports/ports.dart';
import 'package:sambura_core/application/health/services/health_check_service.dart';
```

### Cross-Cutting Imports
Shared concerns available to all domains:

```dart
// Shared ports (cache, http, metrics, secrets)
import 'package:sambura_core/application/shared/ports/ports.dart';

// Shared exceptions
import 'package:sambura_core/application/shared/exceptions/exceptions.dart';
```

---

## Infrastructure Layer

The infrastructure layer implements domain ports:

```
lib/infrastructure/
├── adapters/
│   ├── auth/
│   │   ├── bcrypt_hash_adapter.dart (implements HashPort)
│   │   ├── jwt_adapter.dart (implements AuthPort)
│   │   └── local_auth_adapter.dart (implements AuthPort)
│   ├── cache/
│   │   └── redis_adapter.dart (implements CachePort)
│   ├── compliance/
│   │   └── dependency_track_adapter.dart (implements CompliancePort)
│   ├── health/
│   │   ├── blob_storage_health_check.dart (implements HealthCheckPort)
│   │   ├── postgres_health_check.dart (implements HealthCheckPort)
│   │   └── redis_healt_check.dart (implements HealthCheckPort)
│   ├── http/
│   │   └── http_client_adapter.dart (implements HttpClientPort)
│   ├── observability/
│   │   └── prometheus_metrics_adapter.dart (implements MetricsPort)
│   └── storage/
│       └── minio_storage_adapter.dart (implements StoragePort)
├── proxies/
│   └── npm_proxy.dart (implements RegistryProxyPort)
└── services/
    └── secrets/
        └── vault_service.dart (implements SecretPort)
```

### Adapter Import Examples

```dart
// Auth adapters
import 'package:sambura_core/application/auth/ports/ports.dart';

// Storage adapter
import 'package:sambura_core/application/artifact/ports/ports.dart';

// Health adapters
import 'package:sambura_core/application/health/ports/ports.dart';
import 'package:sambura_core/application/artifact/ports/ports.dart'; // For BlobStorageHealthCheck

// Cross-cutting adapters
import 'package:sambura_core/application/shared/ports/ports.dart';
```

---

## Architectural Principles

### 1. **Bounded Context Isolation**
Each domain is self-contained with its own:
- DTOs (Data Transfer Objects)
- Ports (interfaces to infrastructure)
- Services (domain logic)
- Use Cases (application orchestration)

### 2. **Dependency Direction**
Dependencies flow inward:
```
Infrastructure → Application (Ports) → Domain
```

### 3. **Port-Adapter Pattern**
- **Ports**: Interfaces defined in `application/{domain}/ports/`
- **Adapters**: Implementations in `infrastructure/adapters/`

### 4. **Cross-Cutting Concerns**
Services used by multiple domains live in `application/shared/ports/`:
- Cache (Redis)
- HTTP Client
- Metrics (Prometheus)
- Secrets (Vault)

### 5. **Barrel Files**
Each `ports/` directory contains a `ports.dart` barrel file:

```dart
// lib/application/auth/ports/ports.dart
export 'auth_port.dart';
export 'hash_port.dart';
```

This simplifies imports:
```dart
// Instead of:
import 'package:sambura_core/application/auth/ports/auth_port.dart';
import 'package:sambura_core/application/auth/ports/hash_port.dart';

// Use:
import 'package:sambura_core/application/auth/ports/ports.dart';
```

---

## Migration Notes

### Breaking Changes
All import paths have changed. Update imports as follows:

#### Old Structure
```dart
import 'package:sambura_core/application/ports/hash_port.dart';
import 'package:sambura_core/application/ports/auth_port.dart';
import 'package:sambura_core/application/ports/storage_port.dart';
import 'package:sambura_core/application/exceptions/application_exception.dart';
```

#### New Structure
```dart
import 'package:sambura_core/application/auth/ports/ports.dart'; // HashPort, AuthPort
import 'package:sambura_core/application/artifact/ports/ports.dart'; // StoragePort
import 'package:sambura_core/application/shared/exceptions/exceptions.dart';
```

---

## Benefits

1. **Clear Domain Boundaries**: Each domain has its own namespace
2. **Reduced Coupling**: Domains only depend on shared cross-cutting concerns
3. **Improved Discoverability**: Structure reflects business domains
4. **Easier Testing**: Mock only domain-specific ports
5. **Scalability**: New domains can be added following the same pattern
6. **Strategy Pattern Support**: Compliance domain demonstrates extensibility (multiple extractors)

---

## Next Steps

1. **Add More Extractors**: Implement `MavenMetadataExtractor`, `PyPIMetadataExtractor`
2. **Repository Domain**: Consider extracting repository operations to its own domain
3. **Domain Events**: Implement domain events for cross-domain communication
4. **Aggregate Roots**: Identify and enforce aggregate boundaries in Domain layer

---

## References

- [ARCHITECTURE.md](./ARCHITECTURE.md) - Overall architecture
- [COMPLIANCE_RESTRUCTURE.md](./COMPLIANCE_RESTRUCTURE.md) - Compliance domain details
- Clean Architecture by Robert C. Martin
- Domain-Driven Design by Eric Evans
