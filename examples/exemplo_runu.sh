#!/bin/bash

# checa se a variavel bashbase está definida, se não exiter avisa e sai do programa

set -euo pipefail

if [ -z "$BASHBASE" ]; then
    echo -e "Variável BASHBASE não definida."
    exit 1
fi

source "$BASHBASE/lib/runu.sh"
source "$BASHBASE/lib/alerta.sh"

# Exemplo 1: Usando com um comando simples
execute "Atualizando repositórios..." "sudo apt update"

# Exemplo 2: Usando com uma função própria do seu script
minha_tarefa_pesada() {
  sleep 4
  # lógica complexa aqui
}

# Para funções, o eval funciona da mesma forma 
execute "" "minha_tarefa_pesada"

sucesso "Tudo pronto!"