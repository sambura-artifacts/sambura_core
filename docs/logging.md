# Sistema de Logging do Samburá Core

## Visão Geral

Este projeto implementa um sistema de logging completo e estruturado usando o pacote `logging` do Dart. O sistema fornece rastreamento detalhado de todas as operações, facilitando debug, monitoramento e análise de problemas em produção.

## Configuração

### Inicialização

O sistema de logging é inicializado no arquivo principal `bin/server.dart`:

```dart
import 'package:sambura_core/config/logger.dart';

void main() async {
  // Inicializa o sistema de logging
  LoggerConfig.initialize(level: Level.ALL);
  
  // Obtém logger para o contexto atual
  final log = LoggerConfig.getLogger('Server');
  
  log.info('Iniciando aplicação...');
}
```

### Níveis de Log

O sistema suporta os seguintes níveis de log (do mais severo ao menos):

- **SEVERE** (🔥): Erros críticos que impedem o funcionamento
- **WARNING** (⚠️): Situações anormais que não impedem a execução
- **INFO** (ℹ️): Informações gerais sobre o fluxo da aplicação
- **CONFIG** (⚙️): Informações de configuração
- **FINE** (🔍): Informações detalhadas para debug
- **FINER** (🔬): Informações muito detalhadas
- **FINEST** (🧬): Máximo nível de detalhamento

### Formato das Mensagens

Cada mensagem de log segue o formato:

```
{emoji} [{timestamp}] [{logger_name}] {level}: {message}
```

Exemplo:
```
ℹ️ [2025-12-22T10:30:45.123456] [Server] INFO: Samburá online em http://0.0.0.0:8080
```

## Uso por Componente

### Controllers

Todos os controllers possuem logging para:
- Requisições recebidas
- Resultados de buscas
- Erros durante processamento
- Respostas enviadas

```dart
class ArtifactController {
  final Logger _log = LoggerConfig.getLogger('ArtifactController');
  
  Future<Response> upload(...) async {
    _log.info('Upload iniciado: repo=$repositoryName, pkg=$packageName');
    // ... lógica
    _log.info('Upload concluído: artifact_id=$id');
  }
}
```

### Use Cases

Use cases registram:
- Início e fim de operações
- Decisões de negócio (cache hit/miss, proxy, etc)
- Falhas e sucessos

```dart
class GetArtifactUseCase {
  final Logger _log = LoggerConfig.getLogger('GetArtifactUseCase');
  
  Future<ArtifactEntity?> execute(...) async {
    _log.info('Buscando: $repositoryName/$packageName@$version');
    // ...
    if (local != null) {
      _log.info('Cache Hit! Retornando arquivo local');
      return local;
    }
  }
}
```

### Repositórios

Repositórios logam:
- Operações de banco de dados
- Queries executadas
- Resultados de buscas
- Erros de persistência

```dart
class PostgresArtifactRepository {
  final Logger _log = LoggerConfig.getLogger('PostgresArtifactRepository');
  
  Future<ArtifactEntity> save(ArtifactEntity artifact) async {
    // ...
    _log.info('Artifact salvo: id=$id, version=${artifact.version}');
  }
}
```

### Serviços

Serviços externos registram:
- Chamadas a APIs externas
- Downloads e uploads
- Tempo de execução
- Falhas de comunicação

```dart
class NpmProxyService {
  final Logger _log = LoggerConfig.getLogger('NpmProxyService');
  
  Future<BlobEntity> fetchAndStore(...) async {
    _log.info('Solicitando upstream: $url');
    // ...
    _log.info('Sincronização concluída | Tempo: ${stopwatch.elapsedMilliseconds}ms');
  }
}
```

## Melhores Práticas

### 1. Escolha o Nível Correto

- Use `info()` para operações principais do fluxo
- Use `fine()` para detalhes de debug
- Use `warning()` para situações anormais não críticas
- Use `severe()` para erros que exigem atenção imediata

### 2. Mensagens Claras e Contextuais

✅ BOM:
```dart
_log.info('Upload concluído: artifact_id=${artifact.externalId}, size=${blob.sizeBytes}');
```

❌ RUIM:
```dart
_log.info('Sucesso');
```

