# ==============================================================================
# VARIÁVEIS DE AMBIENTE
# ==============================================================================

# Configurações de Infra
DB_URL=postgres://sambura:sambura_db_secret@localhost:5432/sambura_metadata
BUCKET_NAME=sambura-blobs
SILO_HOST=localhost
SILO_PORT_API=9000
SILO_ACCESS_KEY=sambura_admin
SILO_SECRET_KEY=sambura_silo_secret

# Dados para criação do repositório inicial
REPO_URL=$(API_URL)/admin/repositories
REPO_DATA='{"name": "npm-registry", "namespace": "npm", "is_public": true, "type": "proxy"}'

# Carrega .env se existir
ifneq ("$(wildcard .env)","")
    include .env
    export $(shell sed 's/=.*//' .env)
endif

.PHONY: help up down dev db-init db-reset db-shell vault-seed auth-register auth-login create-repo setup-s3 setup-all check test test-watch test-coverage clean

# ==============================================================================
# HELP & INFO
# ==============================================================================
help: ## Mostra os comandos disponíveis
	@echo "🌊 Samburá Control Center - Comandos Disponíveis:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

# ==============================================================================
# INFRAESTRUTURA (Docker)
# ==============================================================================

docker-up: ## Sobe os containers (Postgres, Redis, Vault, MinIO, RabbitMQ)
	docker compose -f docker/docker-compose.yml up -d
	@echo "🚀 Infraestrutura subindo em background..."

docker-build: ## Constrói a aplicação e sobe os containers (Postgres, Redis, Vault, MinIO, RabbitMQ)
	docker compose -f docker/docker-compose.yml up --build -d --remove-orphans
	@echo "🚀 Aplicação construída e infraestrutura subindo em background..."

docker-down: ## Para todos os containers e remove redes
	docker compose -f docker/docker-compose.yml down
	@echo "🛑 Infraestrutura offline."

docker-purge: ## Para todos os containers e remove redes
	docker compose -f docker/docker-compose.yml down --volumes
	@echo "🛑 Infraestrutura excluída."

docker-logs: ## Acompanha os logs dos containers
	docker compose -f docker/docker-compose.yml logs 

docker-logs-full: ## Acompanha os logs dos containers
	docker compose -f docker/docker-compose.yml logs -f

# ==============================================================================
# BANCO DE DADOS
# ==============================================================================
db-init: ## Cria as tabelas do zero usando o script SQL
	@echo "🏗️  Estruturando o banco de dados..."
	@docker exec -i sambura_db psql -U sambura -d sambura_metadata < sql/init.sql
	@echo "✅ Tabelas criadas com sucesso!"

db-reset: ## Limpa os dados das tabelas (TRUNCATE)
	@echo "⚠️  Limpando dados..."
	@docker exec -i sambura_db psql -U sambura -d sambura_metadata -c "TRUNCATE TABLE artifacts, packages, repositories, blobs, accounts, api_keys RESTART IDENTITY CASCADE;"
	@echo "✨ Banco limpo!"

db-shell: ## Abre o terminal psql dentro do container
	@docker exec -it sambura_db psql -U sambura -d sambura_metadata


# ==============================================================================
# AUTENTICAÇÃO
# ==============================================================================


# Configurações do Vault
VAULT_TOKEN = root_token_sambura
VAULT_API_URL = http://127.0.0.1:8200/v1/secret/data/sambura/bootstrap
DEBUG ?= false

auth-login:
	@echo "🔍 Verificando Vault..."
	@if ! curl -s -m 2 http://127.0.0.1:8200/v1/sys/health > /dev/null; then exit 1; fi
	@echo "🔐 Extraindo credenciais..."
	@RESPONSE=$$(curl -s -k --header "X-Vault-Token: $(VAULT_TOKEN)" $(VAULT_API_URL)); \
	ADMIN_USER=$$(echo $$RESPONSE | jq -r '.data.data.username'); \
	ADMIN_PASS=$$(echo $$RESPONSE | jq -r '.data.data.password'); \
	if [ "$(DEBUG)" = "true" ]; then echo "🐞 [DEBUG] Password length: $${#ADMIN_PASS}"; fi; \
	echo "🔑 Fazendo login como '$$ADMIN_USER'..."; \
	export USER="$$ADMIN_USER"; \
	export PASS="$$ADMIN_PASS"; \
	LOGIN_RES=$$(curl -s -X POST $(API_URL)/auth/login \
		-H "Content-Type: application/json" \
		--data-raw "$$(jq -n --arg u "$$USER" --arg p "$$PASS" '{username: $$u, password: $$p}')"); \
	if [ "$(DEBUG)" = "true" ]; then echo "🐞 [DEBUG] API Response: $$LOGIN_RES"; fi; \
	TOKEN=$$(echo $$LOGIN_RES | jq -r '.token // empty'); \
	if [ -n "$$TOKEN" ]; then \
		echo $$TOKEN > .token; \
		echo "🎫 JWT salvo em .token"; \
	else \
		echo "❌ Falha na autenticação."; \
		exit 1; \
	fi


