# --- Build Stage ---
FROM golang:1.23-bullseye AS builder
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates p7zip-full jq && \
    rm -rf /var/lib/apt/lists/*

# Busca dinâmica do asset correto para v2.1.4 para evitar 404
RUN echo "LOG: Buscando assets para Merlin v2.1.4..." && \
    ASSET_URL=$(curl -s https://api.github.com/repos/Ne0nd0g/merlin/releases/tags/v2.1.4 | jq -r '.assets[] | select(.name | contains("server") and contains("linux") and (contains("amd64") or contains("x64"))) | .browser_download_url' | head -n 1) && \
    if [ -z "$ASSET_URL" ] || [ "$ASSET_URL" = "null" ]; then \
        echo "ERRO: Nao foi possivel encontrar o asset do servidor para Linux."; \
        exit 1; \
    fi && \
    echo "LOG: Baixando de $ASSET_URL" && \
    curl -L -o merlin.7z "$ASSET_URL" && \
    echo "LOG: Extraindo binario..." && \
    7z x merlin.7z -pmerlin -y && \
    TARGET_BIN=$(find . -type f -name "merlin-server*" ! -name "*.7z" | head -n 1) && \
    if [ -z "$TARGET_BIN" ]; then echo "ERRO: Binario nao encontrado apos extracao!"; ls -R; exit 1; fi && \
    mv "$TARGET_BIN" merlin-server && \
    chmod +x merlin-server

# --- Final Stage ---
FROM debian:12-slim
WORKDIR /opt/merlin

# Instalar dependências mínimas e Python para o sidecar
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    python3 \
    procps \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/merlin-server .
COPY healthcheck.py .

# Otimização de Memória Go
ENV GOGC=50

# Expor portas (Render mapeia a porta interna PORT para 80/443 externa)
EXPOSE 443 80 8888

# Inicia o Health Check em background e o Merlin em foreground
CMD python3 healthcheck.py & ./merlin-server
