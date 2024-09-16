#!/bin/bash

# Diretório de trabalho
WORK_DIR="$(pwd)/static_tools_build"
INSTALL_DIR="$WORK_DIR/install"

# Criar diretórios
mkdir -p "$WORK_DIR" "$INSTALL_DIR"

# Função para compilar uma ferramenta
compile_tool() {
    local name="$1"
    local url="$2"
    local configure_opts="${3:-}"
    
    cd "$WORK_DIR"
    wget "$url" -O "$name.tar.gz"
    tar xzvf "$name.tar.gz"
    cd "$name"*
    
    ./configure --prefix="$INSTALL_DIR" --enable-static --disable-shared $configure_opts
    make -j$(nproc)
    make install
    
    cd "$WORK_DIR"
}

# Compilar coreutils (inclui muitas ferramentas básicas)
compile_tool "coreutils" "https://ftp.gnu.org/gnu/coreutils/coreutils-8.32.tar.xz" \
    "CFLAGS=-static LDFLAGS=-static"

# Compilar procps-ng (inclui ps, top)
compile_tool "procps" "https://sourceforge.net/projects/procps-ng/files/Production/procps-ng-3.3.17.tar.xz" \
    "CFLAGS=-static LDFLAGS=-static"

# Compilar net-tools (inclui netstat, ifconfig)
git clone https://github.com/ecki/net-tools.git
cd net-tools
make CFLAGS=-static LDFLAGS=-static
make DESTDIR="$INSTALL_DIR" install
cd "$WORK_DIR"

# Compilar iproute2 (inclui ip)
compile_tool "iproute2" "https://mirrors.edge.kernel.org/pub/linux/utils/net/iproute2/iproute2-5.15.0.tar.xz" \
    "CFLAGS=-static LDFLAGS=-static"

# Compilar tcpdump
compile_tool "tcpdump" "https://www.tcpdump.org/release/tcpdump-4.99.1.tar.gz" \
    "CFLAGS=-static LDFLAGS=-static"

# Compilar OpenSSH (inclui ssh, scp)
compile_tool "openssh" "https://cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-8.8p1.tar.gz" \
    "--with-ssl-dir=/path/to/openssl --with-zlib=/path/to/zlib CFLAGS=-static LDFLAGS=-static"

echo "Ferramentas estáticas compiladas e instaladas em $INSTALL_DIR"
