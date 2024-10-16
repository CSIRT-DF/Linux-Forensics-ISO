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

# Criar diretório de destino
mkdir -p "$DEST_DIR"

# Copie as pastas `/bin`, `/sbin`, `/lib`, e `/lib64` para o diretório `forense_tools`
echo -e "${GREEN}Copiando binários e bibliotecas para $DEST_DIR...${NC}"

echo -e "${BLUE} Copiando /bin"
rsync -a --delete --info=progress2 /bin/ "$DEST_DIR/bin/"

echo -e "${BLUE} Copiando /sbin"
rsync -a --delete  --info=progress2 /sbin/ "$DEST_DIR/sbin/"

echo -e "${BLUE} Copiando /lib"
rsync -a --delete --info=progress2 /lib/ "$DEST_DIR/lib/"

echo -e "${BLUE} Copiando /lib32"
rsync -a --delete --info=progress2 /lib32/ "$DEST_DIR/lib32/"

echo -e "${BLUE} Copiando /lib64"
rsync -a --delete --info=progress2 /lib64/ "$DEST_DIR/lib64/"

echo "Processo concluído. Os binários e bibliotecas foram copiados para $DEST_DIR"


# Script de inicialização
cat > "./init.sh" << EOF
#!/bin/bash

# Define cores para o terminal
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR=\$(dirname "\$(readlink -f "./init.sh")")
FORENSIC_TOOLS_DIR="\$SCRIPT_DIR"

echo -e "\${YELLOW}CSIRT-DF\${NC}"
echo -e "\${YELLOW}   ___                        _        _____            _      \${NC}"
echo -e "\${YELLOW}  / __\__  _ __ ___ _ __  ___(_) ___  /__   \___   ___ | |___  \${NC}"
echo -e "\${YELLOW} / _\/ _ \| '__/ _ \ '_ \/ __| |/ __|   / /\/ _ \ / _ \| / __| \${NC}"
echo -e "\${YELLOW}/ / | (_) | | |  __/ | | \__ \ | (__   / / | (_) | (_) | \__ \ \${NC}"
echo -e "\${YELLOW}\/   \___/|_|  \___|_| |_|___/_|\___|  \/   \___/ \___/|_|___/ \${NC}"

# Ativar modo de erro estrito
set -euo pipefail


# Função para adicionar diretórios ao LD_LIBRARY_PATH
# Função para adicionar diretórios ao LD_LIBRARY_PATH
add_to_ld_library_path() {
    local dir="$1"
    if [ -d "\$dir" ]; then
        find "\$dir" -type d | while read -r subdir; do
            LD_LIBRARY_PATH="${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}\$subdir"
        done
    fi
}

# Inicializa LD_LIBRARY_PATH
LD_LIBRARY_PATH=""

# Varre os diretórios lib, lib32 e lib64 relativos a FORENSIC_TOOLS_DIR
for lib_dir in "lib" "lib32" "lib64"; do
    add_to_ld_library_path "z$FORENSIC_TOOLS_DIR/z$lib_dir"
done

# Remove o último ':' se existir
LD_LIBRARY_PATH=\$(echo $LD_LIBRARY_PATH | sed 's/:$//')

# Verificar se está sendo executado como root
if [ "\$(id -u)" != "0" ]; then
   echo "Este script deve ser executado como root" 1>&2
   exit 1
fi



echo -e "\${YELLOW}"Configurando ambiente forense..."\${NC}"
echo "\$FORENSIC_TOOLS_DIR"

# Configurar PATH
export PATH="\$FORENSIC_TOOLS_DIR/usr/local/sbin:\$FORENSIC_TOOLS_DIR/usr/local/bin:\$FORENSIC_TOOLS_DIR/usr/sbin:\$FORENSIC_TOOLS_DIR/usr/bin:\$FORENSIC_TOOLS_DIR/sbin:\$FORENSIC_TOOLS_DIR/bin"


# Configurar LD_LIBRARY_PATH
export LD_LIBRARY_PATH


# Limpar LD_PRELOAD
unset LD_PRELOAD

# Verificar se o bash forense existe
FORENSIC_BASH="\$FORENSIC_TOOLS_DIR/bin/bash"
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
   echo -e "\${RED}Desativando ambiente forense...\${NC}"
    # Desmontar o ponto de montagem /media
    if mountpoint -q /media; then
        echo "Desmontando /media..."
        umount /media
        if [ \$? -eq 0 ]; then
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
echo -e "\${RED}"Entrando em shell root forense. Use 'exit' para sair."\${NC}"
exec "\$FORENSIC_BASH" --norc
EOF

cp "./init.sh" "$DEST_DIR/init.sh"

chmod +x "$DEST_DIR/init.sh"

echo "Script de inicialização atualizado criado em $DEST_DIR/init.sh"

chmod +x "$DEST_DIR/init.sh"

echo "Script de inicialização criado em $DEST_DIR/init.sh"

#echo "Gerando hashes"
#source ./generate_sha256_hashes.sh

echo "Gerando imagem .iso"
# Excluindo imagem .iso anterior se existir
if [ -f "build/forensic_tools.iso" ]; then
    echo -e "${RED}Excluindo imagem .iso anterior...${NC}"
    rm -f build/forensic_tools.iso
fi


# sudo genisoimage -o forensic_tools.iso -R -J -joliet-long -iso-level 3 -V "Forensic_Tools" forense_tools/ | pv -s "$(du -sb forense_tools/ | awk '{print $1}')" > /dev/null
(sudo genisoimage -o - -R -J -joliet-long -iso-level 3 -V "Forensic_Tools" forense_tools/ | \
pv -s "$(du -sb forense_tools/ | awk '{print $1}')" | \
dd of=build/forensic_tools.iso bs=4M) 2>&1 | grep --line-buffered -o '\([0-9.]\+%\)'
