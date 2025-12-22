# Documentação de Entidade: Artifact (Artefato)

## 1. Conceito

O **Artifact** é a unidade fundamental de metadados no Samburá. Ele representa a existência de um recurso (arquivo, pacote ou imagem) dentro de um contexto específico.

Diferente de um arquivo em um sistema de arquivos tradicional, um Artefato no Samburá é uma entidade puramente lógica que faz a ponte entre a organização do usuário (**Namespace**) e o conteúdo físico armazenado (**Blob**).

---

## 2. Anatomia da Entidade

A entidade é composta pelos seguintes atributos:

* **id (Internal ID):** Identificador sequencial (`int`) utilizado exclusivamente para performance de indexação e relacionamentos dentro do banco de dados relacional.
* **externalId (UUID v7):** Identificador público e imutável. Utiliza o padrão **UUID v7** (ordenado por tempo), garantindo performance em inserções e segurança ao expor IDs em APIs externas.
* **Namespace:** Define o escopo de isolamento do artefato. É o identificador do repositório lógico ao qual o arquivo pertence.
* **path:** O caminho relativo e nome do arquivo dentro do seu `namespace`. A combinação de `namespace + path` é única no sistema.
* **blob:** Uma referência ao objeto `Blob`, que contém os metadados sobre o conteúdo (Hash, Tamanho e Tipo).
* **createdAt:** Data e hora de quando o artefato foi registrado no sistema.

---

## 3. Ciclo de Vida e Estados

O `ArtifactEntity` possui três estados de inicialização principais:

### A. Criação (`create`)

Ocorre durante o processo de upload. Nesta fase, a entidade orquestra o processamento do stream de dados para gerar o `Blob`. O `externalId` é gerado automaticamente via UUID v7 e o `id` interno permanece nulo até a persistência.

### B. Recuperação do Repositório (`fromRepository`)

Utilizado pela camada de infraestrutura ao converter resultados brutos de consultas SQL (joins entre tabelas de artefatos e blobs) em objetos de domínio ricos.

### C. Restauração (`restore`)

Utilizado para reconstruir a entidade a partir de estados conhecidos, garantindo a imutabilidade dos dados recuperados.

---

## 4. Comportamento e Regras de Negócio

1. **Imutabilidade Lógica:** Uma vez criado, as propriedades fundamentais de um artefato (como seu Hash e Path) não devem ser alteradas. Caso o conteúdo mude, um novo artefato (ou uma nova versão) deve ser gerado.
2. **Acesso Delegado:** O artefato expõe propriedades do Blob (como `mimeType`, `sizeBytes` e `hashValue`) através de getters de conveniência, mantendo a Lei de Demeter e facilitando o uso pela camada de aplicação.
3. **Desacoplamento de Conteúdo:** Diversos artefatos (em diferentes caminhos ou repositórios) podem apontar para o mesmo Blob. O Artefato é o "ponteiro", o Blob é o "dado".

---

## 5. Implementação Técnica (Resumo)

A entidade utiliza construtores privados e métodos estáticos de fábrica para garantir que nenhuma instância seja criada em estado inválido.

* **Identidade:** A igualdade da entidade é definida pelo seu `externalId`.
* **Geração de Hash:** Delegada inteiramente ao Value Object `Blob` durante o método `create`.

