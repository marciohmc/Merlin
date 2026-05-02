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
RUN LATEST_TAG=$(curl -s https://api.github.com/repos/Ne0nd0g/merlin/releases/latest | jq -r .tag_name) && \
    DOWNLOAD_URL=$(curl -s https://api.github.com/repos/Ne0nd0g/merlin/releases/latest | jq -r '.assets[] | select(.name | contains("server-linux-amd64.7z")) | .browser_download_url') && \
    echo "Downloading Merlin Server ${LATEST_TAG} from ${DOWNLOAD_URL}..." && \
    curl -L -o merlin-server.7z "$DOWNLOAD_URL" && \
    7z x merlin-server.7z && \
    # O binário extraído geralmente vem com nome como merlin-server (tentar localizar se mudar)
    find . -name "merlin-server*" -type f -exec chmod +x {} + && \
    # Mover para um nome padrão para facilitar a cópia
    mv $(find . -name "merlin-server*" -type f | head -n 1) merlin-server

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
