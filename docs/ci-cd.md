# 🚀 CI/CD - Integração e Deploy Contínuo

## 📋 Visão Geral

O Samburá Core utiliza **GitHub Actions** para automação de qualidade. O workflow **Quality Gate** executa análise estática, testes unitários e verificação de segurança em paralelo, com foco em simplicidade e velocidade.

## 🛡️ Quality Gate Workflow

### Triggers

O workflow é acionado em:
- **Push** para branches: `main`, `develop`, `feat/*`, `fix/*`
- **Pull Requests** para `main`

### Jobs

#### 1. 🔒 Security Scan (5 min)

Verifica vazamento de credenciais e secrets no código:

```yaml
- Checkout com histórico completo (fetch-depth: 0)
- Gitleaks: Detecta secrets, API keys, tokens
```

**Continue-on-error**: `true` - Não bloqueia pipeline

#### 2. 📊 Analysis & Tests (15 min)

Job unificado que executa todas as verificações de qualidade:

**Steps:**

1. **Checkout** - Clone do repositório
2. **Setup Dart** - Instala Dart SDK stable
3. **Install Dependencies** - `dart pub get`
4. **Verify Formatting** - `dart format --output=none --set-exit-if-changed .`
5. **Static Analysis** - `dart analyze --fatal-warnings`
6. **Run Unit Tests** - `dart test --reporter=expanded --exclude-tags=integration`
7. **Generate Coverage** - `dart test --coverage=coverage --exclude-tags=integration`
8. **Format Coverage** - Converte para formato LCOV
9. **Coverage Summary** - Exibe estatísticas no log (% e linhas cobertas)

**Critérios de Falha:**
- Código não formatado segundo padrão Dart
- Warnings do analyzer (unused imports, dead code, etc)

**Continue-on-error**: Testes e coverage não bloqueiam (6 falhas conhecidas)

## 🧪 Arquitetura de Testes

### Testes com Mocks

O projeto utiliza **mocks e in-memory implementations** ao invés de serviços reais:

- ✅ **Banco de Dados**: Mock em memória (sem PostgreSQL)
- ✅ **Cache**: Mock em memória (sem Redis)
- ✅ **Storage**: Mock em memória (sem MinIO)
- ✅ **Secrets**: Mock em memória (sem Vault)

**Vantagens:**
- ⚡ **Rápido**: Sem overhead de containers Docker
- 🎯 **Determinístico**: Testes sempre produzem mesmo resultado
- 💰 **Econômico**: Não requer infraestrutura externa
- 🔧 **Simples**: Sem configuração complexa de serviços

### Tags de Teste

- `--exclude-tags=integration`: Exclui testes que requerem serviços reais
- Testes unitários rodam 100% em memória

## 📊 Métricas de Qualidade

### Cobertura de Código

- **Target**: 80%+
- **Atual**: 80.1% (335/418 linhas)
- **Relatório Local**: `coverage/html/index.html`
- **CI**: Estatísticas no log do workflow

### Testes

- **Total**: 185 testes
- **Passando**: 179 (96.7%)
- **Falhando**: 6 (issues conhecidas - ExternalId validation)
- **Excludes**: `--exclude-tags=integration`

### Análise Estática

- **Linter**: `dart analyze --fatal-warnings`
- **Formatter**: `dart format`
- **Nível**: Warnings bloqueiam (infos não)

## 🔧 Executar Localmente

### Análise Completa

```bash
# Formatação
dart format .

# Análise estática
dart analyze --fatal-warnings

# Testes
dart test --reporter=expanded --exclude-tags=integration

# Coverage
dart test --coverage=coverage --exclude-tags=integration
dart pub global activate coverage
dart pub global run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --report-on=lib

# Gerar HTML de coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html  # ou xdg-open no Linux
```

### Com Make

```bash
make test      # Testes com reporter expanded
make coverage  # Coverage com HTML
make analyze   # Análise estática
make format    # Formata código
```

### Executar Teste Específico

```bash
# Por arquivo
dart test test/domain/entities/account_entity_test.dart

# Por padrão
dart test --name "Account"

# Com coverage de arquivo específico
dart test test/domain/ --coverage=coverage
```

## 🐛 Troubleshooting CI/CD

### ❌ Workflow Falhando no Static Analysis

**Problema**: `dart analyze --fatal-warnings` encontrou warnings

**Solução**:
```bash
# Ver warnings localmente
dart analyze

# Corrigir automaticamente (quando possível)
dart fix --apply

# Suprimir warning específico (último caso)
// ignore: warning_type
var x = something();
```

### ❌ Testes Falhando Localmente mas Passando no CI

**Problema**: Diferenças de ambiente

