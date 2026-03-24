# Copilot Workspace Instructions for sambura_core

## Overview
- Repository: `sambura_core` (Dart 3, Clean Architecture, artifact registry + proxy).
- Goal: private artifact registry with NPM/Maven/PyPI uplink + auth (JWT + API key) + Redis/MinIO/Postgres/Vault.
- Layers: presentation (api/middleware) → application (usecases/ports/dtos) → domain (entities/value objects) → infrastructure (repos/adapters/mappers/services).

## Fast setup (commands)
- `dart pub get`
- `make dev` (local server + hot reload)
- `make test`
- `make test-coverage`
- `make docker-up` (dev infra: Postgres, Redis, Vault, MinIO, RabbitMQ)

## Where to start
- `bin/server.dart` (bootstrap entry)
- `lib/config/dependency_injection.dart` (DI with GetIt)
- `lib/application/usecase` (business flows)
- `lib/domain/entities`, `lib/domain/repositories`, `lib/domain/value_objects`
- `lib/infrastructure/repositories` + `lib/infrastructure/adapters` + `lib/infrastructure/mappers`

## Conventions
- Use `barrel` exports (`entities.dart`, `repositories.dart`, `ports.dart`) not individual file imports.
- Domain entities are pure and not dependent on framework/serialization.
- Application uses DTOs + ports; infrastructure implements ports.
- Use `domain/factories` for entity creation with validation.
- Error classes in `lib/application/exceptions` and `lib/domain/exceptions`.
- Tests mirror source tree under `test/`.

## Important behavior patterns
- Auth caching: JWT timeout + Redis token cache (AuthMiddleware)
- API keys cached in memory and Redis (if configured)
- Proxy uplink: transparent on package miss; caches manifests and blobs.
- UUID v7 for external IDs.

## Documentation links
- `README.md` (usage, arch, todos)
- `docs/ARCHITECTURE.md`
- `docs/ci-cd.md`, `docs/logging.md`, `docs/observability.md`
- `README_STRUCTURE.md` (directory docs)

## How to ask Copilot
1. “In sambura_core, add a new use case to create an artifact tag in `lib/application/usecase/artifact` and wire API route in `lib/infrastructure/api` with tests.”
2. “Refactor exporter from `lib/infrastructure/repositories` to use an explicit mapper in `lib/domain/factories` matching existing style.”
3. “Find and fix the punt in auth middleware where an API key that exists in Redis can still fall back to DB in version 0.8.”

## Agent customization ideas
- `create-agent` for endpoint scaffolding: `artifact`, `repository`, `auth` use cases
- `create-hook` for enforcing `barrel` import policy
- `create-prompt` to check caching path (Redis/MinIO) and consistency

## ApplyTo (optional)
Use if you later split into role-specific instruction sets:
- `lib/application/**`: "business logic and use case actions"
- `lib/domain/**`: "pure entity/value object invariants"
- `lib/infrastructure/**`: "persistency / gateway / adapter implementation"
- `test/**`: "unit/integration coverage and mocks"
