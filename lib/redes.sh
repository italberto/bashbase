# shellcheck shell=bash
# redes.sh - Primitivos de diagnóstico de rede
#
# Fornece verificações de baixo nível para conectividade com a internet, DNS,
# interfaces de rede, gateway, Wi-Fi, Ethernet e disponibilidade de portas TCP.
# Estas funções operam sobre infraestrutura de rede sem conhecimento de serviços
# específicos. Para verificar serviços conhecidos (SSH, HTTP, etc.), use
# lib/servicos/conectividade.sh.
#
# Dependências: systemu.sh, alerta.sh
#
# Funções disponíveis:
#   con_checar_internet      - Verifica conectividade com a internet
#   con_checar_dns           - Verifica resolução de nomes DNS
#   con_checar_porta         <host> <porta> [timeout] - Verifica se uma porta TCP está aberta
#   con_checar_interface     <interface>    - Verifica se uma interface de rede existe
#   con_checar_gateway       - Verifica se há gateway padrão configurado
#   con_checar_wifi          - Verifica se há conexão Wi-Fi ativa
#   con_checar_ethernet      - Verifica se há conexão Ethernet ativa
#   con_lista_enderecos_ip   - Lista os endereços IP de todas as interfaces


[[ -n "${_REDES_SH_LOADED:-}" ]] && return 0
readonly _REDES_SH_LOADED=1

source "$(dirname "${BASH_SOURCE[0]}")/systemu.sh"
source "$(dirname "${BASH_SOURCE[0]}")/alerta.sh"

function con_checar_internet() {
    # Testa conectividade com a internet via ping.
    # Tenta google.com primeiro; se falhar, tenta o IP do DNS do Google (8.8.8.8)
    # para distinguir falha de DNS de falha de rota.
    # Retorna 0 se qualquer um dos testes responder, 1 se ambos falharem.
    # Modo de uso: con_checar_internet && echo "Internet disponível"
    if ping -c 1 google.com &>/dev/null || ping -c 1 8.8.8.8 &>/dev/null; then
        return 0
    else
        return 1
    fi
}

function con_checar_dns() {
    # Verifica se a resolução de nomes DNS está funcionando.
    # Tenta host, dig ou nslookup (nesta ordem); usa a primeira ferramenta encontrada.
    # Retorna 0 se a resolução de google.com for bem-sucedida, 1 caso contrário.
    # Retorna 1 com mensagem de erro se nenhuma ferramenta estiver disponível.
    # Modo de uso: con_checar_dns || alerta "DNS não está resolvendo"
    if sys_programa_esta_instalado "host"; then
        host google.com &>/dev/null && return 0
    elif sys_programa_esta_instalado "dig"; then
        dig +short google.com &>/dev/null && return 0
    elif sys_programa_esta_instalado "nslookup"; then
        nslookup google.com &>/dev/null && return 0
    else
        erro "Nenhuma ferramenta de consulta DNS encontrada ('host', 'dig' ou 'nslookup')."
        return 1
    fi
    return 1
}

function con_checar_porta() {
    # Verifica se uma porta TCP está aberta em um host.
    # Usa /dev/tcp (built-in do bash) como método primário; cai para nc se falhar.
    # O timeout padrão é 3 segundos; pode ser ajustado pelo terceiro parâmetro.
    # Retorna 0 se a porta estiver acessível, 1 caso contrário.
    # Modo de uso: con_checar_porta db.local 5432
    #              con_checar_porta 10.0.0.1 22 5
    local host="$1"
    local porta="$2"
    local timeout="${3:-3}"

    if (timeout "$timeout" bash -c "echo > /dev/tcp/$host/$porta") &>/dev/null; then
        return 0
    fi

    if sys_programa_esta_instalado "nc"; then
        nc -z -w "$timeout" "$host" "$porta" &>/dev/null && return 0
    fi

    return 1
}

function con_checar_interface() {
    # Verifica se uma interface de rede existe no sistema.
    # Retorna 0 se a interface existir, 1 caso contrário.
    # Modo de uso: con_checar_interface eth0
    #              con_checar_interface wlan0 || alerta "Interface Wi-Fi não encontrada"
    if ip link show "$1" &>/dev/null; then
        return 0
    else
        return 1
    fi
}

function con_checar_gateway() {
    # Verifica se há um gateway padrão configurado na tabela de rotas.
    # Retorna 0 se houver rota default, 1 caso contrário.
    # Modo de uso: con_checar_gateway || alerta "Sem gateway configurado"
    if ip route | grep -q "default"; then
        return 0
    else
        return 1
    fi
}

function con_checar_wifi() {
    # Verifica se o sistema está conectado a uma rede Wi-Fi.
    # Usa nmcli como método primário; cai para iwconfig como fallback.
    # Retorna 0 se houver conexão Wi-Fi ativa, 1 caso contrário.
    # Retorna 1 com mensagem de erro se nenhuma ferramenta estiver disponível.
    # Modo de uso: con_checar_wifi && echo "Wi-Fi conectado"

    if sys_programa_esta_instalado "nmcli"; then
        if nmcli -t -f TYPE,STATE device | grep -qE "^wifi:(conectado|connected)"; then
            return 0
        fi
    fi

    if sys_programa_esta_instalado "iwconfig"; then
        if iwconfig 2>&1 | grep -q "ESSID"; then
            return 0
        fi
    else
        if ! sys_programa_esta_instalado "nmcli"; then
            erro "Nenhum dos comandos ('nmcli' ou 'iwconfig') foi encontrado para verificar o Wi-Fi."
            return 1
        fi
    fi

    return 1
}

function con_checar_ethernet() {
    # Verifica se o sistema está conectado a uma rede Ethernet.
    # Usa nmcli como método primário; cai para ethtool como fallback.
    # No fallback, itera sobre cada interface en*/eth* individualmente,
    # removendo sufixos @ifN (presentes em containers) antes de consultar ethtool.
    # Retorna 0 se houver conexão Ethernet ativa, 1 caso contrário.
    # Modo de uso: con_checar_ethernet || alerta "Sem Ethernet ativa"

    if sys_programa_esta_instalado "nmcli"; then
        if nmcli -t -f TYPE,STATE device | grep -qE "^ethernet:(conectado|connected)"; then
            return 0
        fi
    fi

    if ! sys_programa_esta_instalado "ethtool"; then
        if ! sys_programa_esta_instalado "nmcli"; then
            erro "Nenhum dos comandos ('nmcli' ou 'ethtool') foi encontrado para verificar a Ethernet."
        fi
        return 1
    fi

    local interfaces
    mapfile -t interfaces < <(ip -o link show | awk -F': ' '{print $2}' | cut -d@ -f1 | grep -E '^(en|eth)')

    if [ "${#interfaces[@]}" -eq 0 ]; then
        return 1
    fi

    local iface
    for iface in "${interfaces[@]}"; do
        if ethtool "$iface" 2>/dev/null | grep -q "Link detected: yes"; then
            return 0
        fi
    done

    return 1
}

function con_lista_enderecos_ip() {
    # Lista os endereços IPv4 de todas as interfaces de rede do sistema,
    # no formato "interface: endereço/prefixo".
    # Modo de uso: con_lista_enderecos_ip
    #              ip_local=$(con_lista_enderecos_ip | grep eth0)
    ip -o -4 addr show | awk '{print $2 ": " $4}'
}
