# 🚀 CI/CD - Integração e Deploy Contínuo

## 📋 Visão Geral

O Samburá Core utiliza **GitHub Actions** para automação de qualidade e deploy. O workflow principal é o **Quality Gate**, que executa análise estática, testes unitários, verificação de segurança e cobertura de código em paralelo.

## 🛡️ Quality Gate Workflow

### Triggers

O workflow é acionado em:
- **Push** para branches: `main`, `develop`, `feat/*`, `fix/*`
- **Pull Requests** para `main`

### Jobs

#### 1. 📊 Static Analysis (10 min)

Valida qualidade do código sem executá-lo:

```yaml
- Checkout do código
- Setup Dart SDK (stable)
- Instalação de dependências (dart pub get)
- Verificação de formatação (dart format)
- Análise estática (dart analyze --fatal-warnings)
```

**Critérios de Falha:**
- Código não formatado segundo padrão Dart
- Warnings do analyzer (unused imports, dead code, etc)

#### 2. 🧪 Unit Tests (15 min)

Executa suite de testes com infraestrutura necessária:

**Services:**
- **PostgreSQL 15**: Banco de dados de teste
- **Redis 7**: Cache em memória

**Configuração:**
```bash
Database: sambura_test
User: sambura
Password: sambura123
Redis: localhost:6379
```

**Comando:**
```bash
dart test --reporter=expanded --exclude-tags=integration
```

**Variáveis de Ambiente:**
- `DATABASE_URL`: Conexão PostgreSQL
- `REDIS_URL`: Conexão Redis
- `JWT_SECRET`: Chave para tokens JWT
- `MINIO_*`: Configuração MinIO (mock)
- `VAULT_TOKEN`: Token Vault (mock)

**Continue-on-error**: `true` - Testes com falhas conhecidas não bloqueiam pipeline

#### 3. 🔒 Security Analysis (10 min)

Verifica vulnerabilidades e vazamento de credenciais:

**Ferramentas:**
- **Gitleaks**: Detecta secrets, API keys, tokens no código

**Continue-on-error**: `true` - Não bloqueia pipeline

#### 4. 📈 Test Coverage (15 min)

Gera relatório de cobertura e envia para Codecov:

**Services:** PostgreSQL + Redis (mesma config do job Test)

**Steps:**
1. Gera coverage: `dart test --coverage=coverage --exclude-tags=integration`
2. Formata para LCOV: `coverage:format_coverage`
3. Upload para Codecov

**Continue-on-error**: `true` em todas as etapas

## 📊 Métricas de Qualidade

### Cobertura de Código

- **Target**: 80%+
- **Atual**: 80.1% (335/418 linhas)
- **Relatório**: `coverage/html/index.html`

### Testes

- **Total**: 185 testes
- **Passando**: 179 (96.7%)
- **Falhando**: 6 (issues conhecidas)
- **Excludes**: `--exclude-tags=integration`

### Análise Estática

- **Linter**: `dart analyze --fatal-warnings`
- **Formatter**: `dart format`
- **Sem warnings permitidos**

## 🔧 Executar Localmente

### Análise Completa

```bash
# Formatação
dart format .

# Análise estática
dart analyze --fatal-warnings

# Testes
dart test --reporter=expanded

# Coverage
dart test --coverage=coverage
genhtml coverage/lcov.info -o coverage/html
```

### Com Make

```bash
make test      # Testes
make coverage  # Coverage com HTML
make analyze   # Análise estática
```

### Com Docker

```bash
# Subir infraestrutura
docker-compose up -d postgres redis

# Executar testes
docker-compose run --rm app dart test
```

## 🐛 Troubleshooting CI/CD

### ❌ Testes Falhando

```bash
# Verificar logs específicos do job
# GitHub Actions > Workflow run > Test job > Step logs

# Executar localmente com mesmas variáveis
export DATABASE_URL=postgresql://sambura:sambura123@localhost:5432/sambura_test
export REDIS_URL=redis://localhost:6379
dart test
```

### ❌ Coverage Job Falhando

```bash
# Verificar se coverage foi gerado
ls -la coverage/lcov.info

# Formatar manualmente
dart pub global activate coverage
dart pub global run coverage:format_coverage \
  --lcov --in=coverage --out=coverage/lcov.info --report-on=lib
```

### ❌ Security Scan Alertas

```bash
# Executar Gitleaks localmente
docker run --rm -v $(pwd):/path zricethezav/gitleaks:latest \
  detect --source="/path" -v

# Adicionar exceções em .gitleaksignore se necessário
```

### ❌ Formatter Falhando

```bash
# Formatar automaticamente
dart format .

# Verificar sem modificar
dart format --output=none --set-exit-if-changed .
```

## 🔐 Secrets Necessários

### GitHub Secrets

- `GITHUB_TOKEN`: Auto-gerado pelo GitHub (já disponível)
- `CODECOV_TOKEN`: Token para upload de coverage (opcional)

### Variáveis de Ambiente

Configuradas no workflow, não precisam de secrets:
- `JWT_SECRET`: Gerado para testes
- Credenciais de serviços (PostgreSQL, Redis)

## 📈 Melhorias Futuras

### v1.1
- [ ] Testes de integração com MinIO real
- [ ] Testes E2E com servidor completo
- [ ] Cache de dependências do Dart
- [ ] Matrix testing (múltiplas versões Dart)

### v2.0
- [ ] Deploy automático para staging
- [ ] Smoke tests pós-deploy
- [ ] Performance benchmarks
- [ ] Análise de dependências vulneráveis (Dependabot)
- [ ] Container scanning (Trivy)

## 📚 Recursos

- [GitHub Actions Docs](https://docs.github.com/actions)
- [Dart CI Best Practices](https://dart.dev/guides/testing/continuous-integration)
- [Codecov Documentation](https://docs.codecov.com/)
- [Gitleaks](https://github.com/gitleaks/gitleaks)

---

**Última atualização**: 24 de dezembro de 2025
