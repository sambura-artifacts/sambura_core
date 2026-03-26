# ==============================================================================
# SAMBURÁ CORE - Makefile de Controle
# ==============================================================================
# Projeto: Registro Privado de Artefatos (NPM, PyPI, Maven, etc.)
# Versão: 1.0.1
# ==============================================================================

# ==============================================================================
# CONFIGURAÇÕES GLOBAIS
# ==============================================================================

# Carrega .env se existir
ifneq ("$(wildcard .env)","")
    include .env
    export $(shell sed 's/=.*//' .env)
endif

# Configurações padrão (podem ser sobrescritas pelo .env)
API_URL ?= http://localhost:8080/api/v1
DB_URL ?= postgres://sambura:sambura_db_secret@localhost:5432/sambura_metadata
BUCKET_NAME ?= sambura-blobs
SILO_HOST ?= localhost
SILO_PORT_API ?= 9000
SILO_ACCESS_KEY ?= sambura_admin
SILO_SECRET_KEY ?= sambura_silo_secret

# Configurações do Vault
VAULT_TOKEN ?= root_token_sambura
VAULT_API_URL ?= http://127.0.0.1:8200/v1/secret/data/sambura/bootstrap

# Configurações de Deploy (K8s/AWS)
AWS_REGION ?= us-east-1
AWS_ACCOUNT_ID ?= $(shell aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "unknown")
ECR_REPO ?= $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com/sambura-core
IMAGE_TAG ?= v1.0.1

# URLs e dados para setup
REPO_URL ?= $(API_URL)/admin/repositories
REPO_DATA ?= '{"name": "npm-registry", "namespace": "npm", "is_public": true, "type": "proxy"}'
API_KEYS_URL ?= $(API_URL)/admin/api-keys

# Flags de debug
DEBUG ?= false

# ==============================================================================
# TARGETS PHONY
# ==============================================================================

.PHONY: help up down dev db-init db-reset db-shell wait-db vault-seed auth-register auth-login create-repo create-apikey setup-s3 env-setup setup-all setup-check check test test-watch test-coverage clean build docker-up docker-build docker-down docker-purge docker-logs docker-logs-full k8s-deploy k8s-clean k8s-status k8s-logs ecr-login ecr-push build-image bootstrap check-deps lint format deps

# ==============================================================================
# HELP & INFO
# ==============================================================================

help: ## Mostra os comandos disponíveis
	@echo "🌊 Samburá Control Center - Comandos Disponíveis:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "📚 Grupos de comandos:"
	@echo "  🔧 Desenvolvimento: dev, test, build, clean, lint, format, deps"
	@echo "  🐳 Infraestrutura: docker-up, docker-down, docker-logs"
	@echo "  🗄️  Banco de dados: db-init, db-reset, db-shell"
	@echo "  🔐 Autenticação: auth-login, create-apikey"
	@echo "  📦 Setup: setup-all, env-setup"
	@echo "  ☁️  Deploy: k8s-deploy, ecr-push"

# ==============================================================================
# INFRAESTRUTURA (Docker)
# ==============================================================================

docker-up: check-deps ## Sobe os containers (Postgres, Redis, Vault, MinIO, RabbitMQ)
	@echo "🚀 Iniciando infraestrutura Docker..."
	@docker compose -f docker/docker-compose.yml up -d
	@echo "⏳ Aguardando containers estabilizarem..."
	@sleep 3
	@echo "✅ Infraestrutura online!"

docker-build: check-deps ## Constrói a aplicação e sobe os containers
	@echo "🔨 Construindo aplicação e infraestrutura..."
	@docker compose -f docker/docker-compose.yml up --build -d --remove-orphans
	@echo "⏳ Aguardando containers estabilizarem..."
	@sleep 3
	@echo "✅ Aplicação construída e infraestrutura online!"


docker-rebuild: check-deps ## Constrói a aplicação e sobe os containers
	@echo "🔨 Construindo aplicação e infraestrutura..."
	@docker compose -f docker/docker-compose.yml up sambura_app --build -d --remove-orphans
	@echo "⏳ Aguardando containers estabilizarem..."
	@sleep 3
	@echo "✅ Aplicação construída e infraestrutura online!"

docker-down: ## Para todos os containers
	@echo "🛑 Parando infraestrutura..."
	@docker compose -f docker/docker-compose.yml down
	@echo "✅ Infraestrutura offline."

docker-purge: ## Para todos os containers e remove volumes
	@echo "🛑 Removendo infraestrutura e volumes..."
	@docker compose -f docker/docker-compose.yml down --volumes
	@rm -rf .apikey .token
	@echo "✅ Infraestrutura removida completamente."

