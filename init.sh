#!/bin/bash


# Define cores para o terminal
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}CSIRT-DF${NC}"
echo -e "${YELLOW}   ___                        _        _____            _      ${NC}"
echo -e "${YELLOW}  / __\__  _ __ ___ _ __  ___(_) ___  /__   \___   ___ | |___  ${NC}"
echo -e "${YELLOW} / _\/ _ \| '__/ _ \ '_ \/ __| |/ __|   / /\/ _ \ / _ \| / __| ${NC}"
echo -e "${YELLOW}/ / | (_) | | |  __/ | | \__ \ | (__   / / | (_) | (_) | \__ \ ${NC}"
echo -e "${YELLOW}\/   \___/|_|  \___|_| |_|___/_|\___|  \/   \___/ \___/|_|___/ ${NC}"

# Ativar modo de erro estrito
set -euo pipefail

# Verificar se está sendo executado como root
if [ "$(id -u)" != "0" ]; then
   echo "Este script deve ser executado como root" 1>&2
   exit 1
fi

SCRIPT_DIR=$(dirname "$(readlink -f "./init.sh")")
FORENSIC_TOOLS_DIR="$SCRIPT_DIR"

echo -e "${YELLOW}"Configurando ambiente forense..."${NC}"
echo "$FORENSIC_TOOLS_DIR"

# Configurar PATH
export PATH="$FORENSIC_TOOLS_DIR/usr/bin:$FORENSIC_TOOLS_DIR/usr/sbin:"

# Configurar LD_LIBRARY_PATH
export LD_LIBRARY_PATH="$FORENSIC_TOOLS_DIR/lib/x86_64-linux-gnu:$FORENSIC_TOOLS_DIR/lib64:"

# Limpar LD_PRELOAD
unset LD_PRELOAD

# Verificar se o bash forense existe
FORENSIC_BASH="$FORENSIC_TOOLS_DIR/usr/bin/bash"
if [ ! -x "$FORENSIC_BASH" ]; then
    echo "Erro: bash forense não encontrado em $FORENSIC_BASH" >&2
    exit 1
fi

# Exibir configuração final
echo -e "${YELLOW}"Ambiente forense configurado:"${NC}"
echo "Usuário atual: $(id)"
echo "PATH=$PATH"
echo "LD_LIBRARY_PATH=$LD_LIBRARY_PATH"
echo "LD_PRELOAD está limpo"
echo "Usando bash forense: $FORENSIC_BASH"

# Função para desativar o ambiente forense
forensic_exit() {
    echo "Desativando ambiente forense..."
    # Restaurar variáveis de ambiente originais aqui, se necessário
    unset -f forensic_exit
}

# Registrar a função de saída
trap forensic_exit EXIT

# Manter o shell como root, usando o bash forense
echo -e "${RED}"Entrando em shell root forense. Use 'exit' para sair."${NC}"
exec "$FORENSIC_BASH" --norc
