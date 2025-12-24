# 🎯 Samburá Core

> Proxy de artefatos NPM com persistência em S3 e PostgreSQL, construído com Clean Architecture em Dart

[![Dart Version](https://img.shields.io/badge/dart-%3E%3D3.0.0-blue.svg)](https://dart.dev/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

## 📋 Sumário

- [Sobre](#-sobre)
- [Arquitetura](#-arquitetura)
- [Tecnologias](#-tecnologias)
- [Pré-requisitos](#-pré-requisitos)
- [Instalação](#-instalação)
- [Uso](#-uso)
- [API](#-api)
- [Estrutura do Projeto](#-estrutura-do-projeto)
- [Desenvolvimento](#-desenvolvimento)
- [Testes](#-testes)
- [Contribuindo](#-contribuindo)

## 🎯 Sobre

**Samburá Core** é um proxy de artefatos NPM que permite:

- 📦 **Gerenciar pacotes privados** com repositórios customizados
- 🔐 **Autenticação JWT e API Keys** para controle de acesso
- 💾 **Persistência em S3** (MinIO) com cache Redis
- 🔄 **Proxy transparente** do NPM Registry público
- 🎨 **Clean Architecture** para manutenibilidade e escalabilidade
- 🐳 **Docker ready** para deploy simplificado

## 🏗️ Arquitetura

O projeto segue os princípios da **Clean Architecture** com separação clara de responsabilidades:

```
┌─────────────────────────────────────┐
│          Presentation               │
│  (Controllers, Routes, Presenters)  │
├─────────────────────────────────────┤
│          Application                │
│      (Use Cases, DTOs, Ports)       │
├─────────────────────────────────────┤
│            Domain                   │
│  (Entities, Value Objects, Rules)   │
├─────────────────────────────────────┤
│         Infrastructure              │
│ (Repositories, Adapters, Services)  │
└─────────────────────────────────────┘
```

Para detalhes completos, veja [README_STRUCTURE.md](README_STRUCTURE.md).

## 🛠️ Tecnologias

- **[Dart](https://dart.dev/)** - Linguagem principal
- **[Shelf](https://pub.dev/packages/shelf)** - Framework HTTP
- **[PostgreSQL](https://www.postgresql.org/)** - Banco de dados relacional
- **[MinIO](https://min.io/)** - Armazenamento de objetos (S3-compatible)
- **[Redis](https://redis.io/)** - Cache e sessões
- **[Vault](https://www.vaultproject.io/)** - Gerenciamento de secrets
- **[Docker](https://www.docker.com/)** - Containerização

## 📦 Pré-requisitos

- **Dart SDK** >= 3.0.0
- **Docker** e **Docker Compose** (opcional, mas recomendado)
- **Make** (opcional, para comandos simplificados)

## 🚀 Instalação

### 1. Clone o repositório

```bash
git clone https://github.com/sambura/sambura_core.git
cd sambura_core
```

### 2. Instale as dependências

```bash
dart pub get
```

### 3. Configure as variáveis de ambiente

Crie um arquivo `.env` na raiz do projeto:

```bash
# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=sambura
DB_USER=sambura
DB_PASSWORD=sambura

# MinIO (S3)
MINIO_ENDPOINT=localhost:9000
MINIO_ACCESS_KEY=minioadmin
MINIO_SECRET_KEY=minioadmin
MINIO_BUCKET=artifacts

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379

# JWT
JWT_SECRET=your-super-secret-jwt-key-change-this

# Server
PORT=8080
```

### 4. Inicie os serviços (Docker)

```bash
docker-compose up -d
```

Ou use o Makefile:

```bash
make dev
```

## 🎮 Uso

### Executar o servidor

**Com Dart:**
```bash
dart run bin/server.dart
```

**Com Make:**
```bash
make run
```

**Com Docker:**
```bash
docker build -t sambura-core .
docker run -p 8080:8080 sambura-core
```

O servidor estará disponível em `http://localhost:8080`

### Acessar a documentação

Abra no navegador: `http://localhost:8080/api/v1/docs`

## 🌐 API

### Endpoints Principais

#### Autenticação
```bash
# Registrar usuário
POST /api/v1/auth/register
Content-Type: application/json

{
  "username": "matheus",
  "email": "matheus@sambura.io",
  "password": "senha123"
}

# Login
POST /api/v1/auth/login
Content-Type: application/json

{
  "username": "matheus",
  "password": "senha123"
}
```

#### API Keys
```bash
# Criar API Key
POST /api/v1/admin/api-keys
Authorization: Bearer <token>

{
  "name": "minha-chave-ci-cd"
}

# Listar API Keys
GET /api/v1/admin/api-keys
Authorization: Bearer <token>

# Revogar API Key
DELETE /api/v1/admin/api-keys/{id}
Authorization: Bearer <token>
```

#### Repositórios
```bash
# Criar repositório
POST /api/v1/admin/repositories
Authorization: Bearer <token>

{
  "name": "my-repo",
  "namespace": "@sambura",
  "is_public": false
}

# Listar repositórios
GET /api/v1/admin/repositories
Authorization: Bearer <token>
```

#### Upload de Artefatos
```bash
# Upload
POST /api/v1/admin/upload
Authorization: Bearer <token>
Content-Type: multipart/form-data

file=@package.tgz
package=@sambura/core
version=1.0.0
repository=my-repo
```

#### Download de Artefatos
```bash
# Resolver artefato
GET /api/v1/{repositoryName}/{packageName}/{version}
Authorization: Bearer <token>

# Download
GET /api/v1/download/{namespace}/{name}/{version}
Authorization: Bearer <token>

# Download de blob direto
GET /api/v1/blobs/{hash}
Authorization: Bearer <token>
```

#### NPM Compatible
```bash
# Metadados do pacote (NPM format)
GET /api/v1/npm/{repo}/{packageName}
```

Para documentação completa da API, acesse `/api/v1/docs` ou veja [specs/swagger.yaml](specs/swagger.yaml).

## 📁 Estrutura do Projeto

```
sambura_core/
├── bin/
│   └── server.dart          # Ponto de entrada
├── lib/
│   ├── application/         # Casos de uso e DTOs
│   │   ├── usecase/
│   │   │   ├── account/
│   │   │   ├── api_key/
│   │   │   ├── artifact/
│   │   │   ├── auth/
│   │   │   └── package/
│   │   ├── dtos/
│   │   ├── ports/
│   │   └── exceptions/
│   ├── domain/              # Regras de negócio
│   │   ├── entities/
│   │   ├── factories/
│   │   ├── value_objects/
│   │   ├── repositories/
│   │   ├── services/
│   │   └── exceptions/
│   ├── infrastructure/      # Implementações
│   │   ├── adapters/
│   │   │   ├── auth/
│   │   │   ├── cache/
│   │   │   ├── crypto/
│   │   │   ├── secrets/
│   │   │   └── storage/
│   │   ├── api/
│   │   │   ├── controller/
│   │   │   ├── presenter/
│   │   │   ├── middleware/
│   │   │   └── routes/
│   │   ├── repositories/
│   │   │   ├── postgres/
│   │   │   └── blob/
│   │   └── services/
│   ├── shared/              # Código compartilhado
│   └── config/              # Configurações
├── test/                    # Testes
├── docs/                    # Documentação
├── sql/                     # Scripts SQL
├── specs/                   # Swagger/OpenAPI
├── docker-compose.yaml
├── Dockerfile
├── Makefile
└── pubspec.yaml
```

Para detalhes completos, veja [README_STRUCTURE.md](README_STRUCTURE.md).

## 🔧 Desenvolvimento

### Comandos úteis

```bash
# Desenvolvimento com hot reload
make dev

# Executar testes
make test

# Cobertura de testes
make coverage

# Análise estática
dart analyze

# Formatar código
dart format .

# Limpar build
make clean
```

### Makefile targets

- `make dev` - Inicia ambiente de desenvolvimento
- `make run` - Executa o servidor
- `make test` - Executa testes
- `make coverage` - Gera relatório de cobertura
- `make clean` - Limpa cache e build
- `make docker-build` - Constrói imagem Docker
- `make docker-up` - Inicia containers
- `make docker-down` - Para containers

## 🧪 Testes

```bash
# Executar todos os testes
dart test

# Executar testes específicos
dart test test/domain/

# Com cobertura
dart test --coverage=coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## 🤝 Contribuindo

Contribuições são bem-vindas! Por favor:

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/MinhaFeature`)
3. Commit suas mudanças (`git commit -m 'feat: adiciona MinhaFeature'`)
4. Push para a branch (`git push origin feature/MinhaFeature`)
5. Abra um Pull Request

Veja [CONTRIBUTING.md](CONTRIBUTING.md) para mais detalhes.

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

## 👥 Autores

- **Matheus** - [GitHub](https://github.com/sambura)

## 🙏 Agradecimentos

- Equipe Dart/Flutter
- Comunidade Open Source
- Todos os contribuidores

---

Feito com ❤️ e ☕ pela equipe Samburá
