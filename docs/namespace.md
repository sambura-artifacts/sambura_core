# Documentação Técnica: Namespace no Ecossistema de Artefatos

Em um repositório de artefatos multilinguagem, o **Namespace** é a estrutura fundamental que organiza e isola as dependências de diferentes ecossistemas (Docker, NPM, Maven, Pub, etc.) dentro de uma mesma instância do Samburá.

## Definição

O Namespace atua como o **Agrupador de Contexto**. Ele define a origem, o formato e a visibilidade de uma dependência. Sua função é garantir que o gerenciador de pacotes de cada linguagem consiga localizar e resolver versões sem ambiguidades.

### Exemplo de Estrutura por Linguagem:

* **NPM:** O Namespace mapeia para o `@scope` (ex: `@sambura/core-ui`).
* **Maven/Gradle:** O Namespace mapeia para o `groupId` (ex: `com.sambura.api`).
* **Docker:** O Namespace mapeia para o nome da organização ou projeto (ex: `sambura/base-images`).
* **Pub (Dart):** Mapeia para o prefixo do pacote no servidor privado.

---

## Hierarquia Lógica e Separação de Preocupações

Para gerenciar múltiplas linguagens, o Namespace deve seguir uma convenção que identifique o **Ecossistema** + **Proprietário**.

**Convenção sugerida:** `{ecossistema}.{projeto-ou-time}.{escopo}`

| Namespace | Exemplo de Artefato | Uso Pretendido |
| --- | --- | --- |
| `docker.infra.proxy` | `nginx-custom:1.21` | Imagens de infraestrutura. |
| `npm.frontend.shared` | `design-system-v2.tgz` | Pacotes de interface. |
| `maven.backend.billing` | `payment-gateway-1.0.jar` | Binários Java/Kotlin. |
| `generic.bin.raw` | `firmware-v5.bin` | Arquivos binários brutos. |

---

## Benefícios da Abstração por Namespace

### A. Resolução de Conflitos (Collision Avoidance)

Diferentes linguagens podem utilizar convenções de nomes similares. O isolamento por Namespace garante que um pacote Python chamado `requests` não interfira em uma pasta de scripts genéricos com o mesmo nome.

### B. Políticas de Retenção Diferenciadas

O sistema pode aplicar regras automáticas baseadas no Namespace:

* **Namespace `docker.***`**: Manter apenas as últimas 10 versões (devido ao alto consumo de disco).
* **Namespace `maven.***`**: Nunca deletar versões (garantia de rastreabilidade de releases).

### C. Integração com CI/CD

Pipelines de integração contínua utilizam o Namespace para determinar o destino correto do comando de `publish` ou `push`, abstraindo a complexidade do storage físico.

---

## Comportamento do Storage (Deduplicação Global)

Apesar do isolamento lógico via Namespace para facilitar a gestão das linguagens, a camada de **Blob Storage** permanece global.

> **Cenário:** Se um `layer` de uma imagem Docker for idêntico a um arquivo binário dentro de um pacote NPM, o Samburá armazenará apenas **uma cópia** física no Silo, embora ambos os Namespaces possuam metadados apontando para esse conteúdo.

---
