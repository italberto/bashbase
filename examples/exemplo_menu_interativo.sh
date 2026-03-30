#!/bin/bash

set -euo pipefail

# checa se a variavel bashbase está definida, se não exiter avisa e sai do programa
if [ -z "$BASHBASE" ]; then
    echo -e "Variável BASHBASE não definida."
    exit 1
fi

source $BASHBASE/lib/inputs.sh                                                                                                                                                     
                                                                                                                                                                         
  menu_interativo "Escolha uma opção:" escolha "Instalar" "Remover" "Atualizar"                                                                                          
                                                                                                                                                                         
  if [ $? -eq 0 ]; then                                                                                                                                                  
      echo "Você escolheu: $escolha"                                                                                                                                     
  else                                                      
      echo "Cancelado."
  fi      