docker-logs: ## Acompanha os logs dos containers
	docker compose -f docker/docker-compose.yml logs 

docker-logs-app: ## Acompanha os logs do container da aplicação
	docker compose -f docker/docker-compose.yml logs -f sambura_app

docker-logs-full: ## Acompanha os logs dos containers
	docker compose -f docker/docker-compose.yml logs -f


# Alias para compatibilidade
up: docker-up
down: docker-down
rebuild: docker-rebuild
log: docker-logs-app
logs: docker-logs-full
purge: docker-purge


# ==============================================================================
# BANCO DE DADOS
# ==============================================================================

wait-db: ## Aguarda o banco estar pronto
	@echo "⏳ Aguardando banco de dados..."
	@for i in {1..30}; do \
		if docker exec sambura_db pg_isready -U sambura -d sambura_metadata >/dev/null 2>&1; then \
			echo "✅ Banco de dados pronto!"; \
			exit 0; \
		fi; \
		echo "  Tentativa $$i/30..."; \
		sleep 2; \
	done; \
	echo "❌ Banco de dados não respondeu em 60 segundos"; \
	exit 1

db-init: wait-db ## Inicializa o banco com schema e dados
	@echo "🏗️  Inicializando banco de dados..."
	@if [ ! -f sql/init.sql ]; then \
		echo "❌ Arquivo sql/init.sql não encontrado"; \
		exit 1; \
	fi
	@docker exec -i sambura_db psql -U sambura -d sambura_metadata < sql/init.sql
	@echo "✅ Banco de dados inicializado com sucesso!"

db-reset: wait-db ## Limpa os dados das tabelas (TRUNCATE)
	@echo "⚠️  Limpando dados do banco..."
	@docker exec -i sambura_db psql -U sambura -d sambura_metadata -c "TRUNCATE TABLE artifacts, packages, repositories, blobs, accounts, api_keys RESTART IDENTITY CASCADE;"
	@echo "✨ Banco de dados limpo!"

db-shell: ## Abre terminal psql no container
	@if ! docker ps | grep -q sambura_db; then \
		echo "❌ Container sambura_db não está rodando. Execute 'make docker-up' primeiro."; \
		exit 1; \
	fi
	@docker exec -it sambura_db psql -U sambura -d sambura_metadata


# ==============================================================================
# AUTENTICAÇÃO
# ==============================================================================


# Configurações do Vault
VAULT_TOKEN = root_token_sambura
VAULT_API_URL = http://127.0.0.1:8200/v1
DEBUG ?= false

auth-login:
	@echo "🔍 Verificando Vault..."
	@if ! curl -m 2 $(VAULT_API_URL)/sys/health >/dev/null; then \
		echo "❌ Vault não está acessível"; \
		exit 1; \
	fi
	@echo "🔐 Extraindo credenciais..."
	@RESPONSE=$$(curl -s -k --header "X-Vault-Token: $(VAULT_TOKEN)" "$(VAULT_API_URL)/secret/data/sambura/bootstrap"); \
	ADMIN_USER=$$(echo "$$RESPONSE" | python3 -c "import json,sys; data=json.load(sys.stdin); print(data.get('data').get('data').get('username'))"); \
	ADMIN_PASS=$$(echo "$$RESPONSE" | python3 -c "import json,sys; data=json.load(sys.stdin);print(data.get('data',{}).get('data',{}).get('password',''))"); \
	if [ "$(DEBUG)" = "true" ]; then echo "🐞 [DEBUG] User: $$ADMIN_USER | Pass length: $${#ADMIN_PASS}"; fi; \
	if [ -z "$$ADMIN_USER" ] || [ -z "$$ADMIN_PASS" ]; then \
		echo "❌ Credenciais não encontradas no Vault. Execute 'make auth-register' primeiro."; \
		exit 1; \
	fi; \
	echo "🔑 Fazendo login como '$$ADMIN_USER'..."; \
	LOGIN_RES=$$(curl -s "$(API_URL)/auth/login" \
		-H "Content-Type: application/json" \
		-d "{\"username\": \"$$ADMIN_USER\", \"password\": \"$$ADMIN_PASS\"}"); \
	if [ "$(DEBUG)" = "true" ]; then echo "🐞 [DEBUG] API Response: $$LOGIN_RES"; fi; \
	TOKEN=$$(echo "$$LOGIN_RES" | python3 -c "import json,sys; data=json.load(sys.stdin); print(data.get('token',''))"); \
	if [ -n "$$TOKEN" ] && [ "$$TOKEN" != "null" ]; then \
		echo "$$TOKEN" > .token; \
		echo "🎫 JWT salvo em .token"; \
	else \
		echo "❌ Falha na autenticação. Response: $$LOGIN_RES"; \
		exit 1; \
	fi


