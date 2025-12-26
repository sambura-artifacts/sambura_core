# Samburá Core - Docker Setup

Estrutura completa de containers, monitoramento e observabilidade para o Samburá Core.

## 🎯 Stack Completa

- **sambura_app**: Aplicação Dart (Samburá Core)
- **postgres**: PostgreSQL 15 (metadados)
- **minio**: MinIO (S3-compatible storage)
- **redis**: Redis 7 (cache de autenticação)
- **vault**: HashiCorp Vault (secrets)
- **prometheus**: Métricas
- **grafana**: Dashboards e visualização
- **loki**: Agregação de logs
- **promtail**: Shipping de logs

## 📁 Estrutura

```
docker/
├── app/
│   └── Dockerfile              # Build multi-stage da aplicação Dart
├── monitoring/
│   ├── promtail-config.yml     # Configuração do log shipper
│   ├── prometheus.yml          # Scraping de métricas
│   └── grafana-datasources.yml # Datasources (Prometheus, Loki)
├── docker-compose.yml          # Orquestração completa
└── README.md                   # Este arquivo
```

## 🚀 Uso Rápido

### Subir toda a infraestrutura

```bash
cd docker
docker-compose up -d
```

### Buildar apenas a aplicação

```bash
docker-compose build sambura_app
```

### Ver logs

```bash
# Aplicação
docker-compose logs -f sambura_app

# Todos os serviços
docker-compose logs -f
```

### Parar tudo

```bash
docker-compose down
```

### Limpar volumes (cuidado!)

```bash
docker-compose down -v
```

## 🏗️ Serviços Disponíveis

### Aplicação
- **Samburá App**: `http://localhost:8080`
  - Health: `http://localhost:8080/health`
  - Liveness: `http://localhost:8080/health/liveness`

### Infraestrutura
- **PostgreSQL**: `localhost:5432`
- **Redis**: `localhost:6379`
- **MinIO**: `http://localhost:9000` (Console: `9001`)
- **Vault**: `http://localhost:8200`

### Observabilidade
- **Grafana**: `http://localhost:3000` (admin/admin)
- **Prometheus**: `http://localhost:9090`
- **Loki**: `http://localhost:3100`
- **Tempo**: `http://localhost:3200`

## 📊 Monitoramento

### Grafana Dashboards

1. Acesse `http://localhost:3000`
2. Login: `admin` / `admin`
3. Datasources já configurados:
   - Loki (logs)
   - Prometheus (métricas)
   - Tempo (traces)

### Queries de Exemplo (Loki)

```logql
# Logs da aplicação
{job="sambura_core"}

# Apenas erros
{job="sambura_core"} |= "ERROR"

# Filtrar por logger
{job="sambura_core", logger="ArtifactController"}
```

## 🔧 Variáveis de Ambiente

Todas as variáveis estão definidas no `docker-compose.yml`. Para produção, use `.env`:

```bash
cp .env.example .env
# Edite .env com suas credenciais
```

## 🐛 Troubleshooting

### App não sobe

```bash
# Verificar logs
docker-compose logs sambura_app

# Verificar health check
curl http://localhost:8080/health/liveness
```

### Banco não conecta

```bash
# Verificar se Postgres está healthy
docker-compose ps postgres

# Testar conexão
docker exec -it sambura_db psql -U sambura -d sambura_metadata
```

### Logs não aparecem no Grafana

```bash
# Verificar se Promtail está rodando
docker-compose logs promtail

# Verificar se Loki está recebendo logs
curl http://localhost:3100/ready
```

## 📦 Build Multi-Stage

O Dockerfile usa multi-stage build:
1. **Stage Build**: Compila a aplicação Dart (AOT)
2. **Stage Runtime**: Imagem mínima com apenas o binário

Tamanho final da imagem: ~150MB

## 🔒 Segurança

- Aplicação roda como usuário não-root (`sambura`)
- Health checks configurados em todos os serviços
- Secrets gerenciados pelo Vault (dev mode)
- Rede isolada entre serviços

## 📝 Notas

- **Dev Mode**: Vault usa token hardcoded (`root_token_dev`)
- **Produção**: Configure Vault adequadamente e use secrets reais
- **Logs**: Armazenados em `../logs/` (ignorado no git)
- **Volumes**: Dados persistidos em volumes Docker
