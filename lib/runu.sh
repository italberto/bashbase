# shellcheck shell=bash
# runu.sh - Funções para execução de comandos com feedback visual no terminal
#
# Executa comandos em background enquanto exibe um spinner de progresso.
# Ao término, exibe o resultado com ícone colorido (✓ sucesso / ✗ falha).
# A saída do comando executado é redirecionada para /dev/null para não
# interferir no layout da animação.
#
# Quando DRYRUN="1", nenhum comando é executado: as funções imprimem no stderr
# o que seria feito, exibem a mensagem de conclusão com indicação "(dry-run)"
# e retornam 0.
#
# Dependências: spinner.sh, dryrun.sh
#
# Funções disponíveis:
#   executar              <msg> <cmd>          - Executa um comando local com spinner
#   executar_remoto       <host> <msg> <cmd>   - Executa um comando remoto via SSH com spinner
#   executar_com_timeout  <segundos> <cmd...>  - Executa um comando com limite máximo de tempo


[[ -n "${_RUNU_SH_LOADED:-}" ]] && return 0
readonly _RUNU_SH_LOADED=1

source "$(dirname "${BASH_SOURCE[0]}")/spinner.sh"
source "$(dirname "${BASH_SOURCE[0]}")/dryrun.sh"

function executar() {
    # Executa um comando shell em background exibindo um spinner de progresso.
    # Ao concluir, exibe mensagem de sucesso (verde) ou falha (vermelho)
    # com o código de saída do comando.
    # A saída do comando (stdout e stderr) é descartada para não quebrar o layout.
    # Modo de uso: executar"Instalando dependências" "apt install -y curl"
    local msg="$1"
    local cmd="$2"
    local frames="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"

    if [ "${DRYRUN:-}" = "1" ]; then
        echo "[DRY-RUN] executar: $msg → $cmd" >&2
        printf '\r\e[32m[✓]\e[0m %s concluído! (dry-run)%*s\n' "$msg" 10 ""
        return 0
    fi

    eval "$cmd" > /dev/null 2>&1 &
    local pid=$!

    spinner "$pid" "$frames" "$msg"

    wait "$pid"
    local exit_code=$?

    if [ $exit_code -eq 0 ]; then
        printf '\r\e[32m[✓]\e[0m %s concluído!%*s\n' "$msg" 10 ""
    else
        printf '\r\e[31m[✗]\e[0m %s falhou (Erro: %d)%*s\n' "$msg" "$exit_code" 10 ""
    fi

    return $exit_code
}

function executar_remoto() {
    # Executa um comando em um host remoto via SSH, exibindo um spinner de progresso.
    # Usa BatchMode para não solicitar senhas interativamente e ConnectTimeout
    # para evitar travamentos em hosts inacessíveis.
    # A saída do comando remoto é descartada para não quebrar o layout.
    # Retorna o código de saída do comando remoto.
    # Modo de uso: executar_remoto "usuario@192.168.1.10" "Reiniciando nginx" "systemctl restart nginx"
    local host="$1"
    local msg="$2"
    local cmd="$3"
    local frames="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"

    if [ "${DRYRUN:-}" = "1" ]; then
        echo "[DRY-RUN] executar_remoto: $msg → ssh $host '$cmd'" >&2
        printf '\r\e[32m[✓]\e[0m %s concluído! (dry-run)%*s\n' "$msg" 10 ""
        return 0
    fi

    ssh -o BatchMode=yes -o ConnectTimeout=10 "$host" "$cmd" > /dev/null 2>&1 &
    local pid=$!

    spinner "$pid" "$frames" "$msg"

    wait "$pid"
    local exit_code=$?

    if [ $exit_code -eq 0 ]; then
        printf '\r\e[32m[✓]\e[0m %s concluído!%*s\n' "$msg" 10 ""
    else
        printf '\r\e[31m[✗]\e[0m %s falhou (Erro: %d)%*s\n' "$msg" "$exit_code" 10 ""
    fi

    return $exit_code
}

function executar_com_timeout() {
    # Executa um comando com limite máximo de tempo em segundos.
    # Usa o comando timeout(1) do sistema, disponível no GNU coreutils.
    # Retorna 0 se o comando concluiu com sucesso dentro do prazo,
    # o código de saída do próprio comando em caso de falha,
    # ou 124 (código padrão de timeout(1)) se o tempo foi excedido.
    # Modo de uso: executar_com_timeout 30 curl -s https://exemplo.com
    #              executar_com_timeout 10 rsync -av origem/ destino/
    #   $1 = segundos máximos de execução
    #   $@ = comando a executar
    local timeout_seg="$1"
    shift

    if [ "${DRYRUN:-}" = "1" ]; then
        echo "[DRY-RUN] executar_com_timeout: ${timeout_seg}s → $*" >&2
        return 0
    fi

    timeout "$timeout_seg" "$@"
    local status=$?

    if [ "$status" -eq 124 ]; then
        echo "Timeout de ${timeout_seg}s atingido para: $*" >&2
    fi

    return "$status"
}
