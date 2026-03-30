# shellcheck shell=bash
# inputs.sh - Funções para coleta e validação de dados inseridos pelo usuário
#
# Fornece wrappers interativos para os tipos mais comuns de entrada,
# com validação automática e suporte a menus navegáveis pelo teclado.
# Os valores coletados são armazenados em variáveis passadas por nome,
# seguindo o padrão de passagem por referência do Bash com printf -v.
#
# As funções pergunta_ip, pergunta_email, pergunta_url e pergunta_porta
# delegam a validação para validau.sh, evitando duplicação de lógica.
#
# Dependências: validau.sh, sinais.sh
#
# Funções disponíveis:
#   pergunta            <pergunta> <var>                    - Lê uma linha de texto livre
#   pergunta_sim_nao    <pergunta> <var>                    - Lê resposta s/n, armazena "1" (sim) ou "" (não)
#   pergunta_senha      <pergunta> <var>                    - Lê senha sem ecoar no terminal
#   pergunta_numero     <pergunta> <var> [min] [max]        - Lê número inteiro com validação de range
#   pergunta_ip         <pergunta> <var>                    - Lê e valida endereço IPv4
#   pergunta_email      <pergunta> <var>                    - Lê e valida endereço de e-mail
#   pergunta_url        <pergunta> <var>                    - Lê e valida URL (http/https/ftp)
#   pergunta_porta      <pergunta> <var>                    - Lê e valida número de porta (1-65535)
#   pergunta_escolha    <pergunta> <var> <op1> <op2> ...    - Menu numerado com select do Bash
#   menu_interativo     <título>   <var> <op1> <op2> ...    - Menu navegável com setas e Enter/ESC
#   barra_de_progresso  <atual> <total> [largura] [msg]     - Barra de progresso em linha


[[ -n "${_INPUTS_SH_LOADED:-}" ]] && return 0
readonly _INPUTS_SH_LOADED=1

source "$(dirname "${BASH_SOURCE[0]}")/validau.sh"
source "$(dirname "${BASH_SOURCE[0]}")/sinais.sh"

function pergunta() {
    # Modo de uso: pergunta"Pergunta" variavel
    local pergunta="$1"
    local __resultvar="$2"
    
    local resposta
    read -r -p "$pergunta: " resposta
    printf -v "$__resultvar" '%s' "$resposta"
}

function pergunta_sim_nao() {
    # Modo de uso: pergunta_sim_nao "Pergunta" variavel
    local pergunta="$1"
    local __resultvar="$2"

    local resposta
    while true; do
        read -r -p "$pergunta (s/n): " resposta
        case "$resposta" in
            [Ss]* ) printf -v "$__resultvar" '%s' "1"; return 0;;
            [Nn]* ) printf -v "$__resultvar" '%s' ""; return 0;;
            * ) echo "Por favor, responda com 's' para sim ou 'n' para não.";;
        esac
    done
}

function pergunta_senha() {
    # Modo de uso: pergunta_senha "Pergunta" variavel
    local pergunta="$1"
    local __resultvar="$2"
    
    local resposta
    read -r -s -p "$pergunta: " resposta
    echo
    printf -v "$__resultvar" '%s' "$resposta"
}

function pergunta_numero() {
    # Lê um número inteiro positivo do terminal com validação de range opcional.
    # Modo de uso: pergunta_numero "Pergunta" variavel
    #              pergunta_numero "Pergunta" variavel 1 100   (aceita apenas 1-100)
    #              pergunta_numero "Pergunta" variavel 0       (aceita apenas >= 0)
    local pergunta="$1"
    local __resultvar="$2"
    local min="${3:-}"
    local max="${4:-}"

    local hint=""
    if [ -n "$min" ] && [ -n "$max" ]; then
        hint=" ($min-$max)"
    elif [ -n "$min" ]; then
        hint=" (mínimo: $min)"
    elif [ -n "$max" ]; then
        hint=" (máximo: $max)"
    fi

    local resposta
    while true; do
        read -r -p "$pergunta${hint}: " resposta
        if [[ ! "$resposta" =~ ^[0-9]+$ ]]; then
            echo "Por favor, insira um número inteiro válido."
            continue
        fi
        if [ -n "$min" ] && [ "$resposta" -lt "$min" ]; then
            echo "O valor deve ser maior ou igual a $min."
            continue
        fi
        if [ -n "$max" ] && [ "$resposta" -gt "$max" ]; then
            echo "O valor deve ser menor ou igual a $max."
            continue
        fi
        printf -v "$__resultvar" '%s' "$resposta"
        return 0
    done
}

function pergunta_ip() {
    # Lê um endereço IPv4 do terminal, repetindo até que um valor válido seja informado.
    # A validação é delegada para valida_ip de validau.sh.
    # Modo de uso: pergunta_ip "IP do servidor" ip_var
    local pergunta="$1"
    local __resultvar="$2"

    local resposta
    while true; do
        read -r -p "$pergunta: " resposta
        if valida_ip "$resposta"; then
            printf -v "$__resultvar" '%s' "$resposta"
            return 0
        fi
        echo "Endereço IP inválido. Use o formato A.B.C.D com octetos entre 0 e 255 (ex: 192.168.1.1)."
    done
}

function pergunta_email() {
    # Lê um endereço de e-mail do terminal, repetindo até que um valor válido seja informado.
    # A validação é delegada para valida_email de validau.sh.
    # Modo de uso: pergunta_email "E-mail do usuário" email_var
    local pergunta="$1"
    local __resultvar="$2"

    local resposta
    while true; do
        read -r -p "$pergunta: " resposta
        if valida_email "$resposta"; then
            printf -v "$__resultvar" '%s' "$resposta"
            return 0
        fi
        echo "Endereço de e-mail inválido. Use o formato usuario@dominio.com."
    done
}

