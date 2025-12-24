# Documentação de Entidade: Package (Pacote)

## 1. Conceito
O **Package** representa o agrupamento de metadados de um componente. Ele é a ponte entre o Repositório e as diversas versões (Artefatos).

## 2. Anatomia da Entidade
* **id:** Identificador sequencial interno.
* **name (PackageName VO):** Nome único do pacote (ex: `@sambura/core`), validado para conformidade com ecossistemas externos.
* **repositoryId:** Chave estrangeira para o Repositório pai.
* **description:** Texto descritivo opcional.
* **latestVersion (SemVer VO):** Cache da versão estável mais recente.

## 3. Regras de Negócio
1. **Unicidade de Nome:** O par `repositoryId + name` deve ser único.
2. **Integridade de Versão:** O campo `latestVersion` é atualizado automaticamente a cada novo `Artifact` publicado que possua uma versão superior à atual.