API_KEYS_URL = http://localhost:8080/api/v1/admin/api-keys

create-apikey:
	@if [ ! -f .token ]; then echo "❌ Erro: Rode 'make auth-login' primeiro."; exit 1; fi
	@echo "🔑 Gerando nova API Key..."
	@TOKEN=$$(cat .token); \
	RESPONSE=$$(curl -s -X POST $(API_KEYS_URL) \
		-H "Authorization: Bearer $$TOKEN" \
		-H "Content-Type: application/json" \
		-d "{\"name\": \"Dev Key $$(date +%Y%m%d)\", \"expires_in_days\": 30}"); \
	if [ "$(DEBUG)" = "true" ]; then echo "🐞 [DEBUG] API Response: $$RESPONSE"; fi; \
	KEY=$$(echo "$$RESPONSE" | jq -r '.data.api_key // empty'); \
	if [ -n "$$KEY" ] && [ "$$KEY" != "null" ]; then \
		echo "$$KEY" > .apikey; \
		echo "🎫 API Key salva em .apikey: $$KEY"; \
	else \
		echo "❌ Falha ao extrair a chave. Verifique o formato do JSON no modo DEBUG."; \
		exit 1; \
	fi

# ==============================================================================
# REPOSITÓRIOS & STORAGE
# ==============================================================================
create-repo: ## Cria o repositório npm-proxy usando o token JWT
	@if [ ! -f .token ]; then echo "❌ Erro: Cadê o token? Roda 'make auth-login' primeiro!"; exit 1; fi
	@echo "🏗️  Criando repositório: npm-proxy..."
	@curl -s -X POST $(REPO_URL) \
		-H "Authorization: Bearer $$(cat .token)" \
		-H "Content-Type: application/json" \
		-d $(REPO_DATA)
	@echo "\n✅ Repositório pronto para cachear pacotes!"

setup-s3: ## Garante que o bucket do MinIO existe
	@echo "📥 Configurando bucket S3 via Docker..."
	@docker run --rm -e AWS_ACCESS_KEY_ID=$(SILO_ACCESS_KEY) -e AWS_SECRET_ACCESS_KEY=$(SILO_SECRET_KEY) amazon/aws-cli --endpoint-url=http://host.docker.internal:9000 s3 mb s3://$(BUCKET_NAME) 2>/dev/null || echo "✅ Bucket já existe."

# ==============================================================================
# COMANDOS DE EXECUÇÃO & TESTES
# ==============================================================================
dev: ## Roda o servidor Dart com hot reload
	@clear
	@echo "🚀 SAMBURÁ em ambiente local!"
	@dart bin/server.dart

test: ## Roda todos os testes unitários
	@mkdir -p /tmp/app/logs
	@echo "🧪 Rodando testes..."
	@dart test --reporter=expanded --exclude-tags=integration --chain-stack-traces

test-coverage: ## Gera relatório de cobertura de testes LCOV
	@echo "📊 Gerando cobertura..."
	@dart test --coverage=coverage
	@dart pub global run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --packages=.dart_tool/package_config.json --report-on=lib

clean: ## Remove artefatos temporários e tokens
	@rm -f .token .token_raw.json
	@rm -rf coverage/
	@echo "🧹 Limpeza concluída."

setup-all: up db-init vault-seed auth-register auth-login create-repo setup-s3 ## Setup COMPLETO do ambiente
	@echo "🚀 SAMBURÁ ESTÁ PRONTO PRO COMBATE, CRIA!"

setup-check: db-init vault-seed auth-register auth-login create-repo setup-s3 ## Setup COMPLETO do ambiente
	@echo "🚀 SAMBURÁ ESTÁ PRONTO PRO COMBATE, CRIA!"

check: ## Testa a resolução de um pacote (express)
	@echo "🔍 Testando resolução de artefato..."
	curl -i -X GET $(API_URL)/npm-proxy/express/4.18.2