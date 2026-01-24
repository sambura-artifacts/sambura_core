-- =============================================================================
-- 🌊 SAMBURÁ CORE - DATABASE INITIALIZATION
-- Escopo: Gestão de Metadados, Armazenamento Dedupulado e Identidade.
-- Versão: 1.0 (2025)
-- =============================================================================

-- Habilita extensão para geração de UUIDs se necessário (opcional para UUID v7)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- -----------------------------------------------------------------------------
-- 1. BLOBS (Camada de Armazenamento Físico)
-- -----------------------------------------------------------------------------
-- Objetivo: Garantir a Deduplicação Global. 
-- Se 1000 pacotes NPM usarem a mesma versão da lib 'lodash', o conteúdo físico
-- é armazenado apenas uma vez, referenciado pelo hash do seu conteúdo.
CREATE TABLE IF NOT EXISTS blobs (
    id SERIAL PRIMARY KEY,
    hash TEXT UNIQUE NOT NULL,      -- SHA-256: Identificador único do conteúdo (CAS)
    size_bytes BIGINT NOT NULL,     -- Tamanho real para cálculo de quota/storage
    mime_type TEXT,                 -- ex: 'application/gzip' ou 'application/octet-stream'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- 2. REPOSITORIES (Camada de Configuração/Escopo)
-- -----------------------------------------------------------------------------
-- Objetivo: Isolar ambientes e comportamentos.
-- Um repositório define a 'casa' dos pacotes (ex: npm, pub, maven).
CREATE TABLE IF NOT EXISTS repositories (
    id SERIAL PRIMARY KEY,
    name TEXT UNIQUE NOT NULL,       -- ex: 'npm-proxy', 'dart-internal'
    namespace TEXT NOT NULL,         -- ex: 'npm', 'pub', 'docker'
    is_public BOOLEAN DEFAULT false, -- Indica se aceita requisições sem auth ou se é Proxy
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- 3. PACKAGES (Camada de Catálogo/Projeto)
-- -----------------------------------------------------------------------------
-- Objetivo: Agrupar versões de um mesmo software.
-- O pacote 'express' pertence a um repositório específico.
CREATE TABLE IF NOT EXISTS packages (
    id SERIAL PRIMARY KEY,
    repository_id INTEGER NOT NULL REFERENCES repositories(id) ON DELETE CASCADE,
    name TEXT NOT NULL,              -- ex: 'express', 'dio', 'shelf'
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT unique_package_per_repo UNIQUE(repository_id, name)
);

-- -----------------------------------------------------------------------------
-- 4. ARTIFACTS (Camada de Versão/Release)
-- -----------------------------------------------------------------------------
-- Objetivo: Ligar um nome/versão amigável a um Blob físico.
-- É aqui que o usuário 'baixa' o arquivo. O artifact é o 'ponteiro' para o conteúdo.
CREATE TABLE IF NOT EXISTS artifacts (
    id SERIAL PRIMARY KEY,
    external_id UUID UNIQUE NOT NULL, -- ID público (UUID) para evitar exposição de IDs sequenciais na API
    package_id INTEGER NOT NULL REFERENCES packages(id) ON DELETE CASCADE,
    version TEXT NOT NULL,            -- Semântica de versão (ex: '1.0.0', '4.18.2')
    path TEXT NOT NULL,               -- Nome final do arquivo (ex: 'express-4.18.2.tgz')
    blob_id INTEGER NOT NULL REFERENCES blobs(id), -- FK para o conteúdo real no storage
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT unique_version_per_package UNIQUE(package_id, version)
);

-- -----------------------------------------------------------------------------
-- 5. ACCOUNTS (Gestão de Identidade)
-- -----------------------------------------------------------------------------
-- Objetivo: Armazenar credenciais e permissões.
-- Parte vital do monólito que futuramente será desacoplada para um Auth Service.
CREATE TABLE IF NOT EXISTS accounts (
    id SERIAL PRIMARY KEY,
    external_id UUID UNIQUE NOT NULL, -- UUID para uso em JWT e APIs externas
    username TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,     -- Senha com hash + pepper (vindo do Vault)
    email TEXT UNIQUE NOT NULL,
    role TEXT NOT NULL DEFAULT 'developer', -- ex: 'admin', 'developer', 'ci_cd'
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- 6. API KEYS (Autenticação Programática)
-- -----------------------------------------------------------------------------
-- Objetivo: Permitir que máquinas (CI/CD) publiquem ou baixem artefatos.
-- Armazenamos apenas o hash da chave para segurança máxima.
CREATE TABLE IF NOT EXISTS api_keys (
    id SERIAL PRIMARY KEY,
    account_id INTEGER NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    name TEXT NOT NULL,               -- Nome amigável (ex: 'Jenkins Deploy Key')
    key_hash TEXT UNIQUE NOT NULL,    -- Hash da chave para validação
    prefix TEXT NOT NULL,             -- Primeiros caracteres da chave para identificação visual
    last_used_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- 7. ÍNDICES (Otimização de Performance)
-- -----------------------------------------------------------------------------
-- Buscas por UUID (comum em APIs REST)
CREATE INDEX IF NOT EXISTS idx_artifacts_external_id ON artifacts(external_id);
CREATE INDEX IF NOT EXISTS idx_accounts_external_id ON accounts(external_id);

-- Buscas de pacotes e versões (hot path das ferramentas de package manager)
CREATE INDEX IF NOT EXISTS idx_artifacts_package_lookup ON artifacts(package_id, version);
CREATE INDEX IF NOT EXISTS idx_packages_repo_name ON packages(repository_id, name);

-- Performance em joins de download (Blob -> Artifact)
CREATE INDEX IF NOT EXISTS idx_artifacts_blob_id ON artifacts(blob_id);

-- Performance em Autenticação
CREATE INDEX IF NOT EXISTS idx_accounts_username ON accounts(username);
CREATE INDEX IF NOT EXISTS idx_api_keys_hash ON api_keys(key_hash);

-- -----------------------------------------------------------------------------
-- 8. SEEDS (Dados Iniciais)
-- -----------------------------------------------------------------------------

-- 8.1 Repositório Proxy (Mundo Externo)
-- Nome: npm-proxy | Namespace: npm | Público: true
INSERT INTO repositories (name, namespace, is_public) 
VALUES ('npm-proxy', 'npm', true)
ON CONFLICT (name) DO NOTHING;

-- 8.2 Repositório Hosted (Interno da Empresa)
-- Nome: npm-internal | Namespace: npm | Público: false
INSERT INTO repositories (name, namespace, is_public) 
VALUES ('npm-internal', 'npm', false)
ON CONFLICT (name) DO NOTHING;

-- 8.3 Repositório Dart/Flutter (Exemplo)
INSERT INTO repositories (name, namespace, is_public) 
VALUES ('sambura-pub', 'pub', false)
ON CONFLICT (name) DO NOTHING;
