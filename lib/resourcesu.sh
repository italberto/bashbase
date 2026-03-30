# shellcheck shell=bash
# resourcesu.sh - Funções para monitoramento de recursos do sistema
#
# Fornece funções para consultar informações sobre CPU, memória e disco,
# além de listar as interfaces de rede disponíveis no sistema.
# Depende de arquivos do sistema de arquivos virtual /proc (Linux).
#
# Todas as funções numéricas retornam números puros sem unidade ou símbolo,
# deixando a formatação e interpretação a cargo do chamador.
#   - Funções memoria_*  : retornam valor inteiro em kB
#   - Funções uso_*      : retornam percentual inteiro (0-100)
#
# Dependências: nenhuma
#
# Funções disponíveis:
#   modelo_de_cpu            - Retorna o modelo do processador (string)
#   memoria_total            - Retorna a memória RAM total em kB
#   memoria_disponivel       - Retorna a memória RAM disponível em kB
#   memoria_usada            - Retorna a memória RAM em uso em kB
#   uso_do_disco  [caminho]  - Retorna o percentual de uso do disco (0-100)
#   uso_da_cpu               - Retorna o percentual de uso da CPU (0-100)
#   uso_da_memoria           - Retorna o percentual de uso da memória (0-100)
#   lista_interfaces_de_rede - Lista as interfaces de rede disponíveis


[[ -n "${_RESOURCESU_SH_LOADED:-}" ]] && return 0
readonly _RESOURCESU_SH_LOADED=1

function modelo_de_cpu() {
    # Retorna o modelo do processador lendo /proc/cpuinfo.
    # Em sistemas sem /proc/cpuinfo (ex: macOS), retorna "Desconhecido".
    # Modo de uso: echo "CPU: $(modelo_de_cpu)"
    if [ -f /proc/cpuinfo ]; then
        grep "model name" /proc/cpuinfo | head -n 1 | cut -d: -f2 | sed 's/^[ \t]*//'
    else
        echo "Desconhecido"
    fi
}

function memoria_total() {
    # Retorna a memória RAM total instalada no sistema como inteiro em kB.
    # Modo de uso: total=$(memoria_total)
    #              echo "RAM total: $((total / 1024)) MB"
    if [ -f /proc/meminfo ]; then
        awk '/MemTotal/{print $2}' /proc/meminfo
    else
        echo "0"
    fi
}

function memoria_disponivel() {
    # Retorna a memória RAM disponível para novos processos como inteiro em kB.
    # Usa MemAvailable (mais precisa que MemFree, inclui cache liberável).
    # Modo de uso: disp=$(memoria_disponivel)
    #              echo "Disponível: $((disp / 1024)) MB"
    if [ -f /proc/meminfo ]; then
        awk '/MemAvailable/{print $2}' /proc/meminfo
    else
        echo "0"
    fi
}

function memoria_usada() {
    # Retorna a memória RAM em uso como inteiro em kB,
    # calculada como MemTotal - MemAvailable.
    # Modo de uso: usada=$(memoria_usada)
    #              echo "Em uso: $((usada / 1024)) MB"
    if [ -f /proc/meminfo ]; then
        awk '/MemTotal/{total=$2} /MemAvailable/{avail=$2} END{print total-avail}' /proc/meminfo
    else
        echo "0"
    fi
}

function uso_do_disco() {
    # Retorna o percentual de uso do disco como inteiro (0-100).
    # Se um caminho for fornecido, usa o sistema de arquivos daquele caminho.
    # Caso contrário, usa o sistema de arquivos raiz (/).
    # Modo de uso: uso=$(uso_do_disco)
    #              uso=$(uso_do_disco /var/log)
    #              [ "$uso" -gt 90 ] && erro "Disco quase cheio: ${uso}%"
    df "${1:-/}" | awk 'NR==2{gsub(/%/,"",$5); print $5}'
}

function uso_da_cpu() {
    # Retorna o percentual de uso da CPU como inteiro (0-100).
    # Calculado como 100 menos o tempo ocioso reportado pelo top.
    # Modo de uso: cpu=$(uso_da_cpu)
    #              [ "$cpu" -gt 80 ] && alerta "CPU acima de 80%: ${cpu}%"
    top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{printf "%d", 100 - $1}'
}

function uso_da_memoria() {
    # Retorna o percentual de uso da memória RAM como inteiro (0-100).
    # Modo de uso: mem=$(uso_da_memoria)
    #              [ "$mem" -gt 90 ] && erro "Memória crítica: ${mem}%"
    free -m | awk 'NR==2{printf "%d", $3*100/$2}'
}

function lista_interfaces_de_rede() {
    # Lista os nomes de todas as interfaces de rede disponíveis no sistema,
    # uma por linha, usando o comando ip.
    # Modo de uso: lista_interfaces_de_rede
    ip -o link show | awk -F': ' '{print $2}'
}
