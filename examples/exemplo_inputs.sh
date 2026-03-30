#!/bin/bash

set -euo pipefail

# checa se a variavel bashbase está definida, se não exiter avisa e sai do programa
if [ -z "$BASHBASE" ]; then
    echo -e "Variável BASHBASE não definida."
    exit 1
fi

source "$BASHBASE/lib/inputs.sh"

ask "Você gosta de bilola?" gosta

echo "$gosta"

ask_yes_no "Term certeza?" gosta

echo "$gosta"

ask_password "Digita tua senha aqui." senha

echo "$senha"

ask_choice "E de qual fruta tu gosta mais?" fruta "Banana" "Carambola" "Manga"

echo "$fruta"

menu_interativo "Escolha uma opção:" escolha "Instalar" "Remover" "Atualizar"                                                                                          
                                                                                                                                                                        
if [ $? -eq 0 ]; then                                                                                                                                                  
    echo "Você escolheu: $escolha"                                                                                                                                     
else                                                      
    echo "Cancelado."
fi   