API_KEYS_URL = $(API_URL)/admin/api-keys

create-apikey:
	@if [ ! -f .token ]; then echo "❌ Erro: Rode 'make auth-login' primeiro."; exit 1; fi
	@echo "🔑 Gerando nova API Key..."
	@TOKEN=$$(cat .token); \
	RESPONSE=$$(curl -X POST $(API_KEYS_URL) \
		-H "Authorization: Bearer $$TOKEN" \
		-H "Content-Type: application/json" \
		-d "{\"name\": \"Dev Key $$(date +%Y%m%d)\", \"expires_in_days\": 30}"); \
	echo "$$RESPONSE"; \
	if [ "$(DEBUG)" = "true" ]; then echo "🐞 [DEBUG] API Response: $$RESPONSE"; fi; \
	KEY=$$(echo "$$RESPONSE" | python3 -c "import json,sys; data=json.load(sys.stdin); print(data.get('data',{}).get('api_key','') if isinstance(data, dict) else '')"); \
	if [ -n "$$KEY" ] && [ "$$KEY" != "null" ]; then \
		echo "$$KEY" > .apikey; \
		echo "🎫 API Key salva em .apikey: $$KEY"; \
	else \
		echo "❌ Falha ao extrair a chave. Response: $$RESPONSE"; \
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
dev: check-deps ## Executa o servidor Dart em modo desenvolvimento
	@echo "🚀 Iniciando Samburá em modo desenvolvimento..."
	@dart bin/server.dart

test: ## Roda todos os testes unitários
	@echo "🧪 Rodando testes..."
	@dart test --reporter=expanded --exclude-tags=integration

test-coverage: ## Gera relatório de cobertura de testes LCOV
	@echo "📊 Gerando cobertura..."
	@dart test --coverage=coverage
	@dart pub global run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --packages=.dart_tool/package_config.json --report-on=lib

build: ## Compila o projeto Dart
	@echo "🔨 Compilando projeto Dart..."
	@mkdir -p build
	@dart pub get
	@dart compile exe bin/server.dart -o build/sambura_core
	@echo "✅ Build concluído! Executável em build/sambura_core"

clean: ## Remove artefatos temporários e tokens
	@rm -f .token .token_raw.json
	@rm -rf coverage/ build/
	@echo "🧹 Limpeza concluída."

check-deps: ## Verifica se todas as dependências estão instaladas
	@echo "🔍 Verificando dependências do sistema..."
	@command -v dart >/dev/null 2>&1 || { echo "❌ Dart SDK não encontrado. Instale em: https://dart.dev/get-dart"; exit 1; }
	@echo "  ✅ Dart SDK ($$(dart --version | cut -d' ' -f4))"
	@command -v docker >/dev/null 2>&1 || { echo "❌ Docker não encontrado. Instale em: https://docs.docker.com/get-docker/"; exit 1; }
	@echo "  ✅ Docker ($$(docker --version | cut -d' ' -f3 | cut -d',' -f1))"
	@docker compose version >/dev/null 2>&1 || { echo "❌ Docker Compose não configurado"; exit 1; }
	@echo "  ✅ Docker Compose"
	@command -v curl >/dev/null 2>&1 || { echo "❌ curl não encontrado"; exit 1; }
	@echo "  ✅ curl"
	@command -v python3 >/dev/null 2>&1 || { echo "❌ Python3 não encontrado"; exit 1; }
	@echo "  ✅ Python3"
	@echo "✅ Todas as dependências estão instaladas!"

lint: check-deps ## Executa análise estática de código
	@echo "🔍 Executando análise de código..."
	@dart analyze lib/
	@echo "✅ Análise concluída!"

format: check-deps ## Formata o código Dart
	@echo "🎨 Formatando código..."
	@dart format lib/ test/ bin/
	@echo "✅ Código formatado!"

deps: check-deps ## Instala/Atualiza dependências Dart
	@echo "📦 Instalando dependências..."
	@dart pub get
	@echo "✅ Dependências instaladas!"

env-setup: ## Configura variáveis de ambiente (.env)
	@echo "🔧 Configurando variáveis de ambiente..."
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo "✅ Arquivo .env criado a partir de .env.example"; \
		echo "ℹ️  Edite .env com suas configurações específicas se necessário"; \
	else \
		echo "ℹ️ Arquivo .env já existe"; \
	fi

