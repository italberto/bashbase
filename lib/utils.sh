# shellcheck shell=bash
# utils.sh - Funções utilitárias para manipulação de strings e extração de campos
#
# Fornece operações básicas sobre strings que não estão disponíveis
# nativamente no Bash de forma conveniente, além de wrappers awk para
# extração e soma de campos em fluxos de texto.
# As implementações de string usam apenas recursos nativos do Bash,
# sem dependências de ferramentas externas.
#
# Dependências: nenhuma
#
# Funções disponíveis:
#   concatena        <elementos...> <delimitador> - Une elementos com um delimitador
#   separa           <string> [delimitador]       - Divide uma string em elementos
#   trim             <string>                     - Remove espaços nas duas extremidades
#   maiusculas       <string>                     - Converte para maiúsculas
#   minusculas       <string>                     - Converte para minúsculas
#   comeca_com       <string> <prefixo>           - Retorna 0 se string começa com prefixo
#   termina_com      <string> <sufixo>            - Retorna 0 se string termina com sufixo
#   contem           <string> <substring>         - Retorna 0 se string contém substring
#   preenche_esquerda <string> <largura> [char]   - Alinha à direita preenchendo à esquerda
#   preenche_direita  <string> <largura> [char]   - Alinha à esquerda preenchendo à direita
#   repete           <string> <n>                 - Repete a string N vezes
#   campo            <num> [delimitador]          - Extrai campo N de stdin usando awk
#   total            <num> [delimitador]          - Soma campo N de todas as linhas do stdin


[[ -n "${_UTILS_SH_LOADED:-}" ]] && return 0
readonly _UTILS_SH_LOADED=1

function utils_concatena() {
    # Concatena elementos usando um delimitador, com suporte correto a argumentos opcionais.
    # O delimitador é sempre o PRIMEIRO argumento, followed by elementos variáveis.
    # Se nenhum elemento for fornecido, retorna vazio. Se nenhum delimitador, usa espaço.
    # Modo de uso: utils_concatena "," "a" "b" "c"    → "a,b,c"
    #              utils_concatena "-" "foo" "bar"     → "foo-bar"
    #              utils_concatena " " "x" "y"         → "x y"
    local delimiter="${1:- }"
    shift
    
    local result=""
    for item in "$@"; do
        [[ -n "$result" ]] && result+="$delimiter"
        result+="$item"
    done
    echo "$result"
}

function separa() {
    # Divide uma string em elementos usando o delimitador informado.
    # Se nenhum delimitador for fornecido, usa espaço como padrão.
    # Os elementos resultantes são impressos separados por espaço.
    # Modo de uso: separa "a,b,c" ","    → a b c
    #              separa "foo bar baz"  → foo bar baz
    local string="$1"

    if [ -n "$2" ]; then
        local delimiter="$2"
    else
        local delimiter=" "
    fi

    IFS="$delimiter" read -ra result <<< "$string"
    echo "${result[@]}"
}

function trim() {
    # Remove espaços (e outros whitespace) do início e do fim da string.
    # Usa apenas expansão de parâmetros do Bash, sem ferramentas externas.
    # Modo de uso: trim "  olá mundo  "   → "olá mundo"
    #              nome=$(trim "$nome")
    local string="$1"
    # Remove whitespace do início
    string="${string#"${string%%[![:space:]]*}"}"
    # Remove whitespace do fim
    string="${string%"${string##*[![:space:]]}"}"
    echo "$string"
}

function maiusculas() {
    # Converte todos os caracteres da string para maiúsculas.
    # Modo de uso: maiusculas "hello world"   → "HELLO WORLD"
    echo "${1^^}"
}

function minusculas() {
    # Converte todos os caracteres da string para minúsculas.
    # Modo de uso: minusculas "HELLO WORLD"   → "hello world"
    echo "${1,,}"
}

function comeca_com() {
    # Retorna 0 se a string começa com o prefixo informado, 1 caso contrário.
    # Modo de uso: comeca_com "arquivo.log" "arquivo"  → 0 (verdadeiro)
    #              comeca_com "arquivo.log" "log"       → 1 (falso)
    [[ "$1" == "$2"* ]]
}

function termina_com() {
    # Retorna 0 se a string termina com o sufixo informado, 1 caso contrário.
    # Modo de uso: termina_com "arquivo.log" ".log"   → 0 (verdadeiro)
    #              termina_com "arquivo.log" ".txt"   → 1 (falso)
    [[ "$1" == *"$2" ]]
}

function contem() {
    # Retorna 0 se a string contém a substring informada, 1 caso contrário.
    # Modo de uso: contem "erro crítico no sistema" "crítico"   → 0 (verdadeiro)
    #              contem "erro crítico no sistema" "aviso"     → 1 (falso)
    [[ "$1" == *"$2"* ]]
}

function preenche_esquerda() {
    # Preenche a string à esquerda até atingir a largura desejada (alinha à direita).
    # O caractere de preenchimento padrão é espaço.
    # Se a string já for maior ou igual à largura, retorna a string sem alteração.
    # Modo de uso: preenche_esquerda "42" 6        → "    42"
    #              preenche_esquerda "42" 6 "0"    → "000042"
    local string="$1"
    local largura="$2"
    local caractere="${3:- }"
    local pad=$(( largura - ${#string} ))

    if [ "$pad" -le 0 ]; then
        echo "$string"
        return
    fi

    local padding
    padding=$(printf "%${pad}s" "" | tr ' ' "$caractere")
    echo "${padding}${string}"
}

function preenche_direita() {
    # Preenche a string à direita até atingir a largura desejada (alinha à esquerda).
    # O caractere de preenchimento padrão é espaço.
    # Se a string já for maior ou igual à largura, retorna a string sem alteração.
    # Modo de uso: preenche_direita "nome" 10          → "nome      "
    #              preenche_direita "nome" 10 "-"       → "nome------"
    local string="$1"
    local largura="$2"
    local caractere="${3:- }"
    local pad=$(( largura - ${#string} ))

    if [ "$pad" -le 0 ]; then
        echo "$string"
        return
    fi

    local padding
    padding=$(printf "%${pad}s" "" | tr ' ' "$caractere")
    echo "${string}${padding}"
}

function repete() {
    # Repete a string N vezes, concatenando sem separador.
    # Modo de uso: repete "ab" 3     → "ababab"
    #              repete "-" 20     → "--------------------"
    local string="$1"
    local vezes="$2"
    local saida=""

    for (( i = 0; i < vezes; i++ )); do
        saida+="$string"
    done

    echo "$saida"
}

function campo() {
    # Extrai um campo específico de cada linha lida do stdin usando um delimitador.
    # Modo de uso: df -h | campo 5     → coluna 5 de cada linha (ex: "Use%")
    #              echo "a:b:c" | campo 2 ":"  → "b"
    awk -F "${2:- }" "{ print \$${1:-1} }"
}

function total() {
    # Soma os valores numéricos de um campo específico em todas as linhas do stdin.
    # Modo de uso: du -sb /var/log/* | total 1   → soma dos tamanhos em bytes
    #              cat vendas.csv | total 3 ","   → soma da coluna 3
    awk -F "${2:- }" "{ s += \$${1:-1} } END { print s }"
}
