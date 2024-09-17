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

echo -e "${GREEN}Instalando dependências...${NC}"
sudo ./install_dependencies.sh

# Diretório de destino para os binários e bibliotecas
DEST_DIR="./forense_tools"

# Lista de binários a serem copiados, exatamente como fornecida pelo usuário
BINARIES=(
    stat ls netstat grep sha256sum sha512sum tcpdump ps df du vim touch ssh cp mv
    pwd more less rmdir rm file strings zip tar cat sed head tail awk sort cut
    diff tee ping find chmod chown top htop uname hostname time date watch kill
    wget curl ln scp rsync ip traceroute nslookup dig dd echo w last lastlog
    lsof mount free ss iptables bash ldd which memdump clear reset id whoami
)

# Função para copiar um binário e suas dependências
copy_binary_and_deps() {
    local binary=$1
    local binary_path=$(which $binary)

    if [ -z "$binary_path" ]; then
        echo "Aviso: $binary não encontrado"
        return
    fi

    # Copiar o binário
    mkdir -p "$DEST_DIR/$(dirname $binary_path)"
    cp "$binary_path" "$DEST_DIR$binary_path"

    # Copiar as dependências
    ldd "$binary_path" 2>/dev/null | grep "=> /" | awk '{print $3}' | while read -r lib; do
        mkdir -p "$DEST_DIR$(dirname $lib)"
        cp "$lib" "$DEST_DIR$lib"
    done

    # Copiar o interpretador dinâmico se existir
    interp=$(ldd "$binary_path" 2>/dev/null | grep "ld-linux" | awk '{print $1}')
    if [ -n "$interp" ]; then
        mkdir -p "$DEST_DIR$(dirname $interp)"
        cp "$interp" "$DEST_DIR$interp"
    fi
}

# Criar diretório de destino
mkdir -p "$DEST_DIR"

# Copiar cada binário e suas dependências
for binary in "${BINARIES[@]}"; do
    echo "Copiando $binary e suas dependências..."
    copy_binary_and_deps "$binary"
done

echo "Processo concluído. Os binários e bibliotecas foram copiados para $DEST_DIR"

# Script de inicialização
cat > "./init.sh" << EOF
#!/bin/bash


# Define cores para o terminal
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "\${YELLOW}CSIRT-DF\${NC}"
echo -e "\${YELLOW}   ___                        _        _____            _      \${NC}"
echo -e "\${YELLOW}  / __\__  _ __ ___ _ __  ___(_) ___  /__   \___   ___ | |___  \${NC}"
echo -e "\${YELLOW} / _\/ _ \| '__/ _ \ '_ \/ __| |/ __|   / /\/ _ \ / _ \| / __| \${NC}"
echo -e "\${YELLOW}/ / | (_) | | |  __/ | | \__ \ | (__   / / | (_) | (_) | \__ \ \${NC}"
echo -e "\${YELLOW}\/   \___/|_|  \___|_| |_|___/_|\___|  \/   \___/ \___/|_|___/ \${NC}"

# Ativar modo de erro estrito
set -euo pipefail

# Verificar se está sendo executado como root
if [ "\$(id -u)" != "0" ]; then
   echo "Este script deve ser executado como root" 1>&2
   exit 1
fi

SCRIPT_DIR=\$(dirname "\$(readlink -f "./init.sh")")
FORENSIC_TOOLS_DIR="\$SCRIPT_DIR"

echo -e "\${YELLOW}"Configurando ambiente forense..."\${NC}"
echo "\$FORENSIC_TOOLS_DIR"

# Configurar PATH
export PATH="\$FORENSIC_TOOLS_DIR/usr/bin:\$FORENSIC_TOOLS_DIR/usr/sbin:"

# Configurar LD_LIBRARY_PATH
export LD_LIBRARY_PATH="\$FORENSIC_TOOLS_DIR/lib/x86_64-linux-gnu:\$FORENSIC_TOOLS_DIR/lib64:"

# Limpar LD_PRELOAD
unset LD_PRELOAD

# Verificar se o bash forense existe
FORENSIC_BASH="\$FORENSIC_TOOLS_DIR/usr/bin/bash"
if [ ! -x "\$FORENSIC_BASH" ]; then
    echo "Erro: bash forense não encontrado em \$FORENSIC_BASH" >&2
    exit 1
fi

# Exibir configuração final
echo -e "\${YELLOW}"Ambiente forense configurado:"\${NC}"
echo "Usuário atual: \$(id)"
echo "PATH=\$PATH"
echo "LD_LIBRARY_PATH=\$LD_LIBRARY_PATH"
echo "LD_PRELOAD está limpo"
echo "Usando bash forense: \$FORENSIC_BASH"

# Função para desativar o ambiente forense
forensic_exit() {
    echo "Desativando ambiente forense..."
    # Restaurar variáveis de ambiente originais aqui, se necessário
    unset -f forensic_exit
}

# Registrar a função de saída
trap forensic_exit EXIT

# Manter o shell como root, usando o bash forense
echo -e "\${RED}"Entrando em shell root forense. Use 'exit' para sair."\${NC}"
exec "\$FORENSIC_BASH" --norc
EOF

cp "./init.sh" "$DEST_DIR/init.sh"

chmod +x "$DEST_DIR/init.sh"

echo "Script de inicialização atualizado criado em $DEST_DIR/init.sh"

chmod +x "$DEST_DIR/init.sh"

echo "Script de inicialização criado em $DEST_DIR/init.sh"

echo "Gerando hashes"
source ./generate_sha256_hashes.sh

echo "Gerando imagem .iso"
sudo genisoimage -o forensic_tools.iso -R -J -joliet-long -iso-level 3 -V "Forensic_Tools" forense_tools/
