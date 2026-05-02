# --- Build Stage ---
FROM golang:1.23-bullseye AS builder
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates p7zip-full && \
    rm -rf /var/lib/apt/lists/*

# Fixando na v2.1.4 para estabilidade
RUN curl -L -o merlin.7z https://github.com/Ne0nd0g/merlin/releases/download/v2.1.4/merlin-server-linux-amd64.7z && \
    7z x merlin.7z -pmerlin -y && \
    TARGET_BIN=$(find . -type f -name "merlin-server*" ! -name "*.7z" | head -n 1) && \
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
