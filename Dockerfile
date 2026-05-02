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

# Obter a versão estável v2.1.4 e baixar o asset .7z para Linux amd64
# Nota: Fixamos a versão para evitar erros de Rate Limit da API do GitHub durante o build
RUN LATEST_TAG="v2.1.4" && \
    DOWNLOAD_URL="https://github.com/Ne0nd0g/merlin/releases/download/${LATEST_TAG}/merlin-server-linux-amd64.7z" && \
    echo "LOG: Baixando Merlin Server ${LATEST_TAG}..." && \
    curl -L -o merlin-server.7z "$DOWNLOAD_URL" && \
    echo "LOG: Extraindo binario..." && \
    # Tentamos extrair. Se houver senha 'merlin', ele usa; se não, extrai normalmente.
    7z x merlin-server.7z -pmerlin -y || 7z x merlin-server.7z -y && \
    echo "LOG: Organizando binario..." && \
    # Busca recursiva pelo binário (geralmente dentro de uma subpasta após extrair)
    TARGET_BIN=$(find . -type f -name "merlin-server*" ! -name "*.7z" | head -n 1) && \
    if [ -z "$TARGET_BIN" ]; then echo "ERRO: Binario nao encontrado!"; ls -R; exit 1; fi && \
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
