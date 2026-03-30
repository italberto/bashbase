# shellcheck shell=bash
# servicou.sh - Funções para gerenciamento de serviços via systemd
#
# Fornece wrappers para as operações mais comuns do systemctl,
# simplificando o gerenciamento de serviços em scripts de automação.
# Verifica automaticamente se systemd está disponível antes de cada operação,
# retornando 1 com mensagem de erro em sistemas que usam SysV, OpenRC ou similares.
#
# Quando DRYRUN="1", nenhum serviço é iniciado, parado ou modificado:
# as funções imprimem no stderr o comando systemctl que seria executado.
# servico_ativo e servico_status não são afetados (operações somente-leitura).
#
# Dependências: systemu.sh, alerta.sh, dryrun.sh
#
# Funções disponíveis:
#   servico_ativo       <nome> - Verifica se o serviço está em execução
#   servico_iniciar     <nome> - Inicia o serviço
#   servico_parar       <nome> - Para o serviço
#   servico_reiniciar   <nome> - Reinicia o serviço
#   servico_habilitar   <nome> - Habilita início automático no boot
#   servico_desabilitar <nome> - Desabilita início automático no boot
#   servico_status      <nome> - Exibe o status detalhado do serviço


[[ -n "${_SERVICOU_SH_LOADED:-}" ]] && return 0
readonly _SERVICOU_SH_LOADED=1

source "$(dirname "${BASH_SOURCE[0]}")/systemu.sh"
source "$(dirname "${BASH_SOURCE[0]}")/alerta.sh"
source "$(dirname "${BASH_SOURCE[0]}")/dryrun.sh"

function _servicou_verificar_systemd() {
    # Verifica se o systemctl está disponível no PATH antes de qualquer operação.
    # Retorna 0 se systemd estiver disponível, 1 caso contrário.
    # Emite mensagem de erro descritiva para facilitar diagnóstico em containers
    # e sistemas que usam alternativas como OpenRC, SysV ou s6.
    if ! command -v systemctl >/dev/null 2>&1; then
        erro "systemd não está disponível neste sistema. As funções de serviço requerem systemctl." >&2
        return 1
    fi
    return 0
}

function servico_ativo() {
    # Verifica silenciosamente se um serviço systemd está em execução.
    # Retorna 0 se ativo, 1 caso contrário. Ideal para uso em condicionais.
    # Modo de uso: servico_ativo "nginx" && echo "nginx está rodando"
    _servicou_verificar_systemd || return 1
    systemctl is-active --quiet "$1"
}

function servico_iniciar() {
    # Inicia um serviço systemd.
    # Requer privilégios de root ou sudo.
    # Modo de uso: servico_iniciar "nginx"
    _servicou_verificar_systemd || return 1
    dryrun_exec "servicou: systemctl start '$1'" systemctl start "$1"
}

function servico_parar() {
    # Para um serviço systemd em execução.
    # Requer privilégios de root ou sudo.
    # Modo de uso: servico_parar "nginx"
    _servicou_verificar_systemd || return 1
    dryrun_exec "servicou: systemctl stop '$1'" systemctl stop "$1"
}

function servico_reiniciar() {
    # Reinicia um serviço systemd, parando e iniciando novamente.
    # Útil para aplicar novas configurações sem intervenção manual.
    # Requer privilégios de root ou sudo.
    # Modo de uso: servico_reiniciar "nginx"
    _servicou_verificar_systemd || return 1
    dryrun_exec "servicou: systemctl restart '$1'" systemctl restart "$1"
}

function servico_habilitar() {
    # Habilita o início automático do serviço durante o boot do sistema.
    # Requer privilégios de root ou sudo.
    # Modo de uso: servico_habilitar "nginx"
    _servicou_verificar_systemd || return 1
    dryrun_exec "servicou: systemctl enable '$1'" systemctl enable "$1"
}

function servico_desabilitar() {
    # Desabilita o início automático do serviço durante o boot do sistema.
    # O serviço não é parado imediatamente; apenas o boot automático é desativado.
    # Requer privilégios de root ou sudo.
    # Modo de uso: servico_desabilitar "nginx"
    _servicou_verificar_systemd || return 1
    dryrun_exec "servicou: systemctl disable '$1'" systemctl disable "$1"
}

function servico_status() {
    # Exibe o status detalhado de um serviço systemd, incluindo logs recentes.
    # Modo de uso: servico_status "nginx"
    _servicou_verificar_systemd || return 1
    systemctl status "$1"
}
