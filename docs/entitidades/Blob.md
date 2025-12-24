# Documentação de Entidade: Blob (Binary Large Object)

## 1. Conceito
O **Blob** representa o conteúdo binário bruto. Sua identidade é definida pelo conteúdo (**Content-Addressable Storage**), garantindo que arquivos idênticos ocupem apenas um espaço físico, independente de quantos artefatos apontem para eles.

## 2. Atributos da Entidade
* **id:** Chave primária sequencial para performance de JOINs.
* **hashValue:** Identificador único gerado via SHA-256 (ex: `sha256:e3b0c4...`).
* **sizeBytes:** Tamanho exato do arquivo em bytes.
* **mimeType:** Classificação do tipo de mídia detectada via *Magic Numbers*.

## 3. Processamento e Integridade
1. **Streaming:** Processado em chunks (O(1) em memória) via `fromStream`.
2. **Deduplicação Global:** Antes de salvar, o sistema verifica a existência do Hash. Se encontrado, reutiliza o ID existente.
3. **MIME Sniffing:** Inspeciona os primeiros 1024 bytes para evitar spoofing de extensão de arquivo.

## 4. Persistência
* O registro do banco (metadado) e o arquivo físico (silo) devem estar sempre sincronizados via Hash.