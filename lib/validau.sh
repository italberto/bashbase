# shellcheck shell=bash
# validau.sh - Funções para validação de dados de entrada
#
# Fornece validações para os tipos de dados mais comuns em scripts de automação.
# Todas as funções retornam 0 se o valor for válido e 1 caso contrário,
# seguindo a convenção de retorno do Bash para uso em condicionais.
#
# Dependências: nenhuma
#
# Funções disponíveis:
#   valida_ip            <string>          - Valida endereço IPv4
#   valida_email         <string>          - Valida formato de e-mail
#   valida_url           <string>          - Valida URL com esquema http/https/ftp
#   valida_porta         <numero>          - Valida número de porta (1-65535)
#   variavel_obrigatoria <nome> [mensagem] - Aborta se variável de ambiente não estiver definida


[[ -n "${_VALIDAU_SH_LOADED:-}" ]] && return 0
readonly _VALIDAU_SH_LOADED=1

function valida_ip() {
    # Verifica se a string é um endereço IPv4 válido no formato A.B.C.D,
    # onde cada octeto está entre 0 e 255.
    # Modo de uso: valida_ip "192.168.1.1" && echo "IP válido"
    local ip="$1"
    local regex='^([0-9]{1,3}\.){3}[0-9]{1,3}$'

    if [[ ! "$ip" =~ $regex ]]; then
        return 1
    fi

    # Verifica se cada octeto está no intervalo válido (0-255)
    local IFS='.'
    local partes
    read -ra partes <<< "$ip"
    for parte in "${partes[@]}"; do
        if [ "$parte" -gt 255 ]; then
            return 1
        fi
    done

    return 0
}

function valida_email() {
    # Valida o formato de um endereço de e-mail.
    # Aceita caracteres alfanuméricos e os especiais . _ % + - antes do @,
    # domínios com múltiplos níveis (ex: user@mail.co.uk) e extensões de 2+
    # caracteres. Não valida a existência real do endereço.
    # Modo de uso: valida_email "usuario@dominio.com" && echo "E-mail válido"
    local email="$1"
    local regex='^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    [[ "$email" =~ $regex ]]
}

function valida_url() {
    # Verifica se a string é uma URL com esquema válido (http, https ou ftp)
    # seguido de host e caminho opcional.
    # Modo de uso: valida_url "https://exemplo.com/pagina" && echo "URL válida"
    local url="$1"
    local regex='^(https?|ftp)://[a-zA-Z0-9.-]+(:[0-9]+)?(/.*)?$'
    [[ "$url" =~ $regex ]]
}

function valida_porta() {
    # Verifica se o valor é um número de porta TCP/UDP válido (entre 1 e 65535).
    # Modo de uso: valida_porta "8080" && echo "Porta válida"
    local porta="$1"
    [[ "$porta" =~ ^[0-9]+$ ]] && [ "$porta" -ge 1 ] && [ "$porta" -le 65535 ]
}

function variavel_obrigatoria() {
    # Verifica se uma variável de ambiente está definida e não está vazia.
    # Se não estiver, exibe uma mensagem de erro e encerra o script com código 1.
    # Útil para garantir que configurações críticas foram fornecidas antes
    # de iniciar operações que dependem delas.
    # Modo de uso: variavel_obrigatoria DB_HOST
    #              variavel_obrigatoria API_KEY "A chave da API é obrigatória"
    local nome="$1"
    local mensagem="${2:-Variável de ambiente obrigatória não definida: $nome}"

    if [ -z "${!nome}" ]; then
        echo "ERRO: $mensagem" >&2
        exit 1
    fi
}

