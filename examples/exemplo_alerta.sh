#!/bin/bash

set -euo pipefail

# checa se a variavel bashbase está definida, se não exiter avisa e sai do programa
if [ -z "$BASHBASE" ]; then
    echo -e "Variável BASHBASE não definida."
    exit 1
fi

source "$BASHBASE/lib/alerta.sh"
source "$BASHBASE/lib/systemu.sh"

alerta "Verificando se o usuário é root..." 

if sys_e_root; then
    sucesso "Você é root!" 1
    exit 0
else
    erro "Você não é root!" 1
    exit 1
fi