### 3. Logs de Erro com Stack Trace

Sempre inclua exceção e stack trace em logs de erro:

```dart
try {
  // código
} catch (e, stackTrace) {
  _log.severe('Erro ao processar upload', e, stackTrace);
  rethrow;
}
```

### 4. Logs de Performance

Para operações longas, registre tempo de execução:

```dart
final stopwatch = Stopwatch()..start();
// ... operação
stopwatch.stop();
_log.info('Operação concluída em ${stopwatch.elapsedMilliseconds}ms');
```

## Configuração em Produção

Para produção, ajuste o nível de log no `main()`:

```dart
// Desenvolvimento
LoggerConfig.initialize(level: Level.ALL);

// Produção
LoggerConfig.initialize(level: Level.INFO);

// Apenas erros
LoggerConfig.initialize(level: Level.WARNING);
```

## Monitoramento

Os logs são enviados para:
- `stdout`: INFO, CONFIG, FINE, FINER, FINEST
- `stderr`: SEVERE, WARNING

Isso facilita a separação de logs normais e erros em sistemas de monitoramento.

## Componentes com Logging

✅ **Implementado em:**
- bin/server.dart
- lib/infrastructure/api/controller/*
- lib/application/usecase/*
- lib/infrastructure/repositories/*
- lib/infrastructure/services/*
- lib/infrastructure/database/*

## Exemplos de Logs Gerados

### Inicialização
```
ℹ️ [2025-12-22T10:30:45.123] [Server] INFO: Iniciando os motores do Samburá...
ℹ️ [2025-12-22T10:30:45.234] [Server] INFO: Configurações carregadas: localhost:5432
ℹ️ [2025-12-22T10:30:45.456] [PostgresConnector] INFO: Conectando ao Postgres: localhost:5432/sambura
ℹ️ [2025-12-22T10:30:45.678] [PostgresConnector] INFO: Postgres conectado com sucesso
🚀 [2025-12-22T10:30:46.000] [Server] INFO: Samburá online em http://0.0.0.0:8080
```

### Operação de Upload
```
ℹ️ [2025-12-22T10:31:00.123] [ArtifactController] INFO: Upload iniciado: repo=npm-public, pkg=express, version=4.18.2
ℹ️ [2025-12-22T10:31:00.234] [CreateArtifactUsecase] INFO: Iniciando criação de artefato: express@4.18.2
🔍 [2025-12-22T10:31:00.345] [CreateArtifactUsecase] FINE: Salvando blob a partir do stream de dados
ℹ️ [2025-12-22T10:31:01.456] [SiloBlobRepository] INFO: Blob hash calculado: abc123def456...
ℹ️ [2025-12-22T10:31:01.567] [SiloBlobRepository] INFO: Blob salvo no MinIO: abc123def456...
ℹ️ [2025-12-22T10:31:01.678] [CreateArtifactUsecase] INFO: Artifact 4.18.2 salvo com sucesso! ID: 550e8400-e29b-41d4-a716-446655440000
ℹ️ [2025-12-22T10:31:01.789] [ArtifactController] INFO: Upload concluído com sucesso: artifact_id=550e8400-e29b-41d4-a716-446655440000
```

### Erro durante Operação
```
🔥 [2025-12-22T10:32:00.123] [ArtifactController] SEVERE: Erro ao processar upload de express@4.18.2
  ❌ Error: Connection timeout
  📚 Stack trace:
  #0      PostgresConnector.query (package:sambura_core/infrastructure/database/postgres_connector.dart:45:7)
  #1      PostgresArtifactRepository.save (package:sambura_core/infrastructure/repositories/postgres_artifact_repository.dart:23:5)
  ...
```

## Troubleshooting

### Logs não aparecem
Verifique se `LoggerConfig.initialize()` foi chamado no início do `main()`.

### Muitos logs em produção
Ajuste o nível para `Level.INFO` ou `Level.WARNING`.

### Logs sem contexto
Sempre inclua variáveis relevantes nas mensagens de log.

---

**Nota**: Este sistema de logging foi implementado em 22/12/2025 e está ativo em todos os componentes do Samburá Core.
