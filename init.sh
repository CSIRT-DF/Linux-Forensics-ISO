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


# Função para adicionar diretórios ao LD_LIBRARY_PATH
add_to_ld_library_path() {
    local dir=""
    if [ -d "" ]; then
        find "" -type d | while read -r subdir; do
            LD_LIBRARY_PATH=""
        done
    fi
}

# Inicializa LD_LIBRARY_PATH
LD_LIBRARY_PATH=""

# Varre os diretórios lib, lib32 e lib64
for lib_dir in "lib" "lib32" "lib64"; do
    add_to_ld_library_path "$FORENSIC_TOOLS_DIR/$lib_dir"
done

# Remove o último ':' se existir
LD_LIBRARY_PATH=$(echo  | sed 's/:$//')

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
export PATH="$FORENSIC_TOOLS_DIR/usr/local/sbin:$FORENSIC_TOOLS_DIR/usr/local/bin:$FORENSIC_TOOLS_DIR/usr/sbin:$FORENSIC_TOOLS_DIR/usr/bin:$FORENSIC_TOOLS_DIR/sbin:$FORENSIC_TOOLS_DIR/bin"


# Configurar LD_LIBRARY_PATH
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH"


# Limpar LD_PRELOAD
unset LD_PRELOAD

# Verificar se o bash forense existe
FORENSIC_BASH="$FORENSIC_TOOLS_DIR/bin/bash"
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
    # Desmontar o ponto de montagem /media
    if mountpoint -q /media; then
        echo "Desmontando /media..."
        umount /media
        if [ $? -eq 0 ]; then
            echo "Ponto de montagem /media desmontado com sucesso."
        else
            echo "Erro ao desmontar /media. Por favor, verifique manualmente."
        fi
    else
        echo "/media não está montado."
    fi
    # Restaurar variáveis de ambiente originais aqui, se necessário
    unset -f forensic_exit
}


# Registrar a função de saída
trap forensic_exit EXIT

# Manter o shell como root, usando o bash forense
echo -e "${RED}"Entrando em shell root forense. Use 'exit' para sair."${NC}"
exec "$FORENSIC_BASH" --norc
