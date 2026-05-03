# --- Build Stage ---
FROM golang:1.23-bullseye AS builder
WORKDIR /app

# Versão estável alvo
ENV MERLIN_VERSION="v2.1.4"

RUN set -xe; \
    apt-get update && apt-get install -y --no-install-recommends git ca-certificates && \
    echo "LOG: Clonando Merlin C2 ${MERLIN_VERSION}..." && \
    git clone --depth 1 --branch ${MERLIN_VERSION} https://github.com/Ne0nd0g/merlin.git . && \
    echo "LOG: Compilando Merlin Server..." && \
    go mod download && \
    go build -ldflags="-s -w" -o merlin-server main.go && \
    chmod +x merlin-server && \
    echo "LOG: Compilação concluída com sucesso!"

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