**Solução**:
```bash
# Limpar cache
dart pub cache clean
dart pub get

# Verificar versão do Dart
dart --version  # Deve ser stable (mesma do CI)

# Limpar build artifacts
rm -rf .dart_tool/
dart pub get
```

### ❌ Coverage Não Gerando Relatório

**Problema**: Comando `coverage:format_coverage` falhando

**Solução**:
```bash
# Verificar se coverage foi gerado
ls -la coverage/

# Verificar se coverage tool está instalado
dart pub global activate coverage

# Adicionar ao PATH se necessário
export PATH="$PATH":"$HOME/.pub-cache/bin"

# Gerar manualmente
dart pub global run coverage:format_coverage \
  --lcov \
  --in=coverage \
  --out=coverage/lcov.info \
  --report-on=lib
```

### ❌ Gitleaks Encontrando Falsos Positivos

**Problema**: Secrets de teste ou exemplos sendo detectados

**Solução**:
```bash
# Criar .gitleaksignore na raiz
echo "test/**" >> .gitleaksignore
echo "docs/**" >> .gitleaksignore

# Ou adicionar comentário inline
const secret = "fake-secret-for-testing"; // gitleaks:allow
```

### ❌ Formatter Alterando Arquivos Gerados

**Problema**: `dart format` modificando `.g.dart` ou outros gerados

**Solução**:
```bash
# Arquivos gerados já devem estar formatados
# Se não, regenere-os:
dart run build_runner build --delete-conflicting-outputs

# Ou adicione ao .gitignore
**/*.g.dart
**/*.freezed.dart
```

## 📈 Performance do CI

### Tempos Médios

| Job | Duração | Pode Falhar |
|-----|---------|-------------|
| Security Scan | ~2 min | ✅ Sim |
| Analysis & Tests | ~8 min | ⚠️ Parcial |
| - Install Deps | ~30s | ❌ Não |
| - Formatting | ~10s | ❌ Não |
| - Static Analysis | ~20s | ❌ Não |
| - Run Tests | ~5 min | ✅ Sim |
| - Generate Coverage | ~2 min | ✅ Sim |
| **Total** | **~10 min** | - |

### Otimizações Implementadas

✅ **Jobs em Paralelo**: Security e Analysis rodam simultaneamente  
✅ **Sem Docker**: Mocks eliminam overhead de containers  
✅ **Continue-on-error**: Testes conhecidos não bloqueiam  
✅ **Timeouts**: Previne workflows travados  
✅ **Cache de deps**: Pub cache do GitHub Actions  

## 🔐 Secrets e Variáveis

### GitHub Secrets Necessários

- `GITHUB_TOKEN`: ✅ Auto-gerado (já disponível)

**Não requer configuração adicional** - testes usam mocks!

### Variáveis de Ambiente

Nenhuma variável externa necessária no CI. Testes utilizam:
- Mocks em memória para todos os serviços
- Dados faker/fixture para cenários
- No estado compartilhado entre testes

## 📈 Melhorias Futuras

### v1.1
- [ ] Cache de dependências Dart pub mais agressivo
- [ ] Matrix testing (múltiplas versões Dart: stable, beta, dev)
- [ ] Testes de mutação (mutation testing)
- [ ] Badges dinâmicos de coverage no README

### v2.0
- [ ] Deploy automático para staging (Cloud Run/Fly.io)
- [ ] Smoke tests pós-deploy
- [ ] Performance benchmarks comparativos
- [ ] Análise de dependências vulneráveis (Dependabot)
- [ ] Teste de carga básico (k6)

## 📚 Recursos

- [GitHub Actions Documentation](https://docs.github.com/actions)
- [Dart Testing Best Practices](https://dart.dev/guides/testing)
- [Dart CI/CD Guide](https://dart.dev/guides/testing/continuous-integration)
- [Gitleaks Secret Scanning](https://github.com/gitleaks/gitleaks)
- [Coverage Package](https://pub.dev/packages/coverage)

## 💡 Boas Práticas

### ✅ Do's

- ✅ Manter testes rápidos (< 10 min total)
- ✅ Usar mocks para dependências externas
- ✅ Executar CI localmente antes do push
- ✅ Manter coverage acima de 80%
- ✅ Corrigir warnings do analyzer
- ✅ Formatar código antes de commitar

### ❌ Don'ts

- ❌ Depender de serviços externos no CI
- ❌ Ignorar falhas de testes sistematicamente
- ❌ Commitar código não formatado
- ❌ Usar `// ignore:` indiscriminadamente
- ❌ Deixar testes flaky (não determinísticos)
- ❌ Fazer testes que dependem de ordem de execução

---

**Última atualização**: 24 de dezembro de 2025  
**Versão**: 1.0  
**Status**: ✅ Operacional
