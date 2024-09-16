#!/bin/bash

# Ativar modo de erro estrito
set -euo pipefail

# Verificar se está sendo executado como root
if [ "$(id -u)" != "0" ]; then
   echo "Este script deve ser executado como root" 1>&2
   exit 1
fi

FORENSIC_TOOLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Função para adicionar diretórios ao início de uma variável de ambiente PATH-like
prepend_path() {
    local var_name=$1
    local new_path=$2
    local current_path=${!var_name//"::"/":"}
    current_path=${current_path#":"}
    current_path=${current_path%":"}
    export $var_name="$new_path${current_path:+:$current_path}"
}

# Limpar variáveis existentes
PATH=""
LD_LIBRARY_PATH=""
MANPATH=""
unset LD_PRELOAD  # Limpar LD_PRELOAD

# Configurar PATH
for dir in bin sbin usr/bin usr/sbin; do
    prepend_path PATH "$FORENSIC_TOOLS_DIR/$dir"
done

# Configurar LD_LIBRARY_PATH
for dir in lib lib64 usr/lib usr/lib64; do
    prepend_path LD_LIBRARY_PATH "$FORENSIC_TOOLS_DIR/$dir"
done

# Configurar MANPATH
prepend_path MANPATH "$FORENSIC_TOOLS_DIR/usr/share/man"

# Adicionar caminhos padrão do sistema ao final
PATH="$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Verificar se os diretórios críticos existem
for dir in bin sbin usr/bin usr/sbin lib lib64 usr/lib usr/lib64; do
    if [ ! -d "$FORENSIC_TOOLS_DIR/$dir" ]; then
        echo "Aviso: Diretório $FORENSIC_TOOLS_DIR/$dir não encontrado" >&2
    fi
done

# Verificar se o bash forense existe
FORENSIC_BASH="$FORENSIC_TOOLS_DIR/bin/bash"
if [ ! -x "$FORENSIC_BASH" ]; then
    echo "Erro: bash forense não encontrado em $FORENSIC_BASH" >&2
    exit 1
fi

# Exibir configuração final
echo "Ambiente forense configurado:"
echo "Usuário atual: $(id)"
echo "PATH=$PATH"
echo "LD_LIBRARY_PATH=$LD_LIBRARY_PATH"
echo "MANPATH=$MANPATH"
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
echo "Entrando em shell root forense. Use 'exit' para sair."
exec "$FORENSIC_BASH" --norc
