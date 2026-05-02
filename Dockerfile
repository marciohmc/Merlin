# --- Build Stage ---
FROM golang:1.23-bullseye AS builder

WORKDIR /app

# Instalar dependências necessárias para download e extração (7z é necessário para versões recentes)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    p7zip-full \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Obter a versão mais recente e baixar o asset .7z correto para Linux amd64
RUN LATEST_JSON=$(curl -s https://api.github.com/repos/Ne0nd0g/merlin/releases/latest) && \
    echo "LOG: Consultando versao via GitHub API..." && \
    LATEST_TAG=$(echo "$LATEST_JSON" | jq -r '.tag_name // "v2.1.4"') && \
    DOWNLOAD_URL=$(echo "$LATEST_JSON" | jq -r '.assets[]? | select(.name | contains("server-linux-amd64.7z")) | .browser_download_url' | head -n 1) && \
    if [ -z "$DOWNLOAD_URL" ] || [ "$DOWNLOAD_URL" = "null" ]; then \
        echo "LOG: Usando fallback de URL direto..."; \
        DOWNLOAD_URL="https://github.com/Ne0nd0g/merlin/releases/download/v2.1.4/merlin-server-linux-amd64.7z"; \
    fi && \
    echo "LOG: Versao=$LATEST_TAG | URL=$DOWNLOAD_URL" && \
    curl -L -o merlin-server.7z "$DOWNLOAD_URL" && \
    echo "LOG: Extraindo binario (password: merlin)..." && \
    7z x merlin-server.7z -pmerlin && \
    echo "LOG: Organizando binario..." && \
    TARGET_BIN=$(find . -maxdepth 2 -type f -name "merlin-server*" ! -name "*.7z" | head -n 1) && \
    if [ -z "$TARGET_BIN" ]; then echo "ERRO: Binario nao encontrado!"; exit 1; fi && \
    chmod +x "$TARGET_BIN" && \
    mv "$TARGET_BIN" merlin-server && \
    echo "LOG: Binario pronto: $(ls -l merlin-server)"

# --- Final Stage ---
FROM debian:12-slim

WORKDIR /opt/merlin

# Instalar dependências básicas de runtime e ferramentas de segurança/rede
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    iptables \
    procps \
    && rm -rf /var/lib/apt/lists/*

# Copiar binário da build stage
COPY --from=builder /app/merlin-server .
# Copiar arquivos de configuração padrão se existirem (Merlin gera ao rodar)
# Mas vamos garantir permissões de escrita para a pasta de dados
RUN mkdir -p data agents logs

# Criar script de entrypoint para otimização de memória
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Merlin Portas Padrão
# 443 - HTTP/2 Listener
# 80  - HTTP Listener
# 8888 - Hardcoded/Custom listeners
EXPOSE 443 80 8888

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
