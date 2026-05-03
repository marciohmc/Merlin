# --- Build Stage ---
FROM golang:1.23-bullseye AS builder
WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates p7zip-full jq && \
    rm -rf /var/lib/apt/lists/*

# Versão estável alvo
ENV MERLIN_VERSION="v2.1.4"

# Busca dinâmica do asset correto para v2.1.4
RUN set -x; \
    echo "LOG: Buscando assets para Merlin ${MERLIN_VERSION}..." && \
    # 1. Busca URL via API
    RAW_JSON=$(curl -s https://api.github.com/repos/Ne0nd0g/merlin/releases/tags/${MERLIN_VERSION}) && \
    ASSET_URL=$(echo "$RAW_JSON" | jq -r '.assets[] | select(.name | contains("server") and contains("linux") and (contains("amd64") or contains("x64"))) | .browser_download_url' | head -n 1) && \
    \
    # 2. Fallback se a API falhar ou der rate limit
    if [ -z "$ASSET_URL" ] || [ "$ASSET_URL" = "null" ]; then \
        echo "LOG: Asset nao encontrado via API. Tentando URL direta..."; \
        ASSET_URL="https://github.com/Ne0nd0g/merlin/releases/download/${MERLIN_VERSION}/merlin-server-linux-x64.7z"; \
    fi && \
    \
    # 3. Download com falha explicita (-f para erro 404)
    echo "LOG: Baixando de $ASSET_URL" && \
    curl -L -f -o merlin.7z "$ASSET_URL" || { echo "ERRO: Falha no download (404 ou Rede)"; exit 1; } && \
    \
    # 4. Extracao com verificacao de erro
    echo "LOG: Extraindo binario..." && \
    7z x merlin.7z -pmerlin -y || { echo "ERRO: Falha na extracao (Senha incorreta ou arquivo corrompido)"; exit 1; } && \
    \
    # 5. Localizacao e limpeza
    TARGET_BIN=$(find . -type f -name "merlin-server*" ! -name "*.7z" | head -n 1) && \
    if [ -z "$TARGET_BIN" ]; then \
        echo "ERRO: Binario nao encontrado apos extracao!"; \
        ls -R; exit 1; \
    fi && \
    mv "$TARGET_BIN" merlin-server && \
    chmod +x merlin-server && \
    rm merlin.7z && \
    echo "LOG: Instalação do Merlin ${MERLIN_VERSION} concluída com sucesso."

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
