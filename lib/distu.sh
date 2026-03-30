# shellcheck shell=bash
# distu.sh - Funções para detecção da distribuição e informações do sistema operacional
#
# Cada função de detecção verifica a existência de arquivos característicos
# de cada distribuição em /etc/, retornando 0 se identificada e 1 caso contrário.
#
# Dependências: nenhuma
#
# Funções de detecção de distribuição:
#   dist_e_debian   - Debian
#   dist_e_ubuntu   - Ubuntu
#   dist_e_fedora   - Fedora
#   dist_e_arch     - Arch Linux
#   dist_e_redhat   - Red Hat Enterprise Linux
#   dist_e_suse     - SuSE Linux
#   dist_e_gentoo   - Gentoo Linux
#   dist_e_alpine   - Alpine Linux
#   dist_e_opensuse - openSUSE
#   dist_e_openbsd  - OpenBSD
#   dist_e_freebsd  - FreeBSD
#   dist_e_osx      - macOS
#
# Funções de informação do sistema:
#   dist_nome_do_so        - Nome do sistema operacional
#   dist_versao_do_so      - Versão do sistema operacional
#   dist_versao_do_kernel  - Versão do kernel
#   dist_arquitetura       - Arquitetura do processador (x86_64, arm64, etc.)
#   dist_nome_do_host      - Nome do host
#   dist_tempo_ligado      - Tempo de atividade do sistema



[[ -n "${_DISTU_SH_LOADED:-}" ]] && return 0
readonly _DISTU_SH_LOADED=1

function dist_e_debian() {
    # Verifica se o sistema é Debian, checando /etc/debian_version.
    # Modo de uso: dist_e_debian && echo "É Debian"
    if [ -f /etc/debian_version ]; then
        return 0
    else
        return 1
    fi
}

function dist_e_ubuntu() {
    # Verifica se o sistema é Ubuntu, checando a presença de "Ubuntu" em /etc/lsb-release.
    # Modo de uso: dist_e_ubuntu && echo "É Ubuntu"
    if [ -f /etc/lsb-release ] && grep -q "Ubuntu" /etc/lsb-release; then
        return 0
    else
        return 1
    fi
}

function dist_e_fedora() {
    # Verifica se o sistema é Fedora, checando /etc/fedora-release.
    # Modo de uso: dist_e_fedora && echo "É Fedora"
    if [ -f /etc/fedora-release ]; then
        return 0
    else
        return 1
    fi
}

function dist_e_arch() {
    # Verifica se o sistema é Arch Linux, checando /etc/arch-release.
    # Modo de uso: dist_e_arch && echo "É Arch Linux"
    if [ -f /etc/arch-release ]; then
        return 0
    else
        return 1
    fi
}

function dist_e_redhat() {
    # Verifica se o sistema é Red Hat Enterprise Linux, checando /etc/redhat-release.
    # Modo de uso: dist_e_redhat && echo "É Red Hat"
    if [ -f /etc/redhat-release ]; then
        return 0
    else
        return 1
    fi
}

function dist_e_suse() {
    # Verifica se o sistema é SuSE Linux, checando /etc/SuSE-release.
    # Modo de uso: dist_e_suse && echo "É SuSE"
    if [ -f /etc/SuSE-release ]; then
        return 0
    else
        return 1
    fi
}

function dist_e_gentoo() {
    # Verifica se o sistema é Gentoo Linux, checando /etc/gentoo-release.
    # Modo de uso: dist_e_gentoo && echo "É Gentoo"
    if [ -f /etc/gentoo-release ]; then
        return 0
    else
        return 1
    fi
}

function dist_e_alpine() {
    # Verifica se o sistema é Alpine Linux, checando /etc/alpine-release.
    # Modo de uso: dist_e_alpine && echo "É Alpine"
    if [ -f /etc/alpine-release ]; then
        return 0
    else
        return 1
    fi
}

function dist_e_opensuse() {
    # Verifica se o sistema é openSUSE, checando a presença de "openSUSE" em /etc/os-release.
    # Modo de uso: dist_e_opensuse && echo "É openSUSE"
    if [ -f /etc/os-release ] && grep -q "openSUSE" /etc/os-release; then
        return 0
    else
        return 1
    fi
}

function dist_e_openbsd() {
    # Verifica se o sistema é OpenBSD, checando a presença de "OpenBSD" em /etc/os-release.
    # Modo de uso: dist_e_openbsd && echo "É OpenBSD"
    if [ -f /etc/os-release ] && grep -q "OpenBSD" /etc/os-release; then
        return 0
    else
        return 1
    fi
}

function dist_e_freebsd() {
    # Verifica se o sistema é FreeBSD, checando a presença de "FreeBSD" em /etc/os-release.
    # Modo de uso: dist_e_freebsd && echo "É FreeBSD"
    if [ -f /etc/os-release ] && grep -q "FreeBSD" /etc/os-release; then
        return 0
    else
        return 1
    fi
}

function dist_e_osx() {
    # Verifica se o sistema é macOS, checando a existência do arquivo de versão do sistema Apple.
    # Modo de uso: dist_e_osx && echo "É macOS"
    if [ -f /System/Library/CoreServices/SystemVersion.plist ]; then
        return 0
    else
        return 1
    fi
}

function dist_nome_do_so() {
    # Retorna o nome do sistema operacional lendo a variável NAME de /etc/os-release.
    # Modo de uso: echo "Sistema: $(dist_nome_do_so)"
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$NAME"
    else
        echo "Desconecido"
    fi
}

function dist_versao_do_so() {
    # Retorna a versão do sistema operacional lendo VERSION_ID de /etc/os-release.
    # Modo de uso: echo "Versão: $(dist_versao_do_so)"
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$VERSION_ID"
    else
        echo "Desconecido"
    fi
}

function dist_versao_do_kernel() {
    # Retorna a versão completa do kernel em execução.
    # Modo de uso: echo "Kernel: $(dist_versao_do_kernel)"
    uname -r
}

function dist_arquitetura() {
    # Retorna a arquitetura do processador (ex: x86_64, aarch64, armv7l).
    # Modo de uso: echo "Arquitetura: $(dist_arquitetura)"
    uname -m
}

function dist_nome_do_host() {
    # Retorna o nome de host da máquina.
    # Modo de uso: echo "Host: $(dist_nome_do_host)"
    uname -n
}

function dist_tempo_ligado() {
    # Retorna o tempo de atividade do sistema em formato legível (ex: "up 2 hours, 30 minutes").
    # Modo de uso: echo "tempo_ligado: $(dist_tempo_ligado)"
    uptime -p
}
