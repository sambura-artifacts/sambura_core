# Documentação de Entidade: Artifact (Artefato)

## 1. Conceito
O **Artifact** é a unidade fundamental de metadados. Ele representa a existência de um recurso (arquivo ou pacote) dentro de um contexto específico. É a ponte lógica entre a organização do usuário (**Namespace**) e o conteúdo físico (**Blob**).

## 2. Anatomia da Entidade
* **id:** Identificador sequencial interno (`int`).
* **externalId (ExternalId VO):** UUID v7 público e imutável, ordenado por tempo.
* **packageId:** FK para a tabela de pacotes (agrupador).
* **namespace:** Escopo de isolamento (identificador do repositório).
* **packageName (PackageName VO):** Nome validado (ex: `@scope/lib`).
* **version (SemVer VO):** Versão semântica rigorosa (ex: `1.2.3`).
* **path:** Caminho lógico único dentro do namespace.
* **blob:** Referência ao objeto `Blob` (conteúdo físico).

## 3. Regras de Negócio
1. **Imutabilidade:** Uma vez publicado, um artefato (par nome+versão) não deve ser alterado.
2. **Ponteiro Lógico:** O artefato não contém os bytes, apenas "aponta" para um Blob através do Hash.
3. **Validação de Fronteira:** Garante conformidade com o ecossistema (NPM/SemVer) antes de atingir o storage.