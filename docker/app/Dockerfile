# ==============================================================================
# Multi-Stage Build para Samburá Core
# ==============================================================================
# Stage 1: Build
FROM dart:stable AS build

LABEL maintainer="Samburá Team <dev@sambura.io>"
LABEL description="Samburá Core - Universal Package Registry"

WORKDIR /app

# Copia arquivos de dependências
COPY pubspec.yaml pubspec.lock ./

# Instala dependências
RUN dart pub get

# Copia código fonte
COPY . .

# Compila a aplicação (AOT)
RUN dart --target-os=linux --target-arch=x64 compile exe bin/server.dart -o bin/server

# ==============================================================================
# Stage 2: Runtime
FROM debian:bookworm-slim

# Instala dependências runtime mínimas
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Cria usuário não-root
RUN useradd -r -u 1001 -m -s /bin/bash sambura

WORKDIR /app

# Copia binário compilado do stage anterior
COPY --from=build /app/bin/server /app/server

COPY specs/ ./specs/

# Cria diretório de logs
RUN mkdir -p /app/logs && chown -R sambura:sambura /app/logs


# Muda para usuário não-root
USER sambura


# Expõe porta
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:8080/health/liveness || exit 1

# Comando de inicialização
ENTRYPOINT ["/app/server"]
