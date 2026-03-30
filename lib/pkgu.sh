# shellcheck shell=bash
# pkgu.sh - Abstração para gerenciadores de pacotes de diferentes distribuições Linux
#
# Detecta automaticamente o gerenciador de pacotes da distribuição em uso
# e executa a operação solicitada com o comando adequado.
# Suporta: apt (Debian/Ubuntu), dnf (Fedora), pacman (Arch), yum (Red Hat),
#          zypper (SuSE), emerge (Gentoo) e apk (Alpine).
#
# Quando DRYRUN="1", nenhuma operação de instalação, remoção ou atualização
# é executada: as funções imprimem no stderr o que seria feito e retornam 0.
# procura_pacote não é afetada (operação somente-leitura).
#
# Dependências: distu.sh, dryrun.sh
#
# Funções disponíveis:
#   atualizar_pacote          - Atualiza todos os pacotes do sistema
#   instala_pacote          <nome> [silencioso] - Instala um pacote
#   instala_pacote_quieto   <nome>              - Instala um pacote sem saída no terminal
#   remove_pacote           <nome>              - Remove um pacote
#   procura_pacote           <nome>              - Busca pacotes pelo nome
#   atualiza_pacote           <nome>              - Atualiza um pacote específico


[[ -n "${_PKGU_SH_LOADED:-}" ]] && return 0
readonly _PKGU_SH_LOADED=1

source "$(dirname "${BASH_SOURCE[0]}")/distu.sh"
source "$(dirname "${BASH_SOURCE[0]}")/dryrun.sh"

function atualizar_pacote() {
    # Atualiza a lista de pacotes e instala as atualizações disponíveis
    # usando o gerenciador de pacotes da distribuição detectada.
    # Requer privilégios de root.
    # Modo de uso: atualizar_pacote
    if [ "${DRYRUN:-}" = "1" ]; then
        echo "[DRY-RUN] pkgu: atualizar todos os pacotes do sistema" >&2
        return 0
    fi
    if dist_e_debian || dist_e_ubuntu; then
        apt update && apt upgrade -y
    elif dist_e_fedora; then
        dnf update -y
    elif dist_e_arch; then
        pacman -Syu --noconfirm
    elif dist_e_redhat; then
        yum update -y
    elif dist_e_suse; then
        zypper update -y
    elif dist_e_gentoo; then
        emerge --sync && emerge --update --deep --with-bdeps=y @world
    elif dist_e_alpine; then
        apk update && apk upgrade
    else
        echo "Distribuição não suportada para atualização de pacotes."
    fi
}

function instala_pacote() {
    # Instala um pacote usando o gerenciador de pacotes da distribuição detectada.
    # Se o segundo parâmetro for fornecido (qualquer valor), a saída é redirecionada
    # para /dev/null, instalando o pacote de forma silenciosa.
    # Requer privilégios de root.
    # Modo de uso: instala_pacote "curl"
    #              instala_pacote "curl" 1   (instalação silenciosa)
    local pkg_name="$1"
    local silent="${2:-}"

    if [ "${DRYRUN:-}" = "1" ]; then
        echo "[DRY-RUN] pkgu: instalar pacote '$pkg_name'" >&2
        return 0
    fi

    _pkg_run() {
        if [ -n "$silent" ]; then
            "$@" &>/dev/null
        else
            "$@"
        fi
    }

    if dist_e_debian || dist_e_ubuntu; then
        _pkg_run apt install -y "$pkg_name"
    elif dist_e_fedora; then
        _pkg_run dnf install -y "$pkg_name"
    elif dist_e_arch; then
        _pkg_run pacman -S --noconfirm "$pkg_name"
    elif dist_e_redhat; then
        _pkg_run yum install -y "$pkg_name"
    elif dist_e_suse; then
        _pkg_run zypper install -y "$pkg_name"
    elif dist_e_gentoo; then
        _pkg_run emerge "$pkg_name"
    elif dist_e_alpine; then
        _pkg_run apk add "$pkg_name"
    else
        echo "Distribuição não suportada para instalação de pacotes."
        return 1
    fi

    unset -f _pkg_run
}

function instala_pacote_quieto() {
    # Instala um pacote de forma silenciosa, sem exibir saída no terminal.
    # Wrapper conveniente para instala_pacote com o modo silencioso ativado.
    # Requer privilégios de root.
    # Modo de uso: instala_pacote_quieto "curl"
    local package_name="$1"
    instala_pacote "$package_name" 1
}

function remove_pacote() {
    # Remove um pacote instalado usando o gerenciador de pacotes da distribuição detectada.
    # Requer privilégios de root.
    # Modo de uso: remove_pacote "curl"
    if [ "${DRYRUN:-}" = "1" ]; then
        echo "[DRY-RUN] pkgu: remover pacote '$1'" >&2
        return 0
    fi
    if dist_e_debian || dist_e_ubuntu; then
        apt remove -y "$1"
    elif dist_e_fedora; then
        dnf remove -y "$1"
    elif dist_e_arch; then
        pacman -R --noconfirm "$1"
    elif dist_e_redhat; then
        yum remove -y "$1"
    elif dist_e_suse; then
        zypper remove -y "$1"
    elif dist_e_gentoo; then
        emerge --unmerge "$1"
    elif dist_e_alpine; then
        apk del "$1"
    else
        echo "Distribuição não suportada para remoção de pacotes."
    fi
}

function procura_pacote() {
    # Busca pacotes disponíveis pelo nome ou descrição no repositório da distribuição.
    # Modo de uso: procura_pacote "nginx"
    if dist_e_debian || dist_e_ubuntu; then
        apt search "$1"
    elif dist_e_fedora; then
        dnf search "$1"
    elif dist_e_arch; then
        pacman -Ss "$1"
    elif dist_e_redhat; then
        yum search "$1"
    elif dist_e_suse; then
        zypper search "$1"
    elif dist_e_gentoo; then
        emerge --search "$1"
    elif dist_e_alpine; then
        apk search "$1"
    else
        echo "Distribuição não suportada para busca de pacotes."
    fi
}

function atualiza_pacote() {
    # Atualiza um pacote específico para a versão mais recente disponível
    # no repositório da distribuição detectada.
    # Requer privilégios de root.
    # Modo de uso: atualiza_pacote "nginx"
    if [ "${DRYRUN:-}" = "1" ]; then
        echo "[DRY-RUN] pkgu: atualizar pacote '$1'" >&2
        return 0
    fi
    if dist_e_debian || dist_e_ubuntu; then
        apt install --only-upgrade -y "$1"
    elif dist_e_fedora; then
        dnf update -y "$1"
    elif dist_e_arch; then
        pacman -S --noconfirm --needed "$1"
    elif dist_e_redhat; then
        yum update -y "$1"
    elif dist_e_suse; then
        zypper update -y "$1"
    elif dist_e_gentoo; then
        emerge --update --deep --with-bdeps=y "$1"
    elif dist_e_alpine; then
        apk upgrade "$1"
    else
        echo "Distribuição não suportada para atualização de pacotes."
    fi
}
