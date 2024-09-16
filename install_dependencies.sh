#!/bin/bash

# Lista de ferramentas para verificar e instalar
tools=(
    stat ls netstat grep sha256sum sha512sum tcpdump ps df du vim touch ssh cp mv
    pwd more less rmdir rm file strings zip tar cat sed head tail awk sort cut
    diff tee ping find chmod chown top htop uname hostname time date watch kill
    wget curl ln scp rsync ip traceroute nslookup dig dd echo w last lastlog
    lsof mount free ss iptables bash ldd which memdump
)

# Função para verificar se uma ferramenta está instalada
is_installed() {
    command -v "$1" >/dev/null 2>&1
}

# Função para instalar uma ferramenta
install_tool() {
    echo "Instalando $1..."
    sudo apt-get install -y "$1"
}

# Verificar se o script está sendo executado como root
if [ "$EUID" -ne 0 ]; then
    echo "Por favor, execute este script como root ou usando sudo."
    exit 1
fi

# Atualizar lista de pacotes
echo "Atualizando lista de pacotes..."
apt-get update

# Verificar e instalar cada ferramenta
for tool in "${tools[@]}"; do
    if ! is_installed "$tool"; then
        echo "$tool não está instalado."
        install_tool "$tool"
    else
        echo "$tool já está instalado."
    fi
done

echo "Verificação e instalação concluídas."