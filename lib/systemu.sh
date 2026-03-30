# shellcheck shell=bash
# systemu.sh - Funções utilitárias gerais de sistema
#
# Fornece verificações de privilégios, detecção de programas instalados
# e funções de encerramento padronizadas para scripts de automação.
#
# Dependências: nenhuma
#
# Funções disponíveis:
#   sys_e_root                  - Verifica se o script está sendo executado como root
#   sys_programa_esta_instalado - Verifica se um programa está disponível no PATH
#   sys_finaliza_ok             - Encerra o script com código de saída 0 (sucesso)
#   sys_finaliza_erro           - Encerra o script com código de saída 1 (erro)


[[ -n "${_SYSTEMU_SH_LOADED:-}" ]] && return 0
readonly _SYSTEMU_SH_LOADED=1

function sys_e_root() {
    # Verifica se o usuário que executa o script é root (EUID = 0).
    # Retorna 0 se for root, 1 caso contrário.
    # Modo de uso: sys_e_root || { erro "Execute como root"; exit 1; }
    if [ "$EUID" -ne 0 ]; then
        return 1
    else
        return 0
    fi
}

function sys_programa_esta_instalado() {
    # Verifica se um programa está instalado e acessível no PATH do sistema.
    # Retorna 0 se o programa for encontrado, 1 caso contrário.
    # Modo de uso: sys_programa_esta_instalado "curl" || echo "curl não instalado"
    if command -v "$1" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

function sys_finaliza_ok() {
    # Encerra o script imediatamente com código de saída 0 (sucesso).
    # Usar ao final de scripts que concluíram com êxito.
    # Modo de uso: sys_finaliza_ok
    exit 0
}

function sys_finaliza_erro() {
    # Encerra o script imediatamente com código de saída 1 (erro).
    # Usar quando o script detectar uma condição de falha irrecuperável.
    # Modo de uso: sys_finaliza_erro
    exit 1
}

