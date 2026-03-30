# shellcheck shell=bash
# downu.sh - Funções para download de arquivos via HTTP
#
# Detecta automaticamente a ferramenta de download disponível no sistema
# (wget, curl ou fallback TCP nativo via /dev/tcp) e realiza o download
# com a sintaxe correta de cada ferramenta.
#
# Quando DRYRUN="1", nenhum download é realizado nem arquivo criado:
# as funções imprimem no stderr o que seria feito e retornam 0.
#
# Dependências: systemu.sh, dryrun.sh
#
# Funções disponíveis:
#   dw_comando_de_download          - Detecta e retorna o nome da ferramenta de download disponível
#   baixar_nativo    <url> <destino>         - Download via TCP puro (sem wget/curl)
#   download         <url> [destino]         - Download com feedback no terminal
#   download_quieto  <url> [destino]         - Download sem saída no terminal


[[ -n "${_DOWNU_SH_LOADED:-}" ]] && return 0
readonly _DOWNU_SH_LOADED=1

source "$(dirname "${BASH_SOURCE[0]}")/systemu.sh"
source "$(dirname "${BASH_SOURCE[0]}")/dryrun.sh"

function dw_baixar_nativo() {
    # 1. Validação de parâmetros
    if [ "$#" -ne 2 ]; then
        echo "Uso: dw_baixar_nativo <URL> <arquivo_saida>"
        echo "Ex:  dw_baixar_nativo http://exemplo.com/pasta/arquivo.txt meu_arquivo.txt"
        return 1
    fi

    local url="$1"
    local arquivo_saida="$2"

    if [ "${DRYRUN:-}" = "1" ]; then
        echo "[DRY-RUN] dw_baixar_nativo: baixar '$url' → '$arquivo_saida'" >&2
        return 0
    fi

    # 2. Extração do Host e do Caminho da URL
    # Remove o prefixo "http://" se existir
    local url_limpa="${url#http://}"
    
    # Extrai o domínio (tudo antes da primeira barra)
    local host="${url_limpa%%/*}"
    
    # Extrai o caminho (tudo depois da primeira barra). Se não houver, assume "/"
    local path="/${url_limpa#*/}"
    if [ "$path" == "/$host" ]; then
        path="/"
    fi

    # 3. Execução da conexão TCP
    echo "Conectando a $host na porta 80..."
    
    # Tenta abrir o descritor de arquivo 3. Em caso de falha, exibe erro.
    if ! exec 3<>/dev/tcp/"$host"/80; then
        echo "Erro: Não foi possível conectar a $host"
        return 1
    fi

    echo "Baixando $path para $arquivo_saida..."

    # Envia a requisição HTTP GET
    echo -e "GET $path HTTP/1.1\r\nHost: $host\r\nConnection: close\r\n\r\n" >&3

    # 4. Tratamento do retorno
    # A resposta virá com os cabeçalhos HTTP. Precisamos remover isso.
    # O sed deleta tudo (1,/^\r$/d) desde a linha 1 até a primeira linha vazia (que separa os cabeçalhos do corpo do arquivo)
    cat <&3 | sed '1,/^\r$/d' > "$arquivo_saida"
    
    # Fecha o descritor de arquivo
    exec 3<&-
    exec 3>&-

    echo "Download concluído!"
}

function dw_comando_de_download() {
    if sys_programa_esta_instalado "wget"; then
        echo "wget"
    elif sys_programa_esta_instalado "curl"; then
        echo "curl"
    else
        echo "baixar_nativo"
    fi
}

function dw_download() {
    local url="$1"
    local destino="$2"

    if [ -z "$url" ]; then
        echo "Uso: dw_download <url> [arquivo_destino]"
        return 1
    fi

    if [ -z "$destino" ]; then
        destino="${url##*/}"
        destino="${destino%%\?*}"
    fi

    local cmd
    cmd=$(dw_comando_de_download)

    case "$cmd" in
        wget)
            dryrun_exec "dw_download: wget -O '$destino' '$url'" wget -O "$destino" "$url"
            ;;
        curl)
            dryrun_exec "dw_download: curl -L -o '$destino' '$url'" curl -L -o "$destino" "$url"
            ;;
        baixar_nativo)
            dw_baixar_nativo "$url" "$destino"
            ;;
    esac
}

function dw_download_quieto() {
    # Em dry-run, deixa as mensagens de simulação passarem (não suprime stderr)
    if [ "${DRYRUN:-}" = "1" ]; then
        dw_download "$@"
        return $?
    fi
    dw_download "$@" &>/dev/null
}