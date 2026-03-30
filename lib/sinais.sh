# shellcheck shell=bash
# sinais.sh - Infraestrutura de tratamento de sinais e cleanup garantido
#
# Implementa o padrão acumulador de handlers: múltiplos módulos e scripts
# podem registrar funções de limpeza sem sobrescrever uns aos outros.
# Os handlers são executados em ordem reversa de registração (pilha LIFO),
# garantindo que o último recurso adquirido seja o primeiro a ser liberado.
#
# Um único trap central é instalado para EXIT, INT, TERM e HUP.
# Os traps de sinal removem o trap EXIT antes de chamar os handlers,
# evitando dupla execução.
#
# A variável _SINAIS__CODIGO_SAIDA fica disponível aos handlers para que
# possam distinguir saída normal (0) de saída por sinal (130=INT, 143=TERM).
#
# Dependências: nenhuma
#
# Funções disponíveis:
#   registrar_cleanup     <comando>        - Adiciona um comando ao stack de limpeza
#   registrar_cleanup_cmd <cmd> [args...]  - Versão segura para comandos com espaços nos argumentos
#   cancelar_cleanup      <comando>        - Remove um comando do stack de limpeza


[[ -n "${_SINAIS_SH_LOADED:-}" ]] && return 0
readonly _SINAIS_SH_LOADED=1

# Stack de comandos de limpeza (executados em ordem LIFO na saída)
_SINAIS__CLEANUP_HANDLERS=()

# Código de saída que disparou a limpeza — acessível aos handlers
_SINAIS__CODIGO_SAIDA=0

function registrar_cleanup() {
    # Adiciona um comando ao stack de limpeza.
    # Aceita qualquer string de comando shell válida.
    # Os comandos são executados em ordem inversa à de registração (LIFO):
    # o último recurso adquirido é o primeiro a ser liberado.
    # Modo de uso: registrar_cleanup "rm -f /tmp/dados.tmp"
    #              registrar_cleanup "lock_liberar /tmp/app.lock"
    _SINAIS__CLEANUP_HANDLERS+=("$1")
}

function registrar_cleanup_cmd() {
    # Versão segura de registrar_cleanup para comandos cujos argumentos podem conter
    # espaços, aspas ou outros caracteres especiais (ex: caminhos de arquivo com espaços).
    # Cada argumento é escapado com printf '%q' antes do registro, garantindo que o
    # eval interno de _sinais_executar_cleanups os trate como tokens individuais.
    # Modo de uso: registrar_cleanup_cmd rm -f "/tmp/meu arquivo.tmp"
    #              registrar_cleanup_cmd lock_liberar "/var/run/meu app.lock"
    local cmd_escapado=()
    local arg
    for arg in "$@"; do
        cmd_escapado+=("$(printf '%q' "$arg")")
    done
    registrar_cleanup "${cmd_escapado[*]}"
}

function cancelar_cleanup() {
    # Remove um comando do stack de limpeza.
    # Útil quando o recurso já foi liberado manualmente antes da saída do script.
    # Modo de uso: cancelar_cleanup "rm -f /tmp/dados.tmp"
    local novo=()
    local alvo="$1"
    for handler in "${_SINAIS__CLEANUP_HANDLERS[@]}"; do
        [[ "$handler" != "$alvo" ]] && novo+=("$handler")
    done
    _SINAIS__CLEANUP_HANDLERS=("${novo[@]}")
}

function _sinais_executar_cleanups() {
    # Percorre o stack em ordem reversa e executa cada handler.
    # Erros individuais são suprimidos (2>/dev/null) para garantir que
    # todos os handlers rodem mesmo que um deles falhe.
    local i
    for (( i=${#_SINAIS__CLEANUP_HANDLERS[@]}-1; i>=0; i-- )); do
        eval "${_SINAIS__CLEANUP_HANDLERS[$i]}" 2>/dev/null
    done
}

# Trap para saída normal: captura o código de saída original antes de limpar
trap '_SINAIS__CODIGO_SAIDA=$?; _sinais_executar_cleanups' EXIT

# Traps para sinais: remove o trap EXIT antes de executar para evitar
# dupla execução, depois sai com o código convencional do sinal recebido
# (128 + número do sinal: INT=2→130, HUP=1→129, TERM=15→143)
trap 'trap - EXIT; _SINAIS__CODIGO_SAIDA=130; _sinais_executar_cleanups; exit 130' INT
trap 'trap - EXIT; _SINAIS__CODIGO_SAIDA=143; _sinais_executar_cleanups; exit 143' TERM
trap 'trap - EXIT; _SINAIS__CODIGO_SAIDA=129; _sinais_executar_cleanups; exit 129' HUP
