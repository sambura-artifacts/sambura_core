# ==============================================================================
# SAMBURÁ CORE - Cloud Native Docker Architecture
# ==============================================================================
# * Build Strategy: Multi-stage build para otimização de imagem final.
# * Compilation: Ahead-of-Time (AOT) para redução de overhead e startup rápido.
# * Security: Runtime baseado em 'distroless/base-debian12' para minimizar a
#   superfície de ataque e garantir conformidade com certificados SSL/TLS.
# ==============================================================================

# STAGE 1: Build & Compilation
# ------------------------------------------------------------------------------
FROM dart:stable AS build

WORKDIR /app

# Camada de cache para dependências (evita re-download se o código mudar)
COPY pubspec.* ./
RUN dart pub get

# Copia o código fonte e gera o binário nativo auto-contido
COPY . .
RUN dart compile exe bin/server.dart -o bin/server

# STAGE 2: High Performance Runtime
# ------------------------------------------------------------------------------
# Usamos distroless para garantir que apenas o binário e bibliotecas 
# essenciais existam na imagem final, removendo shells e pacotes desnecessários.
FROM gcr.io/distroless/base-debian12

# Copia o runtime nativo do Dart do estágio de build
COPY --from=build /runtime/ /

# Copia o binário compilado para o bin do sistema de arquivos
COPY --from=build /app/bin/server /app/bin/

# COPIA OS ASSETS (Especificações OpenAPI/Swagger UI)
# Necessário para que o ApiRouter sirva a documentação corretamente.
COPY --from=build /app/specs /app/specs

# Configurações de Rede
EXPOSE 8080

# Execução do Entrypoint
CMD ["/app/bin/server"]