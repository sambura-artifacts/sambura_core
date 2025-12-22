> Esta documentação detalha a entidade **Blob**, o componente central da estratégia de armazenamento e deduplicação do Samburá.

---

# Documentação de Entidade: Blob (Binary Large Object)

## 1. Conceito

O **Blob** representa o conteúdo binário bruto de um arquivo de forma agnóstica ao contexto.

A identidade de um Blob não é definida por um nome, mas sim pelo seu conteúdo, utilizando a técnica de **Content-Addressable Storage (CAS)**.

---

## 2. Atributos da Entidade

* **id (Internal ID):** Identificador numérico primário utilizado para otimização de chaves estrangeiras (*Foreign Keys*) no banco de dados.
* **hashValue:** O identificador único global do conteúdo, gerado via algoritmo **SHA-256**. O valor é prefixado com o algoritmo utilizado (ex: `sha256:e3b0c442...`), permitindo futura evolução de algoritmos sem quebra de compatibilidade.
* **sizeBytes:** O tamanho exato do arquivo em bytes.
* **mimeType:** A classificação do tipo de mídia (ex: `application/pdf`, `image/png`).

---

## 3. Processamento de Dados (Streaming & Hashing)

A principal responsabilidade do Blob é processar fluxos de dados de forma eficiente através do método `fromStream`.

### A. Processamento "On-the-fly"

O Blob utiliza o padrão de processamento por pedaços (*chunks*). Isso garante que o uso de memória RAM seja constante (O(1)), independentemente do tamanho do arquivo (seja 1KB ou 10GB), pois os bytes são processados e descartados conforme passam pelo stream.

### B. Detecção de Tipo (MIME Detection)

O Blob implementa uma estratégia de detecção em duas camadas:

1. **Extensão:** Analisa o nome do arquivo fornecido.
2. **Magic Numbers:** Inspeciona os primeiros **1024 bytes** (header) do stream para identificar a assinatura real do binário, prevenindo spoofing de extensões (ex: um executável renomeado para `.txt`).

---

## 4. Deduplicação e Integridade

A arquitetura do Blob viabiliza a **Deduplicação Global**:

* Se dois usuários fizerem upload do mesmo arquivo para namespaces diferentes, o sistema detectará que o `hashValue` é idêntico.
* O banco de dados manterá apenas um registro na tabela de `blobs`, enquanto a tabela de `artifacts` terá dois registros apontando para o mesmo `blob_id`.

---

## 5. Métodos de Instanciação

* **`fromStream` / `create`:** Métodos assíncronos que consomem um `Stream<List<int>>` para calcular o hash e o tamanho em tempo real.
* **`restore` / `fromLibrary`:** Métodos de fábrica para reconstruir o objeto a partir de dados persistidos no banco de dados (Infraestrutura).
* **`fromJson` / `toJson`:** Suporte à serialização para transferência entre camadas ou cache.

---

### 💡 Nota Técnica sobre Comparação

Como o Blob estende `Equatable`, a comparação entre dois objetos Blob é baseada em seu conteúdo (`hashValue`, `sizeBytes` e `mimeType`), e não em sua referência de memória. Dois objetos Blob com o mesmo hash são considerados semanticamente iguais.

**Deseja que eu detalhe como o `CreateArtifactUsecase` deve coordenar a persistência do Blob antes de criar o vínculo com o Artifact?** Isso fecharia o entendimento da transação entre essas duas entidades.


Entendido. Para manter a coerência com a sua implementação atual e o esquema de banco de dados que definimos, ajustei a documentação técnica do **Blob**. O foco agora é refletir a estrutura de **IDs incrementais** para performance interna e a lógica de processamento por **Streams**.

---

# Documentação Técnica: Entidade Blob

## 1. Definição Conceitual

O **Blob** (Binary Large Object) é a representação imutável do conteúdo binário no ecossistema Samburá. Ele implementa o conceito de **Content-Addressable Storage (CAS)**, onde a identidade do objeto é derivada do seu próprio conteúdo (Hash) e não de metadados externos.

## 2. Estrutura de Atributos

| Atributo | Tipo | Descrição |
| --- | --- | --- |
| `id` | `int?` | Chave primária sequencial (`SERIAL`) para otimização de relacionamentos no PostgreSQL. |
| `hashValue` | `String` | Identificador único gerado via SHA-256, prefixado pelo algoritmo (ex: `sha256:...`). |
| `sizeBytes` | `int` | Tamanho total do binário em bytes. |
| `mimeType` | `String` | Tipo de mídia detectado (ex: `application/octet-stream`). |

## 3. Mecanismos de Instanciação e Processamento

A entidade utiliza métodos de fábrica para garantir que o processamento binário não sobrecarregue a memória do servidor.

### A. Processamento via Stream (`fromStream`)

O método `fromStream` é o ponto de entrada para novos uploads. Ele processa o `Stream<List<int>>` em "pedaços" (chunks), realizando duas operações simultâneas sem carregar o arquivo completo na RAM:

1. **Hashing:** Alimenta um `AccumulatorSink` com o algoritmo SHA-256.
2. **MIME Sniffing:** Inspeciona os primeiros **1024 bytes** (header) para identificar a assinatura do arquivo através de *Magic Numbers*.

### B. Persistência e Reconstrução

* **`restore`:** Utilizado para instanciar objetos a partir de dados já existentes no banco de dados.
* **`fromJson/toJson`:** Facilita a serialização para comunicação entre camadas ou sistemas de cache (Redis).

## 4. Estratégia de Deduplicação Global

A arquitetura do Blob permite que o Samburá economize espaço em disco de forma agressiva.

1. Antes de salvar um novo binário, o sistema verifica se o `hashValue` já existe na tabela `blobs`.
2. Se existir, o `id` do Blob existente é retornado e vinculado ao novo `Artifact`.
3. O armazenamento físico (Silo) ignora o novo upload, mantendo apenas uma cópia dos bytes para múltiplos artefatos.

## 5. Mapeamento de Persistência (PostgreSQL)

A tabela `blobs` é otimizada para buscas rápidas por Hash e integridade referencial:

```sql
CREATE TABLE IF NOT EXISTS blobs (
    id SERIAL PRIMARY KEY UNIQUE,
    hash TEXT UNIQUE, -- Índice B-Tree automático para deduplicação
    size_bytes BIGINT NOT NULL,
    mime_type TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

```
