# Estrutura do Projeto Sambura Core

## 📁 Organização das Pastas

Este projeto segue os princípios da **Clean Architecture**, organizado por domínios de negócio para garantir manutenibilidade.

### 🔧 `/lib/application`
Camada de aplicação contendo a lógica de orquestração:

- **`compliance/`** - ✨ **Domínio de Governança**:
  - `extractor/`: Estratégias de extração (ex: `NpmMetadataExtractor`). Transformam bytes em metadados sem I/O.
  - `usecase/`: Orquestração de auditoria (ex: `RegisterComplianceArtifactUseCase`).
- **`artifact/usecase/`**: Operações físicas com artefatos (Silo, Downloads).
- **`package/usecase/`**: Operações lógicas de metadados e versionamento do registry.
- **`ports/`**: Contratos de infraestrutura, incluindo `CompliancePort` e `MetricsPort`.

### 🏗️ `/lib/infrastructure`
Implementações técnicas e comunicação externa:

- **`adapters/compliance/`**: Integração com Dependency-Track para ingestão de SBOM.
- **`adapters/secrets/`**: Integração com HashiCorp Vault.
- **`proxies/`**: Comunicação com registries externos (NPM Proxy).

## 🔄 Fluxo de Auditoria Assíncrona
Para não impactar a experiência do desenvolvedor (`npm install`), o fluxo de compliance é desacoplado:
1. O artefato é entregue ao cliente e persistido no Silo.
2. O `RegisterComplianceArtifactUseCase` é disparado via `unawaited`.
3. O `MetadataExtractor` processa o buffer em memória.
4. O `DependencyTrackAdapter` realiza a ingestão no servidor de segurança.

## 🎨 Nomenclatura
- **Extractors**: `*Extractor` (ex: `NpmMetadataExtractor`).
- **Use Cases**: `*Usecase` (ex: `DownloadArtifactTarballUsecase`).
- **Gatekeepers**: Time `@gatekeepers` responsável pela governança no arquivo `CODEOWNERS`.

## 🚀 Melhorias Futuras
- [x] Barrel files para imports limpos (v1.1)
- [x] Observabilidade com Prometheus e Loki (v1.1)
- [ ] Extração de metadados para ecossistemas compilados (v1.2)