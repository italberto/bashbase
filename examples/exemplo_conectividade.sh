#!/usr/bin/env bash

set -euo pipefail

if [ -z "$BASHBASE" ]; then
    echo "Variável BASHBASE não definida."
    exit 1
fi

source "$BASHBASE/lib/redes.sh"
source "$BASHBASE/lib/servicos/conectividade.sh"
source "$BASHBASE/lib/alerta.sh"

info "=== Diagnóstico de rede ==="

info "Conectividade básica:" 1

if con_checar_internet; then
    sucesso "Internet disponível" 2
else
    erro "Sem internet" 2
fi

if con_checar_dns; then
    sucesso "DNS resolvendo" 2
else
    erro "DNS falhou" 2
fi

if con_checar_gateway; then
    sucesso "Gateway configurado" 2
else
    erro "Sem gateway" 2
fi

if con_checar_wifi; then
    sucesso "Wi-Fi ativo" 2
else
    alerta "Sem Wi-Fi" 2
fi

if con_checar_ethernet; then
    sucesso "Ethernet ativa" 2
else
    alerta "Sem Ethernet" 2
fi

info "Serviços disponíveis em localhost:" 1

servicos=(ssh http https dns smtp pop3 imap ftp smb rdp vpn)
funcoes=(
    con_ssh_disponivel
    con_http_disponivel
    con_https_disponivel
    con_dns_disponivel
    con_smtp_disponivel
    con_pop3_disponivel
    con_imap_disponivel
    con_ftp_disponivel
    con_smb_disponivel
    con_rdp_disponivel
    con_vpn_disponivel
)

for i in "${!funcoes[@]}"; do
    if "${funcoes[$i]}"; then
        sucesso "${servicos[$i]}" 2
    else
        alerta "${servicos[$i]} indisponível" 2
    fi
done

info "Endereços IP:" 1
while IFS= read -r linha; do
    sucesso "$linha" 2
done < <(con_lista_enderecos_ip)
