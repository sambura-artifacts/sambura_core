-- ==================================================================
-- Script de inicialização do banco de dados para Dependency Track
-- Este script deve ser executado para criar o banco de dados, tabelas, índices e dados iniciais necessários para o funcionamento do Samburá Core.
-- ==================================================================
-- 1. Cria o usuário (role) do banco de dados
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'dtrack_user') THEN
        CREATE ROLE dtrack_user WITH LOGIN PASSWORD 'dtrack_password';
    END IF;
END
$$;

-- 2. Cria o banco de dados
-- Nota: CREATE DATABASE não pode ser executado dentro de blocos DO, 
-- então usamos este truque de shell ou simplesmente deixamos o comando puro:
SELECT 'CREATE DATABASE dtrack_db'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'dtrack_db')\gexec

-- 3. Conecta e ajusta permissões
\c dtrack_db

GRANT ALL PRIVILEGES ON DATABASE dtrack_db TO dtrack_user;
GRANT ALL ON SCHEMA public TO dtrack_user;
GRANT ALL PRIVILEGES ON SCHEMA public TO dtrack_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO dtrack_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO dtrack_user;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO dtrack_user;

-- ==============================================================================
-- Este script deve ser idempotente, ou seja, pode ser executado múltiplas vezes sem causar erros.
-- Ele estabelece a estrutura fundamental para o funcionamento do Samburá Core.
-- ==============================================================================