#!/bin/bash

# Nome do diretório alvo
TARGET_DIR="forense_tools"

# Nome do arquivo de saída
OUTPUT_FILE="forense_tools_sha256_hashes.txt"

# Verifica se o diretório alvo existe
if [ ! -d "$TARGET_DIR" ]; then
    echo "Erro: O diretório $TARGET_DIR não existe."
    exit 1
fi

# Remove o arquivo de saída se já existir
if [ -f "$OUTPUT_FILE" ]; then
    rm "$OUTPUT_FILE"
fi

# Gera os hashes
find "$TARGET_DIR" -type f -print0 | while IFS= read -r -d '' file; do
    sha256sum "$file" >> "$OUTPUT_FILE"
done

# Ordena o arquivo de saída alfabeticamente pelos nomes dos arquivos
sort -k 2 "$OUTPUT_FILE" -o "$OUTPUT_FILE"

echo "Hashes SHA256 gerados e salvos em $OUTPUT_FILE"

# Exibe as primeiras linhas do arquivo de saída
echo "Primeiras linhas do arquivo de hashes:"
head "$OUTPUT_FILE"

# Conta o número total de arquivos processados
total_files=$(wc -l < "$OUTPUT_FILE")
echo "Total de arquivos processados: $total_files"