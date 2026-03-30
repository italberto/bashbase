#!/bin/bash

# exemplo_sinais.sh - Demonstração do sistema de cleanup automático via sinais.sh
#
# Mostra três cenários onde recursos precisam ser liberados mesmo em caso de
# interrupção (Ctrl+C, kill, ou erro não tratado):
#
#   Cenário 1 - Arquivo temporário: registrar_cleanup com rm
#   Cenário 2 - Lock exclusivo: lock_adquirir_com_cleanup
#   Cenário 3 - Spinner + Ctrl+C: cursor restaurado automaticamente
#
# Para testar o cleanup por interrupção, pressione Ctrl+C durante qualquer
# operação com spinner e observe que o cursor volta a aparecer no terminal.

set -euo pipefail

if [ -z "$BASHBASE" ]; then
    echo "Variável BASHBASE não definida."
    exit 1
fi

source $BASHBASE/lib/sinais.sh
source $BASHBASE/lib/alerta.sh
source $BASHBASE/lib/procesu.sh
source $BASHBASE/lib/runu.sh

# ---------------------------------------------------------------------------
# Cenário 1: Arquivo temporário com cleanup garantido
#
# Sem sinais.sh: se o script morrer antes do rm, o arquivo fica para sempre.
# Com sinais.sh: o arquivo é removido no cleanup independente de como o script sair.
# ---------------------------------------------------------------------------

info "=== Cenário 1: arquivo temporário ==="

ARQUIVO_TEMP=$(mktemp /tmp/exemplo_sinais_XXXXXX)
info "Arquivo temporário criado: $ARQUIVO_TEMP"

# Registra a remoção no stack de cleanup
registrar_cleanup "rm -f $ARQUIVO_TEMP"

# Simula processamento que usa o arquivo
echo "dados importantes" > "$ARQUIVO_TEMP"
sleep 1

# Remove manualmente ao terminar o uso (caminho feliz)
rm -f "$ARQUIVO_TEMP"
# Como o arquivo já foi removido, cancela o cleanup para evitar erro no rm
cancelar_cleanup "rm -f $ARQUIVO_TEMP"

sucesso "Arquivo temporário removido. Cleanup cancelado pois já foi limpo."

# ---------------------------------------------------------------------------
# Cenário 2: Lock exclusivo com liberação automática
#
# lock_adquirir_com_cleanup combina aquisição do lock + registro no cleanup.
# Se o script for interrompido, o lock é removido e uma nova instância pode rodar.
# ---------------------------------------------------------------------------

info "=== Cenário 2: lock exclusivo ==="

LOCK=/tmp/exemplo_sinais.lock

# Uma linha substitui o padrão verboso de duas:
#   lock_adquirir "$LOCK" || exit 1
#   trap "lock_liberar $LOCK" EXIT
lock_adquirir_com_cleanup "$LOCK" || {
    erro "Outra instância já está em execução (lock: $LOCK)"
    exit 1
}

info "Lock adquirido: $LOCK"
info "PID gravado no lock: $(cat $LOCK/pid)"

# Simula trabalho exclusivo
sleep 1

# Libera manualmente ao terminar (caminho feliz)
lock_liberar "$LOCK"
# Remove do stack pois já foi liberado
cancelar_cleanup "lock_liberar $LOCK"

sucesso "Lock liberado. Cleanup cancelado pois já foi limpo."

# ---------------------------------------------------------------------------
# Cenário 3: Spinner com proteção de cursor
#
# spinner.sh registra _spinner_restaurar_cursor automaticamente ao ser carregado.
# Se você pressionar Ctrl+C DURANTE a animação abaixo, o cursor será restaurado
# pelo cleanup de sinais.sh — o terminal não ficará travado sem cursor.
#
# Teste: execute o script e pressione Ctrl+C enquanto o spinner estiver animando.
# ---------------------------------------------------------------------------

info "=== Cenário 3: spinner com Ctrl+C ==="
info "Pressione Ctrl+C durante o spinner para ver o cursor ser restaurado."

sleep 3 &
spinner "$!" "⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏" "Processando (pressione Ctrl+C para testar)..."

sucesso "Concluído. O cursor foi restaurado normalmente ao final do spinner."

# ---------------------------------------------------------------------------
# Saída normal — os handlers registrados e não cancelados rodam aqui via
# trap EXIT instalado por sinais.sh
# ---------------------------------------------------------------------------

sucesso "Script finalizado com sucesso."
