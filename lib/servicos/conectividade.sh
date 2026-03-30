# shellcheck shell=bash
# conectividade.sh - Verificação de disponibilidade de serviços de rede conhecidos
#
# Fornece funções de alto nível para testar se serviços padrão de rede estão
# acessíveis em um host, verificando suas portas convencionais. Cada função
# aceita um host opcional; quando omitido, verifica o localhost.
#
# Este módulo pertence à camada de serviços da biblioteca (lib/servicos/).
# Para primitivos de rede (checar portas, interfaces, gateway), use lib/redes.sh.
#
# Dependências: redes.sh
#
# Funções disponíveis:
#   con_ssh_disponivel    [host] - Verifica disponibilidade do SSH (porta 22)
#   con_http_disponivel   [host] - Verifica disponibilidade do HTTP (porta 80)
#   con_https_disponivel  [host] - Verifica disponibilidade do HTTPS (porta 443)
#   con_dns_disponivel    [host] - Verifica disponibilidade do DNS (porta 53)
#   con_smtp_disponivel   [host] - Verifica disponibilidade do SMTP (porta 25)
#   con_pop3_disponivel   [host] - Verifica disponibilidade do POP3 (porta 110)
#   con_imap_disponivel   [host] - Verifica disponibilidade do IMAP (porta 143)
#   con_ftp_disponivel    [host] - Verifica disponibilidade do FTP (porta 21)
#   con_smb_disponivel    [host] - Verifica disponibilidade do SMB (porta 445)
#   con_rdp_disponivel    [host] - Verifica disponibilidade do RDP (porta 3389)
#   con_vpn_disponivel    [host] - Verifica disponibilidade do VPN/OpenVPN (porta 1194)


[[ -n "${_SERVICOS_CONECTIVIDADE_SH_LOADED:-}" ]] && return 0
readonly _SERVICOS_CONECTIVIDADE_SH_LOADED=1

source "$(dirname "${BASH_SOURCE[0]}")/../redes.sh"

function con_ssh_disponivel() {
    # Verifica se o serviço SSH está acessível na porta 22.
    # Modo de uso: con_ssh_disponivel
    #              con_ssh_disponivel "10.0.0.5"
    local host="${1:-localhost}"
    con_checar_porta "$host" 22
}

function con_http_disponivel() {
    # Verifica se o serviço HTTP está acessível na porta 80.
    # Modo de uso: con_http_disponivel
    #              con_http_disponivel "meuservidor.local"
    local host="${1:-localhost}"
    con_checar_porta "$host" 80
}

function con_https_disponivel() {
    # Verifica se o serviço HTTPS está acessível na porta 443.
    # Modo de uso: con_https_disponivel
    #              con_https_disponivel "api.prod.com"
    local host="${1:-localhost}"
    con_checar_porta "$host" 443
}

function con_dns_disponivel() {
    # Verifica se o serviço DNS está acessível na porta 53.
    # Modo de uso: con_dns_disponivel
    #              con_dns_disponivel "8.8.8.8"
    local host="${1:-localhost}"
    con_checar_porta "$host" 53
}

function con_smtp_disponivel() {
    # Verifica se o serviço SMTP está acessível na porta 25.
    # Modo de uso: con_smtp_disponivel
    #              con_smtp_disponivel "mail.empresa.com"
    local host="${1:-localhost}"
    con_checar_porta "$host" 25
}

function con_pop3_disponivel() {
    # Verifica se o serviço POP3 está acessível na porta 110.
    # Modo de uso: con_pop3_disponivel
    #              con_pop3_disponivel "mail.empresa.com"
    local host="${1:-localhost}"
    con_checar_porta "$host" 110
}

function con_imap_disponivel() {
    # Verifica se o serviço IMAP está acessível na porta 143.
    # Modo de uso: con_imap_disponivel
    #              con_imap_disponivel "mail.empresa.com"
    local host="${1:-localhost}"
    con_checar_porta "$host" 143
}

function con_ftp_disponivel() {
    # Verifica se o serviço FTP está acessível na porta 21.
    # Modo de uso: con_ftp_disponivel
    #              con_ftp_disponivel "ftp.empresa.com"
    local host="${1:-localhost}"
    con_checar_porta "$host" 21
}

function con_smb_disponivel() {
    # Verifica se o serviço SMB/CIFS está acessível na porta 445.
    # Modo de uso: con_smb_disponivel
    #              con_smb_disponivel "fileserver.local"
    local host="${1:-localhost}"
    con_checar_porta "$host" 445
}

function con_rdp_disponivel() {
    # Verifica se o serviço RDP está acessível na porta 3389.
    # Modo de uso: con_rdp_disponivel
    #              con_rdp_disponivel "desktop.empresa.com"
    local host="${1:-localhost}"
    con_checar_porta "$host" 3389
}

function con_vpn_disponivel() {
    # Verifica se o serviço VPN/OpenVPN está acessível na porta 1194.
    # Modo de uso: con_vpn_disponivel
    #              con_vpn_disponivel "vpn.empresa.com"
    local host="${1:-localhost}"
    con_checar_porta "$host" 1194
}
