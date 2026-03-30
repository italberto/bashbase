#!/bin/bash

set -euo pipefail

[[ -n "${_INPUTS_SH_LOADED:-}" ]] && return 0
readonly _INPUTS_SH_LOADED=1

# checa se a variavel bashbase está definida, se não exiter avisa e sai do programa
if [ -z "$BASHBASE" ]; then
    echo -e "Variável BASHBASE não definida."
    exit 1
fi

source $BASHBASE/lib/logu.sh
source $BASHBASE/lib/alerta.sh
source $BASHBASE/lib/diru.sh
source $BASHBASE/lib/systemu.sh

log_set_arquivo "$BASHBASE/logs/exemplo.log"
log_set_nivel 1

log_info "Iniciando o script de exemplo."

contagem=$(count_files_in_directory "/etc/")

info "O diretório /etc/ contém $contagem arquivos."

log_info "Script finalizado."
sys_finaliza_ok