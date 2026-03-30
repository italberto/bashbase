# shellcheck shell=bash
# jboss.sh - Operações de alto nível para JBoss/WildFly
#
# Fornece funções para verificar disponibilidade, inspecionar deployments e
# consultar o estado de instâncias JBoss/WildFly via porta HTTP de aplicação
# e porta de management. As funções aceitam host e porta opcionais; quando
# omitidos, usam localhost e as portas padrão (8080 para aplicação, 9990
# para management).
#
# A API de management do WildFly é acessada via HTTP (curl). Para operações
# que requerem autenticação, configure as variáveis JBOSS_MGMT_USER e
# JBOSS_MGMT_PASS antes de chamar as funções.
#
# Este módulo pertence à camada de serviços da biblioteca (lib/servicos/).
#
# Dependências: redes.sh, alerta.sh, systemu.sh
#
# Funções disponíveis:
#   jboss_esta_rodando           [host] [porta]      - Verifica se o JBoss está acessível (porta HTTP)
#   jboss_management_disponivel  [host] [porta]      - Verifica se a porta de management está acessível
#   jboss_deployment_ativo       <app> [host] [porta] - Verifica se um deployment está no estado OK
#   jboss_listar_deployments     [host] [porta]      - Lista todos os deployments e seus estados
#   jboss_checar_saude           [host] [porta]      - Verifica o estado geral do servidor via management API
#   jboss_versao                 [host] [porta]      - Retorna a versão do servidor


[[ -n "${_SERVICOS_JBOSS_SH_LOADED:-}" ]] && return 0
readonly _SERVICOS_JBOSS_SH_LOADED=1

source "$(dirname "${BASH_SOURCE[0]}")/../redes.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../alerta.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../systemu.sh"

# Portas padrão do JBoss/WildFly
readonly _JBOSS_PORTA_HTTP_PADRAO=8080
readonly _JBOSS_PORTA_MGMT_PADRAO=9990

function _jboss_curl_mgmt() {
    # Executa uma chamada à API de management do WildFly via curl.
    # Usa JBOSS_MGMT_USER e JBOSS_MGMT_PASS se definidos.
    # Uso interno; não é parte da API pública do módulo.
    local host="$1"
    local porta="$2"
    local payload="$3"
    local url="http://${host}:${porta}/management"
    local args=(-s -X POST -H "Content-Type: application/json" -d "$payload")

    if [[ -n "${JBOSS_MGMT_USER:-}" && -n "${JBOSS_MGMT_PASS:-}" ]]; then
        args+=(--digest -u "${JBOSS_MGMT_USER}:${JBOSS_MGMT_PASS}")
    fi

    curl "${args[@]}" "$url" 2>/dev/null
}

function jboss_esta_rodando() {
    # Verifica se o JBoss/WildFly está aceitando conexões na porta HTTP.
    # Não requer curl — usa apenas con_checar_porta.
    # Retorna 0 se a porta estiver aberta, 1 caso contrário.
    # Modo de uso: jboss_esta_rodando
    #              jboss_esta_rodando "app.prod.local"
    #              jboss_esta_rodando "app.prod.local" 8180
    local host="${1:-localhost}"
    local porta="${2:-$_JBOSS_PORTA_HTTP_PADRAO}"
    con_checar_porta "$host" "$porta"
}

function jboss_management_disponivel() {
    # Verifica se a porta de management do JBoss/WildFly está acessível.
    # A porta de management (padrão 9990) expõe a API HTTP de administração.
    # Retorna 0 se a porta estiver aberta, 1 caso contrário.
    # Modo de uso: jboss_management_disponivel
    #              jboss_management_disponivel "app.prod.local"
    #              jboss_management_disponivel "app.prod.local" 19990
    local host="${1:-localhost}"
    local porta="${2:-$_JBOSS_PORTA_MGMT_PADRAO}"
    con_checar_porta "$host" "$porta"
}

