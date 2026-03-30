#!/usr/bin/env bash

# exemplo_argsu.sh - Exemplo de uso do módulo argsu.sh
#
# Demonstra:
#   - argumentos com valor usando "--flag valor"
#   - argumentos com valor usando "--flag=valor"
#   - flags booleanas
#   - argumentos posicionais
#   - separador "--" para forçar posicionais
#   - ajuda automática com --help

set -euo pipefail

if [ -z "$BASHBASE" ]; then
    echo "Variável BASHBASE não definida."
    exit 1
fi

source "$BASHBASE/lib/argsu.sh"

# Limpa definições anteriores caso o módulo já tenha sido usado no mesmo processo
arg_resetar

# Define os argumentos aceitos por este script
arg_definir "--host" HOST "localhost" "Host do servidor"
arg_definir "--porta" PORTA "8080" "Porta de conexão"
arg_definir "--saida" SAIDA "" "Arquivo de saída" "valor"
arg_definir "--verbose" VERBOSE "" "Ativa modo verboso" "boolean"
arg_definir "--dry-run" DRYRUN "" "Simula a execução sem alterar nada" "boolean"

# Parseia os argumentos recebidos
arg_parsear "$@" || exit 1

echo "=== Exemplo de uso do módulo argsu.sh ==="
echo ""
echo "Valores parseados:"
echo "  HOST=$HOST"
echo "  PORTA=$PORTA"
echo "  SAIDA=${SAIDA:-<vazio>}"
echo "  VERBOSE=${VERBOSE:-<desativado>}"
echo "  DRYRUN=${DRYRUN:-<desativado>}"
echo ""

if [ "${#_ARG__POSICIONAIS[@]}" -gt 0 ]; then
    echo "Argumentos posicionais recebidos:"
    for item in "${_ARG__POSICIONAIS[@]}"; do
        echo "  - $item"
    done
else
    echo "Nenhum argumento posicional foi informado."
fi

echo ""
echo "Exemplos de execução:"
echo "  ./examples/exemplo_argsu.sh --host api.local --porta 9000 arquivo1.txt arquivo2.txt"
echo "  ./examples/exemplo_argsu.sh --host=api.local --porta=9000 --verbose --saida resultado.log"
echo "  ./examples/exemplo_argsu.sh --dry-run -- --arquivo-que-comeca-com-traco"
