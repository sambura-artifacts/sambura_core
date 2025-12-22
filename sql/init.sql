-- 1. BLOBS (Camada de Armazenamento Físico)
-- Responsável pela deduplicação global. O conteúdo é único em todo o sistema.
CREATE TABLE IF NOT EXISTS blobs (
    id SERIAL PRIMARY KEY,
    hash TEXT UNIQUE NOT NULL, -- SHA-256:Identificador único do conteúdo
    size_bytes BIGINT NOT NULL,
    mime_type TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. REPOSITORIES (Camada de Configuração/Escopo)
-- Define se o repositório é interno (Hosted) ou um cache do mundo externo (Proxy).
CREATE TABLE IF NOT EXISTS repositories (
    id SERIAL PRIMARY KEY,
    name TEXT UNIQUE NOT NULL,       -- ex: 'npm-internal', 'maven-public-cache'
    namespace TEXT NOT NULL,         -- ex: 'npm', 'maven', 'docker', 'pub'
    is_public BOOLEAN DEFAULT false, -- false = Interno/Privado, true = Proxy/Público
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. PACKAGES (Camada de Catálogo/Projeto)
-- Agrupa as versões. Ex: O pacote "express" dentro do repo "npm-internal".
CREATE TABLE IF NOT EXISTS packages (
    id SERIAL PRIMARY KEY,
    repository_id INTEGER NOT NULL REFERENCES repositories(id) ON DELETE CASCADE,
    name TEXT NOT NULL,              -- ex: 'express', 'react', 'my-internal-lib'
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT unique_package_per_repo UNIQUE(repository_id, name)
);

-- 4. ARTIFACTS (Camada de Versão/Release)
-- É a instância real de uma versão apontando para um conteúdo físico.
CREATE TABLE IF NOT EXISTS artifacts (
    id SERIAL PRIMARY KEY,
    external_id UUID UNIQUE NOT NULL, -- ID público (UUID v7) para a API
    package_id INTEGER NOT NULL REFERENCES packages(id) ON DELETE CASCADE,
    version TEXT NOT NULL,            -- ex: '1.0.0', '4.18.2', 'latest'
    path TEXT NOT NULL,               -- Caminho do arquivo (ex: 'express-4.18.2.tgz')
    blob_id INTEGER NOT NULL REFERENCES blobs(id), -- FK para o conteúdo real
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    -- Garante que uma versão seja única dentro de um pacote
    CONSTRAINT unique_version_per_package UNIQUE(package_id, version)
);

-- 5. ÍNDICES (Camada de Performance)
-- Busca rápida por ID externo (padrão em sistemas distribuídos)
CREATE INDEX IF NOT EXISTS idx_artifacts_external_id ON artifacts(external_id);

-- Busca rápida de versões de um pacote específico
CREATE INDEX IF NOT EXISTS idx_artifacts_package_version ON artifacts(package_id, version);

-- Busca de pacotes por namespace (ex: todos os pacotes npm)
CREATE INDEX IF NOT EXISTS idx_repositories_namespace ON repositories(namespace);

-- Acelera o JOIN entre artefatos e blobs para downloads
CREATE INDEX IF NOT EXISTS idx_artifacts_blob_id ON artifacts(blob_id);