# ==============================================================================
# VARIÁVEIS DE AMBIENTE
# ==============================================================================
API_URL=http://localhost:8080
ADMIN_USER=cria_root
ADMIN_PASS=senha_braba_123
ADMIN_EMAIL=admin@sambura.io

# Configurações de Infra
DB_URL=postgres://sambura:sambura_db_secret@localhost:5432/sambura_metadata
BUCKET_NAME=sambura-blobs
SILO_HOST=localhost
SILO_PORT_API=9000
SILO_ACCESS_KEY=sambura_admin
SILO_SECRET_KEY=sambura_silo_secret

# Dados para criação do repositório inicial
REPO_URL=$(API_URL)/admin/repositories
REPO_DATA='{"name": "npm-proxy", "namespace": "npm", "is_public": true, "type": "proxy"}'

# Carrega .env se existir
ifneq ("$(wildcard .env)","")
    include .env
    export $(shell sed 's/=.*//' .env)
endif

.PHONY: help up down dev db-init db-reset db-refresh vault-seed auth-register auth-login create-repo setup-all check

# ==============================================================================
# HELP & INFO
# ==============================================================================
help: ## Mostra os comandos disponíveis
	@echo "🌊 Samburá Control Center - Comandos Disponíveis:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

# ==============================================================================
# INFRAESTRUTURA (Docker)
# ==============================================================================
up: ## Sobe os containers (Postgres, Redis, Vault, MinIO, RabbitMQ)
	docker-compose up -d
	@echo "🚀 Infraestrutura subindo em background..."

down: ## Para todos os containers e remove redes
	docker-compose down
	@echo "🛑 Infraestrutura offline."

logs: ## Acompanha os logs dos containers
	docker-compose logs -f

# ==============================================================================
# BANCO DE DADOS
# ==============================================================================
db-init: ## Cria as tabelas do zero usando o script SQL
	@echo "🏗️  Estruturando o banco de dados..."
	@docker exec -i sambura_db psql -U sambura -d sambura_metadata < sql/init.sql
	@echo "✅ Tabelas criadas com sucesso!"

db-reset: ## Limpa os dados das tabelas (TRUNCATE)
	@echo "⚠️  Limpando dados..."
	@docker exec -i sambura_db psql -U sambura -d sambura_metadata -c "TRUNCATE TABLE artifacts, packages, repositories, blobs, accounts RESTART IDENTITY CASCADE;"
	@echo "✨ Banco limpo!"

db-shell: ## Abre o terminal psql dentro do container
	@docker exec -it sambura_db psql -U sambura -d sambura_metadata

# ==============================================================================
# VAULT (Segredos) - Com Token de Root
# ==============================================================================
vault-seed: ## Injeta os segredos manuais usando o token de root
	@echo "🔐 Injetando pimenta e chaves no Vault..."
	@docker exec -e VAULT_ADDR='http://127.0.0.1:8200' -e VAULT_TOKEN='root_token_sambura' sambura_vault \
		vault kv put -mount=secret sambura/database password="sambura_db_secret"
	@docker exec -e VAULT_ADDR='http://127.0.0.1:8200' -e VAULT_TOKEN='root_token_sambura' sambura_vault \
		vault kv put -mount=secret sambura/auth jwt_secret="chave_mestra_sambura_2025" pepper="pimenta_no_reino"
	@echo "✅ Vault populado com sucesso!"

# ==============================================================================
# AUTENTICAÇÃO (O fluxo do JWT)
# ==============================================================================
auth-register: ## Registra o usuário administrador inicial
	@echo "👤 Registrando: $(ADMIN_USER)..."
	@curl -s -X POST $(API_URL)/auth/register \
		-H "Content-Type: application/json" \
		-d '{"username":"$(ADMIN_USER)", "password":"$(ADMIN_PASS)", "email":"$(ADMIN_EMAIL)", "role":"admin"}'
	@echo "\n✅ Registro finalizado."

auth-login: ## Faz login e extrai o JWT puro para o arquivo .token
	@echo "🔑 Fazendo login..."
	@curl -s -X POST $(API_URL)/auth/login \
		-H "Content-Type: application/json" \
		-d '{"username":"$(ADMIN_USER)", "password":"$(ADMIN_PASS)"}' > .token_raw.json
	@cat .token_raw.json | sed -n 's/.*"token":"\([^"]*\)".*/\1/p' > .token
	@echo "🎫 JWT extraído e salvo no arquivo .token"

# ==============================================================================
# REPOSITÓRIOS & STORAGE
# ==============================================================================
create-repo: ## Cria o repositório npm-proxy usando o token JWT
	@if [ ! -f .token ]; then echo "❌ Erro: Cadê o token? Roda 'make auth-login' primeiro, cria!"; exit 1; fi
	@echo "🏗️  Criando repositório: npm-proxy..."
	@curl -s -X POST $(REPO_URL) \
		-H "Authorization: Bearer $$(cat .token)" \
		-H "Content-Type: application/json" \
		-d $(REPO_DATA)
	@echo "\n✅ Repositório pronto para cachear pacotes!"

setup-s3: ## Garante que o bucket do MinIO existe
	@echo "📥 Configurando bucket S3..."
	@AWS_ACCESS_KEY_ID=$(SILO_ACCESS_KEY) AWS_SECRET_ACCESS_KEY=$(SILO_SECRET_KEY) \
	aws --endpoint-url=http://$(SILO_HOST):$(SILO_PORT_API) s3 mb s3://$(BUCKET_NAME) 2>/dev/null || echo "✅ Bucket já existe."

# ==============================================================================
# COMANDOS DE EXECUÇÃO
# ==============================================================================
dev: ## Roda o servidor Dart com hot reload
	env $$(cat .env | xargs) dart --observe bin/server.dart

setup-all: db-init vault-seed auth-register auth-login create-repo setup-s3 ## Setup COMPLETO do ambiente
	@echo "🚀 SAMBURÁ ESTÁ PRONTO PRO COMBATE, CRIA!"

check: ## Testa a resolução de um pacote (express)
	@echo "🔍 Testando resolução de artefato..."
	curl -i -X GET $(API_URL)/npm-proxy/express/4.18.2