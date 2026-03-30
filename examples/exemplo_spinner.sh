#!/bin/bash

# Exemplo de uso do módulo spinner.sh
# Demonstra as três funções de animação de progresso disponíveis

set -euo pipefail

if [ -z "$BASHBASE" ]; then
    echo -e "Variável BASHBASE não definida."
    exit 1
fi

source "$BASHBASE/lib/spinner.sh"

echo "=== Exemplos de uso do módulo spinner.sh ==="
echo ""

# Exemplo 1: spinner genérico com frames simples
echo "1º exemplo: spinner com frames simples (|\-/)"
sleep 2 &
spinner "$!" "|\-/" "Compactando arquivo..."
echo ""

# Exemplo 2: spinner genérico com frames Braille
echo "2º exemplo: spinner com frames Braille"
sleep 3 &
spinner "$!" "⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏" "Sincronizando dados..." 0.08
echo ""

# Exemplo 3: spinner com frames de círculo
echo "3º exemplo: spinner com frames de círculo"
sleep 2 &
spinner "$!" "◐◓◑◒" "Processando..." 0.12
echo ""

# Exemplo 4: spinner_pingpong (barra vertical ping-pong)
echo "4º exemplo: spinner_pingpong (barra vertical)"
sleep 2 &
spinner_pingpong "$!" "Instalando pacotes..."
echo ""

# Exemplo 5: spinner_bar (barra horizontal deslizante)
echo "5º exemplo: spinner_bar (barra horizontal)"
sleep 2 &
spinner_bar "$!" "Baixando arquivo..."
echo ""

# Exemplo 6: Exemplo prático com comando real
echo "6º exemplo: spinner com tar (compactação real)"
mkdir -p /tmp/spinner_demo
echo "arquivo teste" > /tmp/spinner_demo/teste.txt
tar -czf /tmp/spinner_demo/backup.tar.gz /tmp/spinner_demo/teste.txt 2>/dev/null &
spinner "$!" "⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏" "Compactando com tar..."
echo ""

# Limpeza
rm -rf /tmp/spinner_demo

echo "=== Exemplos concluídos! ==="
