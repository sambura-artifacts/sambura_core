# Documentação de Entidade: Account (Conta)

## 1. Conceito
A **Account** representa a identidade de um usuário ou serviço (Bot) dentro do sistema. É a base para o controle de permissões (RBAC).

## 2. Anatomia da Entidade
* **externalId (ExternalId VO):** Identificador público imutável (UUID v7).
* **username (Username VO):** Identificador único para login, sanitizado e lowercase.
* **email (Email VO):** Endereço de email validado e normalizado.
* **password (Password VO):** Contém o hash Bcrypt da credencial.
* **role (Role VO):** Nível de privilégio (Admin, Developer, Viewer).
* **lastLoginAt:** Timestamp da última autenticação bem-sucedida.

## 3. Regras de Segurança
1. **Deduplicação por Normalização:** Emails e Usernames são normalizados para lowercase antes da persistência.
2. **Blindagem de Credencial:** A entidade nunca expõe a senha em texto plano, apenas o seu Hash.