setup-all: env-setup docker-up build wait-db db-init vault-seed auth-register auth-login create-repo setup-s3 ## Setup completo do ambiente
	@echo "🎉 SAMBURÁ ESTÁ TOTALMENTE CONFIGURADO E PRONTO!"
	@echo ""
	@echo "📋 Próximos passos:"
	@echo "  • API disponível em: $(API_URL)"
	@echo "  • JWT salvo em: .token"
	@echo "  • Teste com: make check"

setup-check: env-setup docker-up build wait-db db-init vault-seed auth-register auth-login create-repo setup-s3 ## Setup completo (alias)
	@echo "🎉 SAMBURÁ ESTÁ TOTALMENTE CONFIGURADO E PRONTO!"

check: ## Testa a resolução de um pacote (express)
	@echo "🔍 Testando resolução de artefato..."
	@if [ ! -f .token ]; then \
		echo "❌ Token não encontrado. Execute 'make auth-login' primeiro."; \
		exit 1; \
	fi
	@curl -s -i -X GET $(API_URL)/npm-proxy/express/4.18.2 \
		-H "Authorization: Bearer $$(cat .token)" | head -1

# ==============================================================================
# DEPLOY (Kubernetes / EKS)
# ==============================================================================

ecr-login: ## Login no Amazon ECR
	@echo "🔐 Fazendo login no ECR..."
	aws ecr get-login-password --region $(AWS_REGION) | docker login --username AWS --password-stdin $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com

build-image: ## Constrói apenas a imagem Docker da aplicação
	@echo "🔨 Construindo imagem Docker..."
	docker build -t sambura-core:latest -f docker/app/Dockerfile .

ecr-push: build-image ecr-login ## Build e Push da imagem para o ECR
	@echo "🚀 Fazendo push da imagem $(ECR_REPO):$(IMAGE_TAG)..."
	docker tag sambura-core:latest $(ECR_REPO):$(IMAGE_TAG)
	docker push $(ECR_REPO):$(IMAGE_TAG)
	@echo "✅ Imagem enviada com sucesso!"

k8s-deploy: ## Aplica todos os manifestos no Kubernetes
	@echo "🏗️  Aplicando manifestos no namespace 'sambura'..."
	kubectl apply -f kubernetes/base-config.yaml
	kubectl apply -f kubernetes/secrets.yaml
	kubectl apply -f kubernetes/redis.yaml
	kubectl apply -f kubernetes/rabbitmq.yaml
	kubectl apply -f kubernetes/deployment.yaml
	kubectl apply -f kubernetes/service.yaml
	kubectl apply -f kubernetes/ingress.yaml
	@echo "🚀 Deploy finalizado! Aguarde o Ingress (ALB) subir."

k8s-status: ## Verifica o status dos recursos no K8s
	@echo "📊 Status dos recursos no namespace 'sambura':"
	@kubectl get all -n sambura
	@echo "\n🌐 Ingress/ALB:"
	@kubectl get ingress -n sambura

k8s-logs: ## Acompanha os logs da aplicação no K8s
	kubectl logs -f -l app=sambura-core -n sambura

k8s-clean: ## Remove todos os recursos do K8s
	@echo "⚠️  Removendo todos os recursos do namespace 'sambura'..."
	@kubectl delete -f kubernetes/ --ignore-not-found=true
	@echo "🧹 Limpeza concluída."

# ==============================================================================
# INFORMAÇÕES & UTILITÁRIOS
# ==============================================================================

info: ## Mostra informações sobre o projeto
	@echo "🌊 Samburá Core - Registro Privado de Artefatos"
	@echo "==============================================="
	@echo "📦 Suporte: NPM, PyPI, Maven, Docker, NuGet"
	@echo "🏗️  Arquitetura: Clean Architecture + Ports & Adapters"
	@echo "🗄️  Banco: PostgreSQL + Redis + MinIO"
	@echo "🔐 Segurança: JWT + API Keys + Vault"
	@echo "📊 Observabilidade: Prometheus + Grafana"
	@echo ""
	@echo "📋 URLs importantes:"
	@echo "  • API: $(API_URL)"
	@echo "  • Vault: http://localhost:8200"
	@echo "  • MinIO Console: http://localhost:9001"
	@echo "  • Grafana: http://localhost:3000"
	@echo ""
	@echo "📚 Documentação:"
	@echo "  • README: docs/README.md"
	@echo "  • Arquitetura: docs/ARCHITECTURE.md"
	@echo "  • API: specs/swagger.yaml"

version: ## Mostra versão do projeto
	@echo "Samburá Core v1.0.1"
