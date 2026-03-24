# Documentação de Entidade: Repository (Repositório)

## 1. Conceito
O **Repository** é o nível mais alto de isolamento no Samburá. Ele define o "balde" (bucket) lógico onde os pacotes residem. É através do repositório que se define o acesso e a tecnologia (NPM, Generic, etc).

## 2. Anatomia da Entidade
* **id:** Chave primária interna (`int`).
* **name:** Nome identificador na URL (ex: `prod-repo`).
* **namespace:** Identificador da organização ou dono.
* **type:** Tipo de tecnologia (ex: `npm`, `maven`, `generic`).
* **isPublic:** Booleano que define se o acesso exige autenticação.

## 3. Regras de Negócio
1. **Isolamento de Namespace:** O `namespace` garante que diferentes organizações possam ter repositórios com o mesmo nome sem colisão.
2. **Imutabilidade de Tipo:** Uma vez criado como `npm`, um repositório não pode ser alterado para outro tipo para preservar a integridade dos metadados.