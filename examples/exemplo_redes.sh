#!/usr/bin/env bash

# exemplo_redes.sh - Exemplo de uso do módulo lib/redes.sh
#
# Demonstra verificações de infraestrutura de rede:
#   - internet
#   - DNS
#   - gateway
#   - interface de rede
#   - Wi‑Fi / Ethernet
#   - portas TCP
#   - listagem de endereços IP

set -euo pipefail

if [ -z "$BASHBASE" ]; then
    echo "Variável BASHBASE não definida."
    exit 1
fi

source "$BASHBASE/lib/redes.sh"
source "$BASHBASE/lib/alerta.sh"

interface_teste="${1:-lo}"
host_teste="${2:-localhost}"
porta_teste="${3:-22}"

tem_comando() {
    command -v "$1" >/dev/null 2>&1
}

echo "=== Exemplo de uso do módulo redes.sh ==="
echo ""

echo "Parâmetros de teste:"
echo "  Interface: $interface_teste"
echo "  Host:      $host_teste"
echo "  Porta TCP: $porta_teste"
echo ""

msg_info "1) Verificando conectividade com a internet" 1
if tem_comando ping && con_checar_internet; then
    msg_sucesso "Internet disponível" 2
else
    msg_alerta "Sem conectividade com a internet ou comando 'ping' indisponível" 2
fi

echo ""
msg_info "2) Verificando resolução DNS" 1
if tem_comando host || tem_comando dig || tem_comando nslookup; then
    if con_checar_dns; then
        msg_sucesso "DNS funcionando corretamente" 2
    else
        msg_alerta "Falha na resolução DNS" 2
    fi
else
    msg_alerta "Nenhuma ferramenta DNS disponível ('host', 'dig' ou 'nslookup')" 2
fi

echo ""
msg_info "3) Verificando gateway padrão" 1
if tem_comando ip && con_checar_gateway; then
    msg_sucesso "Gateway padrão configurado" 2
else
    msg_alerta "Nenhum gateway padrão encontrado ou comando 'ip' indisponível" 2
fi

echo ""
msg_info "4) Verificando interface de rede: $interface_teste" 1
if tem_comando ip && con_checar_interface "$interface_teste"; then
    msg_sucesso "Interface '$interface_teste' encontrada" 2
else
    msg_alerta "Interface '$interface_teste' não existe ou comando 'ip' indisponível" 2
fi

echo ""
msg_info "5) Verificando conectividade Wi‑Fi e Ethernet" 1
if tem_comando nmcli || tem_comando iwconfig; then
    if con_checar_wifi; then
        msg_sucesso "Existe conexão Wi‑Fi ativa" 2
    else
        msg_alerta "Nenhuma conexão Wi‑Fi ativa detectada" 2
    fi
else
    msg_alerta "Nenhuma ferramenta disponível para verificar Wi‑Fi ('nmcli' ou 'iwconfig')" 2
fi

if tem_comando nmcli || tem_comando ethtool; then
    if con_checar_ethernet; then
        msg_sucesso "Existe conexão Ethernet ativa" 2
    else
        msg_alerta "Nenhuma conexão Ethernet ativa detectada" 2
    fi
else
    msg_alerta "Nenhuma ferramenta disponível para verificar Ethernet ('nmcli' ou 'ethtool')" 2
fi

echo ""
msg_info "6) Verificando porta TCP em $host_teste:$porta_teste" 1
if con_checar_porta "$host_teste" "$porta_teste" 2; then
    msg_sucesso "Porta $porta_teste acessível em $host_teste" 2
else
    msg_alerta "Porta $porta_teste não está acessível em $host_teste" 2
fi

echo ""
msg_info "7) Listando endereços IPv4 locais" 1
if tem_comando ip; then
    if con_lista_enderecos_ip | while IFS= read -r linha; do msg_sucesso "$linha" 2; done; then
        :
    else
        msg_alerta "Não foi possível listar os endereços IP" 2
    fi
else
    msg_alerta "Comando 'ip' indisponível; não foi possível listar os endereços IP" 2
fi

echo ""
msg_sucesso "Exemplo finalizado." 1
exit 0
