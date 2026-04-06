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

-- ---------------------------------------------------------------------------
-- 2. PACKAGE MANAGERS (Maven, NPM, Nuget, etc...)
-- ---------------------------------------------------------------------------
-- Objetivo: Garantir isolamento de pacotes por repositórios
-- Criando granularidade nos bloqueios de pacotes
CREATE TABLE IF NOT EXISTS package_manager (
    id SERIAL PRIMARY KEY,
    slug VARCHAR(20) UNIQUE NOT NULL, -- 'npm', 'maven', 'pypi'
    name VARCHAR(50) NOT NULL,        -- 'Node Package Manager', 'Apache Maven'
    description TEXT,
    icon_url TEXT,                    -- Útil para Dashboard
    default_upstream TEXT,            -- ex: 'https://registry.npmjs.org/'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- 3. NAMESPACES (Camada de Configuração/Escopo)
-- -----------------------------------------------------------------------------
-- Objetivo: Isolar ambientes e comportamentos.
-- Um repositório define a 'casa' dos pacotes (ex: npm, pub, maven).
CREATE TABLE IF NOT EXISTS namespaces (
    id SERIAL PRIMARY KEY,
    package_manager_id INTEGER NOT NULL REFERENCES package_manager(id),
    name TEXT UNIQUE NOT NULL,       -- ex: 'npm-proxy', 'dart-internal'
    escope VARCHAR(30) NOT NULL,
    is_public BOOLEAN DEFAULT false, -- Indica se aceita requisições sem auth ou se é Proxy
    remote_url TEXT,                 -- URL remota para proxy (opcional)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- 4. PACKAGES (Camada de Catálogo/Projeto)
-- -----------------------------------------------------------------------------
-- Objetivo: Agrupar versões de um mesmo software.
-- O pacote 'express' pertence a um repositório específico.
CREATE TABLE IF NOT EXISTS packages (
    id SERIAL PRIMARY KEY,
    namespace_id INTEGER NOT NULL REFERENCES namespaces(id) ON DELETE CASCADE,
    name TEXT NOT NULL,              -- ex: 'express', 'dio', 'shelf'
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT unique_package_per_repo UNIQUE(namespace_id, name)
);

-- -----------------------------------------------------------------------------
-- 5. ARTIFACTS (Camada de Versão/Release)
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
-- 6. ACCOUNTS (Gestão de Identidade)
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
-- 7. API KEYS (Autenticação Programática)
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
-- 8. ÍNDICES (Otimização de Performance)
-- -----------------------------------------------------------------------------
-- Buscas por UUID (comum em APIs REST)
CREATE INDEX IF NOT EXISTS idx_artifacts_external_id ON artifacts(external_id);
CREATE INDEX IF NOT EXISTS idx_accounts_external_id ON accounts(external_id);

-- Buscas de pacotes e versões (hot path das ferramentas de package manager)
CREATE INDEX IF NOT EXISTS idx_artifacts_package_lookup ON artifacts(package_id, version);
CREATE INDEX IF NOT EXISTS idx_packages_namespace_name ON packages(namespace_id, name);
CREATE INDEX IF NOT EXISTS idx_namespaces_pm_id ON namespaces(package_manager_id);

-- Performance em joins de download (Blob -> Artifact)
CREATE INDEX IF NOT EXISTS idx_artifacts_blob_id ON artifacts(blob_id);

-- Performance em Autenticação
CREATE INDEX IF NOT EXISTS idx_accounts_username ON accounts(username);
CREATE INDEX IF NOT EXISTS idx_api_keys_hash ON api_keys(key_hash);

-- -----------------------------------------------------------------------------
-- 9. SEEDS (Dados Iniciais)
-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------
-- 9. SEEDS (Dados Iniciais)
-- -----------------------------------------------------------------------------

-- 9.0 Populando os Package Managers (Obrigatório para as Foreign Keys)
INSERT INTO package_manager (id, slug, name, default_upstream) VALUES 
(1, 'npm', 'Node Package Manager', 'https://registry.npmjs.org/'),
(2, 'maven', 'Apache Maven', 'https://repo.maven.apache.org/maven2/'),
(3, 'generic', 'Generic Storage', NULL)
ON CONFLICT (id) DO NOTHING;
-- ATENÇÃO: Se usar o Postgres 10+, é melhor resetar a sequência do ID após forçar a inserção
SELECT setval('package_manager_id_seq', (SELECT MAX(id) FROM package_manager));

-- 9.1 Repositório Proxy (Mundo Externo)
-- Nome: public | Namespace: npm | Público: true
-- Agora o ID 1 (npm) existe e a Foreign Key vai passar!
INSERT INTO namespaces (package_manager_id, name, escope, is_public, remote_url) 
VALUES (1, 'npm-public', 'npm', true, 'https://registry.npmjs.org/')
ON CONFLICT (name) DO NOTHING;

------------------------------------------------------------------------------
-- Fim da Inicialização do Banco de Dados
-- Este script deve ser idempotente e pode ser executado múltiplas vezes sem causar erros.
-- Ele estabelece a estrutura fundamental para o funcionamento do Samburá Core.
-- =============================================================================