function jboss_deployment_ativo() {
    # Verifica se um deployment está registrado e no estado OK no servidor.
    # Consulta a API de management; requer curl e acesso à porta de management.
    # O nome do deployment deve incluir a extensão (ex: "minha-app.war").
    # Retorna 0 se o deployment existir e estiver com status OK, 1 caso contrário.
    # Modo de uso: jboss_deployment_ativo "minha-app.war"
    #              jboss_deployment_ativo "minha-app.war" "app.local" 9990
    local app="$1"
    local host="${2:-localhost}"
    local porta="${3:-$_JBOSS_PORTA_MGMT_PADRAO}"

    if ! sys_programa_esta_instalado "curl"; then
        erro "curl não encontrado. Instale curl para usar esta função."
        return 1
    fi

    local payload
    payload=$(printf '{"operation":"read-attribute","address":[{"deployment":"%s"}],"name":"status"}' "$app")

    local resultado
    resultado=$(_jboss_curl_mgmt "$host" "$porta" "$payload")

    echo "$resultado" | grep -q '"result" : "OK"'
}

function jboss_listar_deployments() {
    # Lista todos os deployments registrados no servidor e seus estados.
    # Consulta a API de management e imprime no formato "nome: estado".
    # Requer curl e acesso à porta de management.
    # Retorna 1 se curl não estiver disponível ou em caso de erro de comunicação.
    # Modo de uso: jboss_listar_deployments
    #              jboss_listar_deployments "app.prod.local"
    local host="${1:-localhost}"
    local porta="${2:-$_JBOSS_PORTA_MGMT_PADRAO}"

    if ! sys_programa_esta_instalado "curl"; then
        erro "curl não encontrado. Instale curl para usar esta função."
        return 1
    fi

    local payload='{"operation":"read-children-resources","child-type":"deployment","include-runtime":true}'
    local resultado
    resultado=$(_jboss_curl_mgmt "$host" "$porta" "$payload")

    if [[ -z "$resultado" ]]; then
        erro "Sem resposta da API de management em ${host}:${porta}."
        return 1
    fi

    # Extrai pares nome/status do JSON de resposta com grep+sed simples,
    # sem dependência de jq
    echo "$resultado" | grep -oP '"[^"]+\.(?:war|jar|ear)"' | tr -d '"' | while IFS= read -r nome; do
        local status
        status=$(echo "$resultado" | grep -A5 "\"$nome\"" | grep '"status"' | grep -oP '"\K[^"]+(?=")')
        printf "%s: %s\n" "$nome" "${status:-desconhecido}"
    done
}

function jboss_checar_saude() {
    # Verifica o estado geral do servidor JBoss/WildFly via management API.
    # Consulta o atributo "server-state" do servidor; retorna 0 se for "running".
    # Requer curl e acesso à porta de management.
    # Retorna 1 se o servidor não estiver no estado "running" ou em caso de erro.
    # Modo de uso: jboss_checar_saude
    #              jboss_checar_saude "app.prod.local" || alerta "JBoss fora do ar"
    local host="${1:-localhost}"
    local porta="${2:-$_JBOSS_PORTA_MGMT_PADRAO}"

    if ! sys_programa_esta_instalado "curl"; then
        erro "curl não encontrado. Instale curl para usar esta função."
        return 1
    fi

    local payload='{"operation":"read-attribute","name":"server-state"}'
    local resultado
    resultado=$(_jboss_curl_mgmt "$host" "$porta" "$payload")

    echo "$resultado" | grep -q '"result" : "running"'
}

function jboss_versao() {
    # Retorna a versão do servidor JBoss/WildFly como string.
    # Consulta o atributo "product-version" via management API.
    # Requer curl e acesso à porta de management.
    # Imprime a versão no stdout (ex: "26.1.3.Final").
    # Retorna 1 se curl não estiver disponível ou em caso de erro.
    # Modo de uso: jboss_versao
    #              jboss_versao "app.prod.local"
    #              versao=$(jboss_versao) && info "WildFly $versao"
    local host="${1:-localhost}"
    local porta="${2:-$_JBOSS_PORTA_MGMT_PADRAO}"

    if ! sys_programa_esta_instalado "curl"; then
        erro "curl não encontrado. Instale curl para usar esta função."
        return 1
    fi

    local payload='{"operation":"read-attribute","name":"product-version"}'
    local resultado
    resultado=$(_jboss_curl_mgmt "$host" "$porta" "$payload")

    echo "$resultado" | grep -oP '"result" : "\K[^"]+'
}
