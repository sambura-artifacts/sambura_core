# Debugging Race Conditions & Rate Limiting

## Problema Identificado

Múltiplas requisições simultâneas de pacotes NPM diferentes podem causar:
1. **Rate Limiting do NPM Registry** - bloqueia IP após ~10+ requisições paralelas
2. **Race Condition no Stream** - `StreamSplitter` dividindo o mesmo stream para 2 consumidores
3. **HTTP Client Connection Pool** - limite de conexões simultâneas

## Sintomas

```
sambura_app | 🚨 [SERVER ERROR] /api/v1/npm/public/@babel/compat-data/-/compat-data-7.22.20.tgz: ExternalServiceUnavailableException
sambura_app | ⚠️ [HTTP] Status XXX para registry.npmjs.org/...
```

Todos os logs chegam com latência similar (~400-500ms) → rate limiting do remoto.

## Mitigações Implementadas

### 1. Delay Entre Requisições
```dart
// No BasePackageHandler.handle()
await Future.delayed(const Duration(milliseconds: 150));
```
- Espaça requisições simultâneas
- Reduz burst de conexões

### 1.1. Tratamento 503 para ExternalServiceUnavailable
- `HttpClientAdapter.stream()` mapeia status >=500 para `ExternalServiceUnavailableException`.
- `NpmHandler.handle()` captura e rethrow como erro de conectividade.
- `ErrorPresenter.fromException()` agora retorna HTTP 503 (`serviceUnavailable`) para esse erro.
- Evita 500 genérico em timeout/NPM indisponível.

### 1.2. Suporte a Scoped Package na URL
- `NpmController.downloadTarball` extrai `unscopedName` com `split('/')`.
- `filename` parseado de `unscopedName-version.tgz`.
- `NpmHandler.buildRemoteUrl` usa o `unscopedName` no segmento `/-/` e inclui scope no pacote original.


### 2. Timeout Aumentado
```dart
// No HttpClientAdapter.stream()
.timeout(const Duration(seconds: 60)) // Era 30s
```
- Aguarda mais tempo em caso de rate limiting
- Permite retry interno do NPM

### 3. Logging Detalhado
```
🌐 [HTTP] GET host/path
⚠️ [HTTP] Status 429 Too Many Requests
✅ [HTTP] 200 OK (1234 bytes)
```
- Identifica exatamente onde falha

### 4. Cache Redis por Pacote
```dart
final lockKey = 'lock:download:npm:${packageName}:${version}';
```
- Evita downloads duplicados **do mesmo pacote**
- Não evita rate limiting de **múltiplos pacotes**

## Como Testar

### Teste 1: Requisição Única
```bash
curl -I http://localhost:8080/api/v1/npm/public/lodash/-/lodash-4.17.21.tgz
```
Se funcionar → problema é rate limiting em concorrência.

### Teste 2: 10 Requisições Simultâneas
```bash
for i in {1..10}; do
  curl -I http://localhost:8080/api/v1/npm/public/lodash/-/lodash-4.17.21.tgz &
done
```
Se falhar → confirma race condition/rate limiting.

### Teste 3: Ver Logs HTTP
```bash
docker logs sambura_app | grep "⚠️ \[HTTP\]"
```
Procure por:
- `429 Too Many Requests` → rate limiting
- `503 Unavailable` → servidor indisponível
- `Timeout 60s` → timeout de conexão

## Próximas Melhorias

1. **Circuit Breaker** para o NPM Registry
2. **Exponential Backoff** em caso de 429
3. **Connection Pool Customizado** no http.Client
4. **Fila Assíncrona** com prioridade para limitar paralelismo
5. **Usar Proxy Oficial** do NPM se disponível

## Referências

- NPM Registry Rate Limit: ~600 requests/10min per IP
- `StreamSplitter` docs: require sincronização perfeita
- HTTP/1.1 Keep-Alive: compartilha conexões
