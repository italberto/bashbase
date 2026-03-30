# shellcheck shell=bash
# paralelo.sh - Execução concorrente de comandos com controle de concorrência e cleanup garantido
#
# Permite disparar múltiplos comandos em paralelo com coleta de resultados,
# limite de jobs simultâneos e timeout global. A saída de cada job é
# bufferizada em arquivo temporário e exibida em ordem ao final, evitando
# interleaving. Os processos filhos são registrados no stack de sinais.sh
# para garantir encerramento em caso de interrupção (Ctrl+C, SIGTERM, etc.).
#
# Requer bash 4.3+ para paralelo_pool e paralelo_com_timeout (usa wait -n).
#
# Quando DRYRUN="1", nenhum comando é executado: as funções listam no stderr
# os jobs que seriam disparados e retornam 0.
#
# Dependências: sinais.sh, dryrun.sh
#
# Variáveis internas (não usar diretamente):
#   _PARALELO__PIDS      - Array de PIDs dos jobs em andamento
#   _PARALELO__TEMP_DIR  - Diretório temporário para buffers de saída
#
# Funções disponíveis:
#   paralelo_executar      <cmd1> [cmd2...]                    - Fan-out/fan-in sem limite
#   paralelo_map           <concorrencia> <cmd> <arg1> [arg2...] - Mesmo cmd para N argumentos
#   paralelo_pool          <concorrencia> <cmd1> [cmd2...]     - Pool com limite de jobs simultâneos
#   paralelo_com_timeout   <segundos> <cmd1> [cmd2...]         - Pool com timeout global


[[ -n "${_PARALELO_SH_LOADED:-}" ]] && return 0
readonly _PARALELO_SH_LOADED=1

source "$(dirname "${BASH_SOURCE[0]}")/sinais.sh"
source "$(dirname "${BASH_SOURCE[0]}")/dryrun.sh"

_PARALELO__PIDS=()
_PARALELO__TEMP_DIR=""

# ---------------------------------------------------------------------------
# Funções internas
# ---------------------------------------------------------------------------

function _paralelo_init() {
    # Cria diretório temporário para buffers de saída e registra cleanup.
    _PARALELO__PIDS=()
    _PARALELO__TEMP_DIR=$(mktemp -d)
    registrar_cleanup "_paralelo_limpar"
}

function _paralelo_limpar() {
    # Encerra todos os jobs rastreados e remove o diretório temporário.
    # Chamada automaticamente pelo stack de sinais.sh em caso de interrupção.
    local pid
    for pid in "${_PARALELO__PIDS[@]:-}"; do
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null
            sleep 0.2
            kill -0 "$pid" 2>/dev/null && kill -9 "$pid" 2>/dev/null
        fi
    done
    [[ -n "$_PARALELO__TEMP_DIR" && -d "$_PARALELO__TEMP_DIR" ]] && rm -rf "$_PARALELO__TEMP_DIR"
    _PARALELO__PIDS=()
    _PARALELO__TEMP_DIR=""
}

function _paralelo_exibir_resultados() {
    # Exibe o output bufferizado de cada job com cabeçalho de status.
    # Parâmetros: array de comandos e array de exit codes (via indireto).
    local -n _cmds="$1"
    local -n _codes="$2"
    local i

    echo ""
    for i in "${!_cmds[@]}"; do
        local status="${_codes[$i]:-1}"
        local icone label
        if [[ "$status" -eq 0 ]]; then
            icone="✓"; label="\e[32m[job $((i+1)) ✓]\e[0m"
        else
            icone="✗"; label="\e[31m[job $((i+1)) ✗ código ${status}]\e[0m"
        fi

        printf "${label} %s\n" "${_cmds[$i]}"

        local out="$_PARALELO__TEMP_DIR/job_${i}.out"
        if [[ -s "$out" ]]; then
            sed 's/^/  /' "$out"
        fi
    done
}

