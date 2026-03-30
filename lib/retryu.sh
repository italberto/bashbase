# shellcheck shell=bash
# retryu.sh - Funções para execução resiliente de comandos com retry automático
#
# Útil para operações instáveis como chamadas de rede, acesso a serviços externos
# ou qualquer comando que possa falhar transitoriamente.
#
# Dependências: spinner.sh
#
# Funções disponíveis:
#   tentar                 <tentativas> <delay> <comando...> - Retry com delay fixo
#   tentar_com_backoff     <tentativas> <delay> <comando...> - Retry com espera exponencial
#   tentar_spinner         <tentativas> <delay> <comando...> - Retry com delay fixo e spinner
#   tentar_backoff_spinner <tentativas> <delay> <comando...> - Retry com backoff exponencial e spinner


[[ -n "${_RETRYU_SH_LOADED:-}" ]] && return 0
readonly _RETRYU_SH_LOADED=1

source "$(dirname "${BASH_SOURCE[0]}")/spinner.sh"

function tentar() {
    # Executa um comando até N vezes, aguardando um intervalo fixo entre tentativas.
    # Retorna 0 na primeira execução bem-sucedida.
    # Retorna 1 se todas as tentativas falharem.
    # Modo de uso: tentar 3 5 curl -s https://exemplo.com
    #   $1 = número máximo de tentativas
    #   $2 = segundos de espera entre tentativas
    #   $@ = comando a executar
    local tentativas="$1"
    local delay="$2"
    shift 2

    local i=1
    while [ "$i" -le "$tentativas" ]; do
        "$@" && return 0
        echo "Tentativa $i/$tentativas falhou. Aguardando ${delay}s..." >&2
        sleep "$delay"
        (( i++ ))
    done

    echo "Todas as $tentativas tentativas falharam: $*" >&2
    return 1
}

function tentar_com_backoff() {
    # Executa um comando até N vezes com espera exponencial entre tentativas.
    # A cada falha, o tempo de espera dobra: delay, 2*delay, 4*delay, etc.
    # Ideal para evitar sobrecarga em serviços que estão se recuperando.
    # Retorna 0 na primeira execução bem-sucedida.
    # Retorna 1 se todas as tentativas falharem.
    # Modo de uso: tentar_com_backoff 4 2 wget -q https://exemplo.com
    #   $1 = número máximo de tentativas
    #   $2 = delay inicial em segundos (dobra a cada falha)
    #   $@ = comando a executar
    local tentativas="$1"
    local delay="$2"
    shift 2

    local i=1
    while [ "$i" -le "$tentativas" ]; do
        "$@" && return 0
        echo "Tentativa $i/$tentativas falhou. Aguardando ${delay}s (backoff exponencial)..." >&2
        sleep "$delay"
        delay=$(( delay * 2 ))
        (( i++ ))
    done

    echo "Todas as $tentativas tentativas falharam: $*" >&2
    return 1
}

function tentar_spinner() {
    # Executa um comando até N vezes com delay fixo entre tentativas,
    # exibindo um spinner durante a execução do comando e durante a espera.
    # A saída do comando é descartada para não quebrar o layout do spinner.
    # Retorna 0 na primeira execução bem-sucedida, 1 se todas as tentativas falharem.
    # Modo de uso: tentar_spinner 3 5 curl -s https://exemplo.com
    #   $1 = número máximo de tentativas
    #   $2 = segundos de espera entre tentativas
    #   $@ = comando a executar
    local tentativas="$1"
    local delay="$2"
    shift 2
    local frames="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    local len=${#frames} f pid status i=1

    spinner_ocultar_cursor
    while [ "$i" -le "$tentativas" ]; do
        "$@" &>/dev/null &
        local pid=$!; f=0
        while kill -0 "$pid" 2>/dev/null; do
            printf '\r[%s] Tentativa %s/%s: %s' "${frames:f:1}" "$i" "$tentativas" "$*"
            f=$(( (f + 1) % len ))
            sleep 0.1
        done
        wait "$pid"; status=$?

        if [ "$status" -eq 0 ]; then
            printf '\r[✓] Concluído na tentativa %s/%s.%*s\n' "$i" "$tentativas" 20 ""
            spinner_mostrar_cursor
            return 0
        fi

        printf '\r[✗] Tentativa %s/%s falhou.%*s\n' "$i" "$tentativas" 20 ""

        if [ "$i" -lt "$tentativas" ]; then
            sleep "$delay" &
            pid=$!; f=0
            while kill -0 "$pid" 2>/dev/null; do
                printf '\r[%s] Aguardando %ss antes da próxima tentativa...' "${frames:f:1}" "$delay"
                f=$(( (f + 1) % len ))
                sleep 0.1
            done
            wait "$pid"
            printf '\r%*s\r' 60 ""
        fi

        (( i++ ))
    done

    printf 'Todas as %s tentativas falharam: %s\n' "$tentativas" "$*"
    spinner_mostrar_cursor
    return 1
}

function tentar_backoff_spinner() {
    # Executa um comando até N vezes com espera exponencial entre tentativas,
    # exibindo um spinner durante a execução do comando e durante a espera.
    # A cada falha o tempo de espera dobra: delay, 2*delay, 4*delay, etc.
    # A saída do comando é descartada para não quebrar o layout do spinner.
    # Retorna 0 na primeira execução bem-sucedida, 1 se todas as tentativas falharem.
    # Modo de uso: tentar_backoff_spinner 4 2 wget -q https://exemplo.com
    #   $1 = número máximo de tentativas
    #   $2 = delay inicial em segundos (dobra a cada falha)
    #   $@ = comando a executar
    local tentativas="$1"
    local delay="$2"
    shift 2
    local frames="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    local len=${#frames} f pid status i=1

    spinner_ocultar_cursor
    while [ "$i" -le "$tentativas" ]; do
        "$@" &>/dev/null &
        local pid=$!; f=0
        while kill -0 "$pid" 2>/dev/null; do
            printf '\r[%s] Tentativa %s/%s: %s' "${frames:f:1}" "$i" "$tentativas" "$*"
            f=$(( (f + 1) % len ))
            sleep 0.1
        done
        wait "$pid"; status=$?

        if [ "$status" -eq 0 ]; then
            printf '\r[✓] Concluído na tentativa %s/%s.%*s\n' "$i" "$tentativas" 20 ""
            spinner_mostrar_cursor
            return 0
        fi

        printf '\r[✗] Tentativa %s/%s falhou.%*s\n' "$i" "$tentativas" 20 ""

        if [ "$i" -lt "$tentativas" ]; then
            sleep "$delay" &
            pid=$!; f=0
            while kill -0 "$pid" 2>/dev/null; do
                printf '\r[%s] Aguardando %ss (backoff exponencial)...' "${frames:f:1}" "$delay"
                f=$(( (f + 1) % len ))
                sleep 0.1
            done
            wait "$pid"
            printf '\r%*s\r' 60 ""
            delay=$(( delay * 2 ))
        fi

        (( i++ ))
    done

    printf 'Todas as %s tentativas falharam: %s\n' "$tentativas" "$*"
    spinner_mostrar_cursor
    return 1
}
