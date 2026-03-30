# shellcheck shell=bash
# backupu.sh - Funções para backup de arquivos e diretórios
#
# Fornece utilitários para criar cópias de segurança com timestamps automáticos
# e limpeza periódica de backups antigos.
#
# Quando DRYRUN="1", nenhuma operação de disco é executada: as funções imprimem
# no stderr o que seria feito e retornam 0.
#
# Dependências: nenhuma
#
# Funções disponíveis:
#   backup_arquivo         <arquivo> [destino]  - Copia arquivo com timestamp no nome
#   backup_diretorio       <dir>    [destino]   - Compacta diretório em .tar.gz com timestamp
#   limpar_backups_antigos <dir>    [dias]      - Remove backups com mais de N dias


[[ -n "${_BACKUPU_SH_LOADED:-}" ]] && return 0
readonly _BACKUPU_SH_LOADED=1

function backup_arquivo() {
    # Cria uma cópia de segurança de um arquivo adicionando timestamp ao nome.
    # O arquivo de backup é criado no mesmo diretório do original por padrão,
    # ou no diretório de destino informado como segundo parâmetro.
    # Em caso de sucesso, imprime o caminho do arquivo de backup criado.
    # Em dry-run: imprime o caminho que seria criado sem copiar nada.
    # Modo de uso: backup_arquivo /etc/nginx/nginx.conf
    #              backup_arquivo /etc/nginx/nginx.conf /var/backups
    local arquivo
    arquivo="$1"
    local destino="${2:-$(dirname "$arquivo")}"

    if [ ! -f "$arquivo" ]; then
        echo "Arquivo não encontrado: $arquivo" >&2
        return 1
    fi

    if [ ! -d "$destino" ]; then
        echo "Diretório de destino não encontrado: $destino" >&2
        return 1
    fi

    local nome_base
    nome_base=$(basename "$arquivo")
    local timestamp
    timestamp=$(date '+%Y%m%d_%H%M%S')
    local destino_final="${destino}/${nome_base}.${timestamp}.bak"

    if [ "${DRYRUN:-}" = "1" ]; then
        echo "[DRY-RUN] backup_arquivo: cp '$arquivo' '$destino_final'" >&2
        echo "$destino_final"
        return 0
    fi

    cp "$arquivo" "$destino_final" && echo "$destino_final"
}

function backup_diretorio() {
    # Compacta um diretório inteiro em um arquivo .tar.gz com timestamp no nome.
    # O arquivo resultante é criado no diretório de destino informado,
    # ou no diretório atual se nenhum destino for fornecido.
    # Em caso de sucesso, imprime o caminho do arquivo .tar.gz criado.
    # Em dry-run: imprime o caminho que seria criado sem compactar nada.
    # Modo de uso: backup_diretorio /var/www/html
    #              backup_diretorio /var/www/html /var/backups
    local diretorio
    diretorio="$1"
    local destino="${2:-.}"

    if [ ! -d "$diretorio" ]; then
        echo "Diretório não encontrado: $diretorio" >&2
        return 1
    fi

    local nome_base
    nome_base=$(basename "$diretorio")
    local timestamp
    timestamp=$(date '+%Y%m%d_%H%M%S')
    local arquivo_saida="${destino}/${nome_base}_${timestamp}.tar.gz"

    if [ "${DRYRUN:-}" = "1" ]; then
        echo "[DRY-RUN] backup_diretorio: tar -czf '$arquivo_saida' '$diretorio'" >&2
        echo "$arquivo_saida"
        return 0
    fi

    tar -czf "$arquivo_saida" -C "$(dirname "$diretorio")" "$nome_base" && echo "$arquivo_saida"
}

function limpar_backups_antigos() {
    # Remove arquivos de backup (.bak e .tar.gz) com mais de N dias em um diretório.
    # A busca é feita apenas no nível raiz do diretório (sem recursão).
    # O valor padrão de dias é 30 caso não seja informado.
    # Em dry-run: lista os arquivos que seriam removidos sem deletar nada.
    # Modo de uso: limpar_backups_antigos /var/backups 15
    local diretorio
    diretorio="$1"
    local dias="${2:-30}"

    if [ ! -d "$diretorio" ]; then
        echo "Diretório não encontrado: $diretorio" >&2
        return 1
    fi

    if [ "${DRYRUN:-}" = "1" ]; then
        find "$diretorio" -maxdepth 1 \( -name "*.bak" -o -name "*.tar.gz" \) -mtime +"$dias" \
            -exec echo "[DRY-RUN] limpar_backups_antigos: remover {}" \; >&2
        return 0
    fi

    find "$diretorio" -maxdepth 1 \( -name "*.bak" -o -name "*.tar.gz" \) -mtime +"$dias" -exec rm -f {} \;
}
