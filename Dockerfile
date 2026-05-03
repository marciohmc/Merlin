# --- Build Stage ---
FROM golang:1.23-bullseye AS builder
WORKDIR /app

# Versão estável alvo
ENV MERLIN_VERSION="v2.1.4"

RUN set -xe; \
    # 1. Garante que as ferramentas existam
    apt-get update && apt-get install -y --no-install-recommends \
    curl jq p7zip-full ca-certificates findutils && \
    \
    echo "LOG: Buscando Merlin ${MERLIN_VERSION}..." && \
    RAW_JSON=$(curl -s https://api.github.com/repos/Ne0nd0g/merlin/releases/tags/${MERLIN_VERSION}) && \
    ASSET_URL=$(echo "$RAW_JSON" | jq -r '.assets[] | select(.name | contains("server") and contains("linux") and (contains("amd64") or contains("x64"))) | .browser_download_url' | head -n 1) && \
    \
    if [ -z "$ASSET_URL" ] || [ "$ASSET_URL" = "null" ]; then \
        echo "LOG: Usando URL estática como fallback..."; \
        ASSET_URL="https://github.com/Ne0nd0g/merlin/releases/download/${MERLIN_VERSION}/merlin-server-linux-x64.7z"; \
    fi; \
    \
    curl -L -f -o merlin.7z "$ASSET_URL" && \
    \
    echo "LOG: Extraindo..." && \
    7z x merlin.7z -pmerlin -y && \
    \
    # Busca o binário em qualquer subdiretório e move para a raiz atual
    TARGET_BIN=$(find . -executable -type f -name "merlin-server*" ! -name "*.7z" | head -n 1) && \
    if [ -z "$TARGET_BIN" ]; then \
        echo "ERRO: Binário não encontrado. Conteúdo do diretório:"; \
        ls -R; exit 1; \
    fi; \
    \
    mv "$TARGET_BIN" ./merlin-server && \
    chmod +x ./merlin-server && \
    rm merlin.7z && \
    echo "LOG: Sucesso na instalação do Merlin ${MERLIN_VERSION}!"

# --- Final Stage ---
FROM debian:12-slim
WORKDIR /opt/merlin

# Instalar dependências básicas e Python para o sidecar
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    python3 \
    procps \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copiar do builder
COPY --from=builder /app/merlin-server .
COPY healthcheck.py .

# Otimização de Memória Go
ENV GOGC=50

# O Render exige que o processo principal respeite a porta definida em $PORT.
# Nossa estratégia aqui é rodar o healthcheck.py em background para satisfazer o Render,
# enquanto o Merlin roda como o motor real.
EXPOSE 443 80 8888

# Inicia o Health Check e o Merlin
CMD python3 healthcheck.py & ./merlin-server