# ---------------------------------------------------------------------------
# Funções públicas
# ---------------------------------------------------------------------------

function paralelo_executar() {
    # Dispara todos os comandos em paralelo e aguarda todos terminarem.
    # A saída de cada job é bufferizada e exibida em ordem ao final.
    # Retorna 0 somente se todos os jobs tiverem sucesso.
    # Modo de uso:
    #   paralelo_executar \
    #     "rsync -av src/ srv1:/dst/" \
    #     "rsync -av src/ srv2:/dst/"
    local cmds=("$@")

    if [[ ${#cmds[@]} -eq 0 ]]; then
        echo "paralelo_executar: nenhum comando informado" >&2
        return 1
    fi

    if dryrun_ativo; then
        echo "[DRY-RUN] paralelo_executar: ${#cmds[@]} jobs seriam executados em paralelo" >&2
        local i
        for i in "${!cmds[@]}"; do
            echo "[DRY-RUN]   job $((i+1)): ${cmds[$i]}" >&2
        done
        return 0
    fi

    _paralelo_init

    local i
    for i in "${!cmds[@]}"; do
        eval "${cmds[$i]}" > "$_PARALELO__TEMP_DIR/job_${i}.out" 2>&1 &
        _PARALELO__PIDS+=($!)
    done

    local exit_codes=() falhas=0
    for i in "${!_PARALELO__PIDS[@]}"; do
        wait "${_PARALELO__PIDS[$i]}"
        exit_codes[$i]=$?
        [[ "${exit_codes[$i]}" -ne 0 ]] && (( falhas++ ))
    done

    _paralelo_exibir_resultados cmds exit_codes

    cancelar_cleanup "_paralelo_limpar"
    _paralelo_limpar

    [[ "$falhas" -eq 0 ]]
}

function paralelo_map() {
    # Aplica o mesmo comando base a cada argumento em paralelo,
    # com limite de concorrência. Equivalente a xargs -P, mas nativo.
    # Retorna 0 somente se todos os jobs tiverem sucesso.
    # Modo de uso:
    #   paralelo_map 4 "gzip -9" arq1.log arq2.log arq3.log arq4.log arq5.log
    #   $1 = número máximo de jobs simultâneos
    #   $2 = comando base (os argumentos são acrescentados ao final)
    #   $@ = argumentos a processar
    local concorrencia="$1"
    local cmd_base="$2"
    shift 2

    if [[ $# -eq 0 ]]; then
        echo "paralelo_map: nenhum argumento informado" >&2
        return 1
    fi

    local cmds=()
    local arg
    for arg in "$@"; do
        cmds+=("${cmd_base} ${arg}")
    done

    if dryrun_ativo; then
        echo "[DRY-RUN] paralelo_map: ${#cmds[@]} jobs (concorrência: ${concorrencia})" >&2
        local i
        for i in "${!cmds[@]}"; do
            echo "[DRY-RUN]   job $((i+1)): ${cmds[$i]}" >&2
        done
        return 0
    fi

    paralelo_pool "$concorrencia" "${cmds[@]}"
}

function paralelo_pool() {
    # Executa os comandos com no máximo <concorrencia> jobs simultâneos.
    # Quando um job termina, o próximo da fila é iniciado imediatamente.
    # Usa wait -n (bash 4.3+) para aguardar o próximo job disponível.
    # Retorna 0 somente se todos os jobs tiverem sucesso.
    # Modo de uso:
    #   paralelo_pool 3 "build modulo_a" "build modulo_b" "build modulo_c" "build modulo_d"
    #   $1 = número máximo de jobs simultâneos
    #   $@ = comandos a executar
    local concorrencia="$1"
    shift
    local cmds=("$@")

    if [[ ${#cmds[@]} -eq 0 ]]; then
        echo "paralelo_pool: nenhum comando informado" >&2
        return 1
    fi

    if dryrun_ativo; then
        echo "[DRY-RUN] paralelo_pool: ${#cmds[@]} jobs (concorrência: ${concorrencia})" >&2
        local i
        for i in "${!cmds[@]}"; do
            echo "[DRY-RUN]   job $((i+1)): ${cmds[$i]}" >&2
        done
        return 0
    fi

    _paralelo_init

    local exit_codes=()
    local fila_idx=0        # próximo comando a despachar
    local ativos=0          # jobs rodando agora
    local pid_para_idx=()   # mapeamento PID → índice do comando

    # Inicia até <concorrencia> jobs da fila
    while [[ "$fila_idx" -lt "${#cmds[@]}" || "$ativos" -gt 0 ]]; do

        # Encher o pool até o limite
        while [[ "$fila_idx" -lt "${#cmds[@]}" && "$ativos" -lt "$concorrencia" ]]; do
            eval "${cmds[$fila_idx]}" > "$_PARALELO__TEMP_DIR/job_${fila_idx}.out" 2>&1 &
            local pid=$!
            _PARALELO__PIDS+=("$pid")
            pid_para_idx[$pid]=$fila_idx
            (( fila_idx++ ))
            (( ativos++ ))
        done

        # Aguardar o próximo job terminar (wait -n: bash 4.3+)
        if [[ "$ativos" -gt 0 ]]; then
            local pid_concluido
            wait -n -p pid_concluido
            local status=$?
            exit_codes[${pid_para_idx[$pid_concluido]}]=$status
            (( ativos-- ))
        fi
    done

    local falhas=0
    local c
    for c in "${exit_codes[@]}"; do
        [[ "$c" -ne 0 ]] && (( falhas++ ))
    done

    _paralelo_exibir_resultados cmds exit_codes

    cancelar_cleanup "_paralelo_limpar"
    _paralelo_limpar

    [[ "$falhas" -eq 0 ]]
}

function paralelo_com_timeout() {
    # Executa os comandos em pool com limite de tempo global.
    # Se o timeout for atingido antes de todos os jobs terminarem,
    # todos os jobs ainda em execução são encerrados (SIGTERM → SIGKILL)
    # e a função retorna 124 (mesmo código de timeout(1)).
    # Modo de uso:
    #   paralelo_com_timeout 60 3 "cmd1" "cmd2" "cmd3"
    #   $1 = segundos máximos de execução total
    #   $2 = concorrência máxima
    #   $@ = comandos a executar
    local timeout_seg="$1"
    local concorrencia="$2"
    shift 2
    local cmds=("$@")

    if [[ ${#cmds[@]} -eq 0 ]]; then
        echo "paralelo_com_timeout: nenhum comando informado" >&2
        return 1
    fi

    if dryrun_ativo; then
        echo "[DRY-RUN] paralelo_com_timeout: ${#cmds[@]} jobs (concorrência: ${concorrencia}, timeout: ${timeout_seg}s)" >&2
        local i
        for i in "${!cmds[@]}"; do
            echo "[DRY-RUN]   job $((i+1)): ${cmds[$i]}" >&2
        done
        return 0
    fi

    # Dispara o pool em subshell com timeout(1) como guardião
    # O subshell herda _PARALELO__PIDS via _paralelo_init interno
    local resultado
    timeout "$timeout_seg" bash -c "
        source '$(dirname "${BASH_SOURCE[0]}")/sinais.sh'
        source '$(dirname "${BASH_SOURCE[0]}")/dryrun.sh'
        source '$(dirname "${BASH_SOURCE[0]}")/paralelo.sh'
        paralelo_pool '$concorrencia' $(printf '%q ' "${cmds[@]}")
    "
    resultado=$?

    if [[ "$resultado" -eq 124 ]]; then
        echo "paralelo_com_timeout: timeout de ${timeout_seg}s atingido — jobs encerrados" >&2
    fi

    return "$resultado"
}
