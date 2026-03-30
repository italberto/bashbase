# shellcheck shell=bash
# spinner.sh - Animações de carregamento para exibir progresso de tarefas demoradas
#
# Todas as funções recebem o PID de um processo em background e exibem
# uma animação enquanto aguardam sua conclusão.
# O cursor é ocultado durante a animação e restaurado ao final.
#
# Integração com sinais.sh: ao ser carregado, registra automaticamente
# _spinner_restaurar_cursor no stack de cleanup. Se o script for interrompido
# (Ctrl+C, kill) com um spinner ativo, o cursor é restaurado automaticamente.
#
# Dependências: sinais.sh
#
# Funções disponíveis:
#   spinner          <pid> <frames> [msg] [delay] - Spinner genérico com frames customizáveis
#   spinner_pingpong <pid> [msg] [delay]           - Animação de barra que vai e volta
#   spinner_bar      <pid> [msg] [delay]           - Barra com bloco deslizante
#
# Exemplos de frames para spinner():
#   Braille:   "⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
#   Simples:   "|\-/"
#   Círculo:   "◐◓◑◒"
#   Relógio:   "🕛🕐🕑🕒🕓🕔🕕🕖🕗🕘🕙🕚"


[[ -n "${_SPINNER_SH_LOADED:-}" ]] && return 0
readonly _SPINNER_SH_LOADED=1

source "$(dirname "${BASH_SOURCE[0]}")/sinais.sh"

# Flag global: 1 enquanto qualquer spinner estiver com o cursor oculto
_SPINNER__CURSOR_OCULTO=0

function spinner_ocultar_cursor() {
    # Oculta o cursor do terminal e marca o estado interno.
    # Use esta função em vez de chamar tput diretamente para manter
    # o estado consistente com o stack de cleanup de sinais.sh.
    tput civis 2>/dev/null
    _SPINNER__CURSOR_OCULTO=1
}

function spinner_mostrar_cursor() {
    # Restaura o cursor do terminal e limpa o estado interno.
    # Use esta função em vez de chamar tput diretamente.
    tput cnorm 2>/dev/null
    _SPINNER__CURSOR_OCULTO=0
}

function _spinner_restaurar_cursor() {
    # Restaura o cursor do terminal se ele foi ocultado por um spinner.
    # Chamada automaticamente pelo stack de cleanup de sinais.sh
    # em caso de interrupção (Ctrl+C, kill, erro não tratado).
    if [ "$_SPINNER__CURSOR_OCULTO" -eq 1 ]; then
        spinner_mostrar_cursor
    fi
}

# Registra a restauração do cursor no stack de cleanup global
registrar_cleanup "_spinner_restaurar_cursor"

function spinner() {
    # Exibe uma animação de spinner genérico enquanto um processo está em execução.
    # Os frames de animação são definidos como uma string de caracteres,
    # onde cada caractere representa um quadro da animação.
    # Aguarda o processo internamente via wait e retorna o exit code dele.
    # Exibe [✓] em caso de sucesso ou [✗] em caso de falha.
    # Modo de uso:
    #   my_comando &
    #   spinner "$!" "⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏" "baixando..."
    #   # o wait já foi feito pelo spinner; use $? para checar o resultado
    local pid="$1"
    local frames="$2"
    local msg="${3:-trabalhando...}"
    local delay="${4:-0.1}"

    local i=0 len=${#frames}

    spinner_ocultar_cursor

    while kill -0 "$pid" 2>/dev/null; do
        printf '\r[%s] %s' "${frames:i:1}" "$msg"
        i=$(( (i + 1) % len ))
        sleep "$delay"
    done

    wait "$pid"
    local status=$?

    if [ "$status" -eq 0 ]; then
        printf '\r[✓] concluído!%*s\n' 20 ""
    else
        printf '\r[✗] falhou (código %s).%*s\n' "$status" 15 ""
    fi

    spinner_mostrar_cursor
    return "$status"
}

function spinner_pingpong() {
    # Exibe uma animação de barra vertical que cresce e diminui (efeito ping-pong)
    # enquanto um processo está em execução.
    # Aguarda o processo internamente via wait e retorna o exit code dele.
    # Exibe [✓] em caso de sucesso ou [✗] em caso de falha.
    # Modo de uso:
    #   my_comando &
    #   spinner_pingpong "$!" "processando..."
    #   # o wait já foi feito pelo spinner; use $? para checar o resultado
    local pid="$1"
    local msg="${2:-trabalhando...}"
    local delay="${3:-0.07}"
    local frames=( "▁" "▂" "▃" "▄" "▅" "▆" "▇" "█" "▇" "▆" "▅" "▄" "▃" "▂" )
    local i=0

    spinner_ocultar_cursor
    while kill -0 "$pid" 2>/dev/null; do
        printf '\r[%s] %s' "${frames[i]}" "$msg"
        i=$(( (i + 1) % ${#frames[@]} ))
        sleep "$delay"
    done

    wait "$pid"
    local status=$?

    if [ "$status" -eq 0 ]; then
        printf '\r[✓] concluído!%*s\n' 20 ""
    else
        printf '\r[✗] falhou (código %s).%*s\n' "$status" 15 ""
    fi

    spinner_mostrar_cursor
    return "$status"
}

function spinner_bar() {
    # Exibe uma barra horizontal com um bloco deslizante que vai e volta
    # enquanto um processo está em execução.
    # Aguarda o processo internamente via wait e retorna o exit code dele.
    # Exibe [✓] em caso de sucesso ou [✗] em caso de falha.
    # Modo de uso:
    #   my_comando &
    #   spinner_bar "$!" "carregando..."
    #   # o wait já foi feito pelo spinner; use $? para checar o resultado
    local pid="$1"
    local msg="${2:-trabalhando...}"
    local delay="${3:-0.05}"
    local width=10
    local pos=0 dir=1

    spinner_ocultar_cursor
    while kill -0 "$pid" 2>/dev/null; do
        local bar
        bar=$(printf "%*s" "$width" "")
        bar="${bar// /-}"
        bar="${bar:0:pos}█${bar:pos+1}"
        printf '\r[%s] %s' "$bar" "$msg"

        pos=$((pos + dir))
        if (( pos <= 0 )); then dir=1; pos=0; fi
        if (( pos >= width-1 )); then dir=-1; pos=$((width-1)); fi

        sleep "$delay"
    done

    wait "$pid"
    local status=$?

    if [ "$status" -eq 0 ]; then
        printf '\r[✓] concluído!%*s\n' 20 ""
    else
        printf '\r[✗] falhou (código %s).%*s\n' "$status" 15 ""
    fi

    spinner_mostrar_cursor
    return "$status"
}
