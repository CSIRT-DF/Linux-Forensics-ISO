# Linux Forensic Tools

```console
CSIRT-DF
   ___                        _        _____            _      
  / __\__  _ __ ___ _ __  ___(_) ___  /__   \___   ___ | |___  
 / _\/ _ \| '__/ _ \ '_ \/ __| |/ __|   / /\/ _ \ / _ \| / __| 
/ / | (_) | | |  __/ | | \__ \ | (__   / / | (_) | (_) | \__ \ 
\/   \___/|_|  \___|_| |_|___/_|\___|  \/   \___/ \___/|_|___/ 
Configurando ambiente forense...
/media
Ambiente forense configurado:
Usuário atual: uid=0(root) gid=0(root) groups=0(root)
PATH=/media/usr/local/sbin:/media/usr/local/bin:/media/usr/sbin:/media/usr/bin:/media/sbin:/media/bin
LD_LIBRARY_PATH=/media/lib:/media/lib64
LD_PRELOAD está limpo
Usando bash forense: /media/bin/bash
Entrando em shell root forense. Use exit para sair.
bash-5.1# 
```

## Visão Geral

Este kit de ferramentas forenses para Linux é projetado para fornecer um ambiente isolado e confiável para análises forenses digitais. Ele inclui uma coleção de binários e bibliotecas seguros, empacotados em uma imagem ISO para fácil distribuição e uso.

## Pré-requisitos

- Sistema operacional Linux ou Windows com WSL
- Privilégios de superusuário (root)
- Ferramentas: `mount`, `genisoimage`, `sha256sum`

## Uso do Kit Forense

### 1. Montando a imagem .iso

```bash
sudo mount -o loop forensic_tools.iso /media
```

Certifique-se de que o diretório `/media` existe e está vazio antes de montar.

### 2. Inicializando o Ambiente Forense

O script `init.sh` modifica as variáveis de ambiente para utilizar os binários e bibliotecas seguros do kit forense. Execute-o cada vez que montar a imagem:

```bash
cd /media
sudo source ./init.sh
```

### 3. Verificando a Configuração

Para confirmar se o ambiente está corretamente configurado:

```bash
which ls
ldd $(which ls)
```

Estes comandos devem mostrar caminhos dentro de `/media`, não do sistema host.

### 4. Realizando a Análise Forense

Agora você está em um ambiente forense isolado. Use as ferramentas fornecidas para sua análise.

#### Captura da Memória

```bash
sudo memdump | ssh csirt@forensics "cat > /media/artefatos/memory_$(date +%Y%m%d_%H%M%S).dump"
```

#### Tráfego de Rede

Ajustes os comandos conforme necessário para capturar o tráfego de rede.

```bash
sudo tcpdump -i eth0 'not (port 22)' -w - | ssh csirt@forensics "cat > /media/artefatos/captura_$(date +%Y%m%d_%H%M%S).pcap"
```

Você pode visualizar o arquivo `.pcap` com a ferramenta `tcpdump`:

```bash
tcpdump -r captura_20240916_181214.pcap -nnvvX
```

### 5. Saindo do Ambiente Forense

Quando terminar, use o comando `exit` para sair do shell forense.

### 6. Desmontando a Imagem

```bash
sudo umount /media
```

## Desenvolvimento e Manutenção do Kit

O script `build.sh` realiza todo o trabalho de compilação e empacotamento do kit forense. Execute-o para gerar uma nova imagem ISO:

```bash
sudo ./build.sh
```

## Testando a imagem .iso

```bash
./test.sh
```

## Desmontando a imagem .iso

```bash
./clean.sh
```

Revise o script `build.sh` para garantir que todos os binários necessários estejam incluídos.

### Manualmente

Copie as pastas `/bin`, `/sbin`, `/lib`, e `/lib64` para o diretório `forense_tools`:

```bash
cp -rL /lib64 forense_tools
```

Crie a imagem ISO:

```bash
genisoimage -o forensic_tools.iso -R -J -V "Forensic Tools" forense_tools
```

Monte a imagem para testar:

```bash
sudo mount -o loop forensic_tools.iso /media
```

Modifique as variáveis de ambiente:

```bash
export PATH=/media/usr/local/sbin:/media/usr/local/bin:/media/usr/sbin:/media/usr/bin:/media/sbin:/media/bin
export LD_LIBRARY_PATH=/media/lib:/mnt/lib64
```

## Boas Práticas

1. Sempre verifique a integridade da imagem ISO antes de usá-la.
2. Mantenha um log detalhado de todas as ações realizadas durante a análise.
3. Use apenas as ferramentas fornecidas no kit para garantir a integridade da análise.
4. Regularmente atualize o kit com as versões mais recentes das ferramentas.

## Solução de Problemas

- Se encontrar erros ao montar a ISO, verifique se tem permissões de superusuário.
- Se os binários não estiverem funcionando como esperado, verifique as variáveis de ambiente e os caminhos das bibliotecas.

## Segurança

- Nunca use este kit em um sistema potencialmente comprometido.
- Mantenha a imagem ISO em um local seguro e controlado.
- Regularmente verifique se há atualizações de segurança para as ferramentas incluídas.
