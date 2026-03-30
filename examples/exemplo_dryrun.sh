#!/bin/bash

# exemplo_dryrun.sh - Exemplos de uso do módulo dryrun.sh
#
# Demonstra:
#   1. Execução normal com `dryrun_exec`
#   2. Escrita em arquivo com `dryrun_gravar`
#   3. Ativação do modo simulação com `DRYRUN=1`
#   4. Verificação com `dryrun_ativo`

set -euo pipefail

if [ -z "$BASHBASE" ]; then
    echo "Variável BASHBASE não definida."
    exit 1
fi

source "$BASHBASE/lib/dryrun.sh"

TMP_DIR="/tmp/bashbase_exemplo_dryrun"
ARQUIVO_TESTE="$TMP_DIR/config.env"

mostrar_conteudo_arquivo() {
    if [ -f "$ARQUIVO_TESTE" ]; then
        echo "Conteúdo atual de $ARQUIVO_TESTE:"
        cat "$ARQUIVO_TESTE"
    else
        echo "Arquivo ainda não existe: $ARQUIVO_TESTE"
    fi
}

echo "=== Exemplo de uso do módulo dryrun.sh ==="
echo ""

# ---------------------------------------------------------------------------
# Exemplo 1: modo normal
# ---------------------------------------------------------------------------

echo "1) Execução normal (DRYRUN desativado)"
DRYRUN=""

if dryrun_ativo; then
    echo "Modo dry-run ativo"
else
    echo "Modo normal ativo"
fi

dryrun_exec "mkdir -p '$TMP_DIR'" mkdir -p "$TMP_DIR"
dryrun_gravar "$ARQUIVO_TESTE" "AMBIENTE=desenvolvimento"
dryrun_gravar "$ARQUIVO_TESTE" "PORTA=8080"

mostrar_conteudo_arquivo
echo ""

# ---------------------------------------------------------------------------
# Exemplo 2: modo dry-run
# ---------------------------------------------------------------------------

echo "2) Simulação com DRYRUN=1"
DRYRUN="1"

if dryrun_ativo; then
    echo "Modo dry-run ativo: nenhuma alteração real será feita"
fi

# Estes comandos serão apenas simulados e impressos no stderr
dryrun_exec "rm -f '$ARQUIVO_TESTE'" rm -f "$ARQUIVO_TESTE"
dryrun_gravar "$ARQUIVO_TESTE" "AMBIENTE=producao"
dryrun_gravar "$ARQUIVO_TESTE" "PORTA=9090"

echo ""
echo "Após o dry-run, o arquivo continua inalterado:"
mostrar_conteudo_arquivo
echo ""

# ---------------------------------------------------------------------------
# Exemplo 3: simulação de comando arbitrário
# ---------------------------------------------------------------------------

echo "3) Simulando um comando qualquer"
dryrun_exec "cp '$ARQUIVO_TESTE' '$TMP_DIR/config.env.bak'" cp "$ARQUIVO_TESTE" "$TMP_DIR/config.env.bak"
echo ""

# Limpeza real do ambiente de teste
DRYRUN=""
dryrun_exec "rm -rf '$TMP_DIR'" rm -rf "$TMP_DIR"

echo "=== Fim do exemplo ==="
