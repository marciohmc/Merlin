#!/bin/bash
set -e

echo "[Merlin] Iniciando ambiente DevSecOps..."

# Otimização de Memória para o Runtime do Go (Merlin é feito em Go)
# GOGC=50 faz o Garbage Collector rodar com mais frequência, economizando RAM em troca de um pouco mais de CPU.
# Ideal para os 512MB do Render.
export GOGC=50

# Ajustar limites de arquivos (importante para muitos agentes conectados)
ulimit -n 65535 || echo "Não foi possível aumentar ulimit, continuando..."

# Persistência: Verificar se estamos rodando em um sistema efêmero
if [ ! -d "/opt/merlin/data/persistent" ]; then
    echo "⚠️ AVISO: Pasta de persistência não detectada em /opt/merlin/data/persistent."
    echo "Os agentes e logs serão perdidos ao reiniciar o container no Render."
    echo "Dica: No render.yaml, configure um 'Disk' e monte em /opt/merlin/data."
else
    echo "✅ Armazenamento persistente detectado."
fi

# Iniciar Merlin Server
# -proto: Protocolo padrão (geralmente h2 ou h3)
# Desativamos flags pesadas se houver.
# O Merlin geralmente abre um console interativo, mas no Render precisamos que ele rode como serviço.
# Usaremos a flag --headless (se disponível na versão atual) ou rodaremos via nohup/tmux.

echo "[Merlin] Lançando servidor Merlin..."

# Merlin não tem um modo "headless" nativo perfeito para Docker logs em versões antigas, 
# mas podemos redirecionar stdin de /dev/null para evitar que ele trave esperando input no TTY 
# ou usar flags de CLI se disponíveis.

# DICA DE SEGURANÇA: Mude a senha padrão via variáveis de ambiente se o Merlin suportar, 
# ou use o comando 'user' no console interativo após o primeiro boot via 'render ssh'.

./merlin-server "$@"