function pergunta_url() {
    # Lê uma URL do terminal, repetindo até que um valor válido seja informado.
    # Aceita esquemas http://, https:// e ftp://.
    # A validação é delegada para valida_url de validau.sh.
    # Modo de uso: pergunta_url "Endereço do servidor" url_var
    local pergunta="$1"
    local __resultvar="$2"

    local resposta
    while true; do
        read -r -p "$pergunta: " resposta
        if valida_url "$resposta"; then
            printf -v "$__resultvar" '%s' "$resposta"
            return 0
        fi
        echo "URL inválida. Use http://, https:// ou ftp:// seguido do endereço (ex: https://exemplo.com)."
    done
}

function pergunta_porta() {
    # Lê um número de porta TCP/UDP do terminal, repetindo até que um valor válido seja informado.
    # Aceita valores entre 1 e 65535.
    # A validação é delegada para valida_porta de validau.sh.
    # Modo de uso: pergunta_porta "Porta do serviço" porta_var
    local pergunta="$1"
    local __resultvar="$2"

    local resposta
    while true; do
        read -r -p "$pergunta (1-65535): " resposta
        if valida_porta "$resposta"; then
            printf -v "$__resultvar" '%s' "$resposta"
            return 0
        fi
        echo "Porta inválida. Informe um número inteiro entre 1 e 65535."
    done
}

function pergunta_escolha() {
    # Modo de uso: pergunta_escolha "Pergunta" variavel "Opção 1" "Opção 2" ...
    local pergunta="$1"
    local __resultvar="$2"
    shift 2
    local options=("$@")

    echo "$pergunta"
    select opt in "${options[@]}"; do
        if [[ -n "$opt" ]]; then
            printf -v "$__resultvar" '%s' "$opt"
            return 0
        else
            echo "Opção inválida. Por favor, tente novamente."
        fi
    done
}

function menu_interativo() {
    # Modo de uso: menu_interativo "Título" variavel "Opção 1" "Opção 2" ...
    # Retorna 0 e preenche variavel com a opção escolhida, ou retorna 1 se cancelado com ESC.
    local titulo="$1"
    local __resultvar="$2"
    shift 2
    local opcoes=("$@")
    local total=${#opcoes[@]}
    local selecionado=0

    if [ "$total" -eq 0 ]; then
        echo "Nenhuma opção fornecida."
        return 1
    fi

    _menu_renderizar() {
        local i
        for i in "${!opcoes[@]}"; do
            if [ "$i" -eq "$selecionado" ]; then
                printf "\r\e[K  \e[7m %s \e[0m\n" "${opcoes[$i]}"
            else
                printf "\r\e[K    %s\n" "${opcoes[$i]}"
            fi
        done
    }

    tput civis 2>/dev/null
    registrar_cleanup "tput cnorm 2>/dev/null"
    echo "$titulo"
    _menu_renderizar

    local tecla tecla2 tecla3
    while true; do
        tput cuu "$total"
        _menu_renderizar

        IFS= read -r -s -n1 tecla

        if [[ "$tecla" == $'\x1b' ]]; then
            IFS= read -r -s -n1 -t 0.1 tecla2
            if [[ "$tecla2" == '[' ]]; then
                IFS= read -r -s -n1 -t 0.1 tecla3
                case "$tecla3" in
                    A) (( selecionado > 0 )) && (( selecionado-- )) ;;
                    B) (( selecionado < total - 1 )) && (( selecionado++ )) ;;
                esac
            else
                tput cnorm 2>/dev/null
                cancelar_cleanup "tput cnorm 2>/dev/null"
                echo
                unset -f _menu_renderizar
                return 1
            fi
        elif [[ "$tecla" == '' ]]; then
            tput cnorm
            cancelar_cleanup "tput cnorm 2>/dev/null"
            echo
            printf -v "$__resultvar" '%s' "${opcoes[$selecionado]}"
            unset -f _menu_renderizar
            return 0
        fi
    done
}

function barra_de_progresso() {
    # Exibe uma barra de progresso em linha no terminal, atualizando em tempo real
    # via retorno de carro (\r) sem adicionar novas linhas.
    # Ao atingir 100%, imprime uma quebra de linha para liberar o terminal.
    # Ideal para operações com total de itens conhecido (ex: loops, cópias de arquivos).
    # Modo de uso: barra_de_progresso <atual> <total> [largura] [mensagem]
    #   Dentro de um loop:
    #     for i in $(seq 1 100); do
    #         barra_de_progresso $i 100 40 "Processando..."
    #         sleep 0.05
    #     done
    local atual="$1"
    local total="$2"
    local largura="${3:-40}"
    local mensagem="${4:-}"

    if [ "$total" -eq 0 ]; then return; fi

    local percentual=$(( atual * 100 / total ))
    local preenchido=$(( atual * largura / total ))
    local vazio=$(( largura - preenchido ))

    # Monta a barra: blocos preenchidos (█) e vazios (░)
    local barra
    barra=$(printf '%*s' "$preenchido" '' | tr ' ' '█')
    barra+=$(printf '%*s' "$vazio" '' | tr ' ' '░')

    printf '\r[%s] %3d%% %s' "$barra" "$percentual" "$mensagem"

    # Quebra de linha ao completar
    if [ "$atual" -eq "$total" ]; then
        echo
    fi
}