# shellcheck shell=bash
# logu.sh - Funções para logging estruturado em scripts de automação
#
# Grava mensagens com timestamp, nível e opcionalmente em arquivo.
# Suporta quatro níveis de log: DEBUG, INFO, WARN e ERRO.
# O nível mínimo pode ser configurado para filtrar mensagens menos relevantes.
#
# Quando DRYRUN="1", apenas log_rodar é suprimida (a rotação não ocorre).
# As funções de escrita (log_info, log_erro, etc.) continuam funcionando
# normalmente em dry-run, pois o log serve como trilha de auditoria do que
# seria executado.
#
# Dependências: nenhuma
#
# Funções disponíveis:
#   log_set_arquivo  <caminho>          - Define o arquivo de destino dos logs
#   log_set_nivel    <nivel>            - Define o nível mínimo (0=DEBUG..3=ERRO)
#   log_debug        <mensagem>         - Registra mensagem de nível DEBUG
#   log_info         <mensagem>         - Registra mensagem de nível INFO
#   log_warn         <mensagem>         - Registra mensagem de nível WARN
#   log_erro         <mensagem>         - Registra mensagem de nível ERRO
#   log_rodar                <arquivo> [limite]       - Rotaciona o log ao atingir o tamanho limite
#   log_escrever_apenas_arquivo <nivel> <str> <msg>  - Grava no arquivo sem output no terminal (API pública)


[[ -n "${_LOGU_SH_LOADED:-}" ]] && return 0
readonly _LOGU_SH_LOADED=1

# Caminho do arquivo de log (vazio = apenas saída no terminal)
_LOG__ARQUIVO=""

# Nível mínimo de log exibido/gravado (0=DEBUG, 1=INFO, 2=WARN, 3=ERRO)
# IMPORTANTE: os valores de nível são NUMÉRICOS inteiros (0-3).
# Não use strings ("DEBUG", "true") — as comparações usam -lt/-ge.
_LOG__NIVEL_MINIMO=0

# Constantes de nível
readonly _LOG__DEBUG=0
readonly _LOG__INFO=1
readonly _LOG__WARN=2
readonly _LOG__ERRO=3

function log_set_arquivo() {
    # Define o arquivo de destino para gravação dos logs.
    # Se o diretório não existir, tenta criá-lo.
    # Modo de uso: log_set_arquivo /var/log/meu_script.log
    local arquivo="$1"
    local diretorio
    diretorio=$(dirname "$arquivo")

    if [ ! -d "$diretorio" ]; then
        mkdir -p "$diretorio" || { echo "ERRO: Não foi possível criar o diretório de log: $diretorio" >&2; return 1; }
    fi

    _LOG__ARQUIVO="$arquivo"
}

function log_set_nivel() {
    # Define o nível mínimo de log a ser exibido e gravado.
    # Mensagens abaixo desse nível são silenciadas.
    # Modo de uso: log_set_nivel 1   (1=INFO, ignora DEBUG)
    _LOG__NIVEL_MINIMO="$1"
}

function _log_escrever() {
    # Função interna: formata e escreve uma entrada de log.
    # Parâmetros: <nivel_numerico> <nivel_string> <mensagem> [apenas_arquivo]
    # O parâmetro opcional apenas_arquivo=1 suprime a saída no terminal,
    # gravando somente no arquivo. Usado internamente por alerta.sh para evitar
    # duplicação de output (terminal já é tratado pelas funções coloridas).
    local nivel_num="$1"
    local nivel_str="$2"
    local mensagem="$3"
    local apenas_arquivo="${4:-0}"

    [ "$nivel_num" -lt "$_LOG__NIVEL_MINIMO" ] && return 0

    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local linha="[$timestamp] [$nivel_str] $mensagem"

    if [ "$apenas_arquivo" -eq 0 ]; then
        if [ "$nivel_num" -ge "$_LOG__ERRO" ]; then
            echo "$linha" >&2
        else
            echo "$linha"
        fi
    fi

    if [ -n "$_LOG__ARQUIVO" ]; then
        echo "$linha" >> "$_LOG__ARQUIVO"
    fi
}

function log_debug() {
    # Registra uma mensagem de nível DEBUG.
    # Útil para informações detalhadas de diagnóstico durante desenvolvimento.
    # Modo de uso: log_debug "variavel x = $x"
    _log_escrever "$_LOG__DEBUG" "DEBUG" "$1"
}

function log_info() {
    # Registra uma mensagem de nível INFO.
    # Usado para confirmar que o script está operando normalmente.
    # Modo de uso: log_info "Serviço iniciado com sucesso"
    _log_escrever "$_LOG__INFO" "INFO " "$1"
}

function log_warn() {
    # Registra uma mensagem de nível WARN.
    # Indica uma situação inesperada que não impede a execução.
    # Modo de uso: log_warn "Arquivo de configuração não encontrado, usando padrão"
    _log_escrever "$_LOG__WARN" "WARN " "$1"
}

function log_erro() {
    # Registra uma mensagem de nível ERRO.
    # Indica uma falha que pode impedir a execução correta do script.
    # Modo de uso: log_erro "Falha ao conectar ao banco de dados"
    _log_escrever "$_LOG__ERRO" "ERRO " "$1"
}

function log_escrever_apenas_arquivo() {
    # Grava uma mensagem diretamente no arquivo de log sem exibir no terminal.
    # API pública que permite a módulos externos (como alerta.sh) integrarem-se
    # com o sistema de log sem acessar a função interna _log_escrever.
    # Não faz nada se nenhum arquivo de log estiver configurado.
    # Modo de uso: log_escrever_apenas_arquivo $LOG_WARN "WARN " "mensagem"
    _log_escrever "$1" "$2" "$3" 1
}

function log_rodar() {
    # Rotaciona o arquivo de log quando seu tamanho ultrapassa o limite definido.
    # Copia o conteúdo atual para um arquivo com timestamp e zera o arquivo original
    # via truncate, preservando o inode. Processos com o descritor já aberto
    # continuam escrevendo no arquivo ativo sem perda de dados.
    # Aceita sufixos K (kilobytes), M (megabytes) e G (gigabytes).
    # Modo de uso: log_rodar /var/log/app.log 10M
    local arquivo="$1"
    local tamanho_max="${2:-10M}"

    if [ ! -f "$arquivo" ]; then
        echo "ERRO: Arquivo de log não encontrado: $arquivo" >&2
        return 1
    fi

    local tamanho_atual
    tamanho_atual=$(stat -c "%s" "$arquivo")

    local limite
    case "$tamanho_max" in
        *K) limite=$(( ${tamanho_max%K} * 1024 )) ;;
        *M) limite=$(( ${tamanho_max%M} * 1024 * 1024 )) ;;
        *G) limite=$(( ${tamanho_max%G} * 1024 * 1024 * 1024 )) ;;
        *)  limite="$tamanho_max" ;;
    esac

    if [ "$tamanho_atual" -ge "$limite" ]; then
        local timestamp
        timestamp=$(date '+%Y%m%d_%H%M%S')
        local arquivo_rotacionado="${arquivo}.${timestamp}"
        if [ "${DRYRUN:-}" = "1" ]; then
            echo "[DRY-RUN] log_rodar: '$arquivo' → '$arquivo_rotacionado' (truncate suprimido)" >&2
            return 0
        fi
        cp "$arquivo" "$arquivo_rotacionado" && truncate -s 0 "$arquivo"
        echo "Log rotacionado: $arquivo_rotacionado"
    fi
}
