# --- Build Stage ---
FROM golang:1.23-bullseye AS builder

WORKDIR /app

# Instalar dependências necessárias para download e extração
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Obter a versão mais recente do Merlin Server do GitHub
RUN LATEST_TAG=$(curl -s https://api.github.com/repos/Ne0nd0g/merlin/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/') && \
    echo "Downloading Merlin Server version ${LATEST_TAG}..." && \
    # Baixar especificamente o servidor para Linux x64
    curl -L -o merlin-server.zip "https://github.com/Ne0nd0g/merlin/releases/download/${LATEST_TAG}/merlin-server-linux-x64.zip" && \
    unzip merlin-server.zip && \
    chmod +x merlin-server

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
