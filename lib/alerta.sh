# shellcheck shell=bash
# alerta.sh - Funções para exibição de mensagens formatadas e coloridas no terminal
#
# Fornece funções de alerta categorizadas por tipo (aviso, erro, sucesso, informação),
# com suporte a recuo (indentação) para hierarquia visual em saídas de scripts.
#
# Integração com logu.sh: se log_set_arquivo for chamado, todas as funções
# de alerta gravam automaticamente no arquivo de log (sem cores, com timestamp).
# O nível de log respeitado é o definido por log_set_nivel.
#   msg_alerta  → WARN
#   msg_erro    → ERRO
#   msg_sucesso → INFO
#   msg_info    → INFO
#
# Dependências: cores.sh, logu.sh
#
# Funções disponíveis:
#   msg_alerta  <mensagem> [recuo] - Exibe mensagem de aviso em amarelo
#   msg_erro    <mensagem> [recuo] - Exibe mensagem de erro em vermelho (stderr)
#   msg_sucesso <mensagem> [recuo] - Exibe mensagem de sucesso em verde
#   msg_info    <mensagem> [recuo] - Exibe mensagem informativa em azul
#   msg_debug   <mensagem> [recuo] - Exibe mensagem de diagnóstico (apenas se DEBUG=1)
#
# O parâmetro opcional [recuo] define o número de tabulações (\t) inseridas
# antes da mensagem, permitindo criar saídas hierárquicas visualmente organizadas.
# Exemplo com recuo 2: "		mensagem" (dois \t antes do texto)


[[ -n "${_ALERTA_SH_LOADED:-}" ]] && return 0
readonly _ALERTA_SH_LOADED=1

source "$(dirname "${BASH_SOURCE[0]}")/cores.sh"
source "$(dirname "${BASH_SOURCE[0]}")/logu.sh"

function msg_alerta() {
    # Exibe uma mensagem de aviso em amarelo.
    # Se log_set_arquivo estiver configurado, grava também no log como WARN.
    # Modo de uso: msg_alerta "Arquivo de configuração não encontrado"
    #              msg_alerta "Item ignorado" 2   (com 2 tabulações de recuo)
    local recuo
    if [ -n "$2" ]; then
        recuo=$(printf '\t%.0s' $(seq 1 "$2"))
    else
        recuo=""
    fi
    if [ -n "$1" ]; then
        cor_amarelo "${recuo}$1"
        [ -n "$_LOG_ARQUIVO" ] && log_escrever_apenas_arquivo "$_LOG_WARN" "WARN " "$1"
    fi
}

function msg_erro() {
    # Exibe uma mensagem de erro em vermelho.
    # Se log_set_arquivo estiver configurado, grava também no log como ERRO.
    # Modo de uso: msg_erro "Falha ao conectar ao servidor"
    #              msg_erro "Permissão negada" 1   (com 1 tabulação de recuo)
    local recuo
    if [ -n "$2" ]; then
        recuo=$(printf '\t%.0s' $(seq 1 "$2"))
    else
        recuo=""
    fi
    if [ -n "$1" ]; then
        cor_vermelho "${recuo}$1" >&2
        [ -n "$_LOG_ARQUIVO" ] && log_escrever_apenas_arquivo "$_LOG_ERRO" "ERRO " "$1"
    fi
}

function msg_sucesso() {
    # Exibe uma mensagem de sucesso em verde.
    # Se log_set_arquivo estiver configurado, grava também no log como INFO.
    # Modo de uso: msg_sucesso "Instalação concluída com sucesso"
    #              msg_sucesso "Arquivo copiado" 1   (com 1 tabulação de recuo)
    local recuo
    if [ -n "$2" ]; then
        recuo=$(printf '\t%.0s' $(seq 1 "$2"))
    else
        recuo=""
    fi
    if [ -n "$1" ]; then
        cor_verde "${recuo}$1"
        [ -n "$_LOG_ARQUIVO" ] && log_escrever_apenas_arquivo "$_LOG_INFO" "INFO " "$1"
    fi
}

function msg_info() {
    # Exibe uma mensagem informativa em azul.
    # Se log_set_arquivo estiver configurado, grava também no log como INFO.
    # Modo de uso: msg_info "Iniciando sincronização dos arquivos..."
    #              msg_info "Processando item 3 de 10" 1   (com 1 tabulação de recuo)
    local recuo
    if [ -n "$2" ]; then
        recuo=$(printf '\t%.0s' $(seq 1 "$2"))
    else
        recuo=""
    fi
    if [ -n "$1" ]; then
        cor_azul "${recuo}$1"
        [ -n "$_LOG_ARQUIVO" ] && log_escrever_apenas_arquivo "$_LOG_INFO" "INFO " "$1"
    fi
}

function msg_debug() {
    # Exibe uma mensagem de diagnóstico em cinza escuro, prefixada com [DEBUG].
    # Só produz saída quando a variável de ambiente DEBUG estiver definida como "1".
    # Modo de uso: DEBUG=1 ./meu_script.sh
    # Se log_set_arquivo estiver configurado, grava no log como DEBUG independente
    # do valor de DEBUG (o nível mínimo de log controla a gravação em arquivo).
    # Modo de uso: msg_debug "variável x = $x"
    #              msg_debug "entrando na função foo" 1   (com 1 tabulação de recuo)
    local recuo
    if [ -n "$2" ]; then
        recuo=$(printf '\t%.0s' $(seq 1 "$2"))
    else
        recuo=""
    fi
    if [ -n "$1" ]; then
        [ "${DEBUG:-0}" = "1" ] && echo -e "\033[90m${recuo}[DEBUG] $1\033[0m"
        [ -n "$_LOG_ARQUIVO" ] && log_escrever_apenas_arquivo "$_LOG_DEBUG" "DEBUG" "$1"
    fi
}
