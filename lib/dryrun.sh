# shellcheck shell=bash
# dryrun.sh - Suporte a modo dry-run global para simulação de operações
#
# Quando DRYRUN="1", todas as funções da biblioteca que causam efeitos colaterais
# (escrita em disco, execução de comandos, chamadas de rede, modificação de sistema)
# simulam a operação sem executá-la, imprimindo no stderr o que seria feito.
# Quando DRYRUN="" (padrão), o comportamento é idêntico ao normal.
#
# Para ativar o dry-run a partir da linha de comando com argsu.sh:
#   arg_definir "--dry-run" DRYRUN "" "Simula operações sem executar nada" "boolean"
#   arg_parsear "$@" || exit 1
#
# Dependências: nenhuma
#
# Variável global:
#   DRYRUN   "1" ativa o modo dry-run; "" (padrão) executa normalmente
#
# Funções disponíveis:
#   dryrun_exec    <descricao> <cmd...>   - Executa cmd ou simula em dry-run
#   dryrun_gravar  <arquivo>   <conteudo> - Acrescenta linha ao arquivo ou simula
#   dryrun_ativo                          - Retorna 0 se dry-run estiver ativo


[[ -n "${_DRYRUN_SH_LOADED:-}" ]] && return 0
readonly _DRYRUN_SH_LOADED=1

# "1" ativa o modo dry-run; "" (padrão) executa normalmente
DRYRUN="${DRYRUN:-}"

function dryrun_exec() {
    # Executa um comando com seus argumentos, ou simula a execução em dry-run.
    # Em dry-run: imprime "[DRY-RUN] <descricao>" no stderr e retorna 0.
    # Em modo normal: executa o comando e retorna seu código de saída.
    # Modo de uso: dryrun_exec "cp arquivo destino" cp arquivo destino
    local descricao="$1"
    shift
    if [ "${DRYRUN:-}" = "1" ]; then
        echo "[DRY-RUN] $descricao" >&2
        return 0
    fi
    "$@"
}

function dryrun_gravar() {
    # Acrescenta uma linha ao arquivo, ou simula a escrita em dry-run.
    # Em dry-run: imprime "[DRY-RUN] escrever em '<arquivo>': <conteudo>" no stderr.
    # Em modo normal: executa echo "<conteudo>" >> "<arquivo>".
    # Modo de uso: dryrun_gravar /etc/app/config.env "CHAVE=valor"
    local arquivo="$1"
    local conteudo="$2"
    if [ "${DRYRUN:-}" = "1" ]; then
        echo "[DRY-RUN] escrever em '$arquivo': $conteudo" >&2
        return 0
    fi
    echo "$conteudo" >> "$arquivo"
}

function dryrun_ativo() {
    # Retorna 0 se o modo dry-run estiver ativo, 1 caso contrário.
    # Modo de uso: dryrun_ativo && echo "Modo simulação ativo"
    [ "${DRYRUN:-}" = "1" ]
}
