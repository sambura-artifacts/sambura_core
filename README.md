# 🎯 Samburá Core

> Registry privado universal de artefatos com proxy transparente, governança de segurança e Clean Architecture em Dart.

[![🛡️ Quality Gate](https://github.com/seu-usuario/sambura_core/actions/workflows/quality-gate.yml/badge.svg)](https://github.com/seu-usuario/sambura_core/actions)
[![Dart Version](https://img.shields.io/badge/dart-%3E%3D3.0.0-blue.svg)](https://dart.dev/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Coverage](https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/usuario/id/raw/coverage.json)](COVERAGE_REPORT.md)

## 📋 Sumário
- [Sobre](#-sobre)
- [Arquitetura](#-arquitetura)
- [Governança e Compliance](#-governança-e-compliance)
- [Estrutura do Projeto](#-estrutura-do-projeto)
- [Roadmap](#-roadmap)
- [Métricas](#-métricas-do-projeto)

## 🎯 Sobre
**Samburá Core** é um registry privado universal de artefatos que atua como uma solução de **Supply Chain Security**. Ele gerencia pacotes privados e faz proxy de registries públicos, garantindo que cada dependência seja auditada via SBOM e monitorada continuamente contra vulnerabilidades.

## 🏗️ Arquitetura
O projeto segue a **Clean Architecture**, isolando as regras de conformidade da infraestrutura:
- **Application**: UseCases organizados por domínio (`artifact`, `package`, `compliance`).
- **Domain**: Entidades e regras de negócio puras.
- **Infrastructure**: Adapters para Dependency-Track, Vault, Redis e S3/MinIO.

## 🛡️ Governança e Compliance
- **Continuous SBOM Monitoring**: Integração nativa com **Dependency-Track**.
- **Metadata Strategy**: Extratores modulares (NPM concluído) via Strategy Pattern.
- **Quality Gate**: Bloqueio de merge via **Gatekeepers** (@sambura-artifacts/gatekeepers) e CODEOWNERS.

## 🚧 Roadmap

### ✅ Concluído (v1.1.0)
- [x] Barrel files para imports limpos.
- [x] Observabilidade com Prometheus, Grafana e Loki.
- [x] Integração com HashiCorp Vault e Lock distribuído Redis.
- [x] **Compliance Engine**: Dependency-Track Adapter e NpmMetadataExtractor.

### 🚧 Em Desenvolvimento (v1.2.0)
- [ ] Dashboards Grafana pré-configurados para Vulnerabilidades.
- [ ] Suporte a Maven (Java) e Cargo (Rust).
- [ ] Alertas automáticos via Prometheus AlertManager.

## 📄 Licença
Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE).

## 👥 Autores

- **Matheus Assis** - [GitHub](https://github.com/marafu)

