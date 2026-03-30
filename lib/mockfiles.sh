# shellcheck shell=bash
# mockfiles.sh - Funções para criação de arquivos fictícios para testes
#
# Fornece três métodos diferentes para gerar arquivos com dados aleatórios,
# úteis para testar scripts que manipulam arquivos sem depender de dados reais.
#
# Métodos disponíveis:
#   dd      - Lê bytes aleatórios de /dev/urandom em blocos de 1KB (dado real)
#   head    - Captura N bytes diretamente de /dev/urandom (dado real)
#   truncate - Cria arquivo do tamanho informado com conteúdo nulo (dado fictício)
#
# Nota: dd e head criam arquivos com dados verdadeiramente aleatórios.
#       truncate cria arquivos esparsos, muito mais rápido mas sem dados reais.
#
# Quando DRYRUN="1", nenhum arquivo é criado: as funções imprimem no stderr
# o que seria feito e retornam 0.
#
# Dependências: nenhuma
#
# Funções disponíveis:
#   criar_arquivo_aleatorio          <nome> <tamanho_kb> - Cria arquivo via dd
#   criar_arquivo_aleatorio_head     <nome> <tamanho_kb> - Cria arquivo via head
#   criar_arquivo_aleatorio_truncate <nome> <tamanho_kb> - Cria arquivo via truncate


[[ -n "${_MOCKFILES_SH_LOADED:-}" ]] && return 0
readonly _MOCKFILES_SH_LOADED=1

function criar_arquivo_aleatorio() {
    # Cria um arquivo com dados aleatórios reais usando dd e /dev/urandom.
    # O arquivo terá exatamente <tamanho_kb> kilobytes de dados aleatórios.
    # Método mais lento, mas garante conteúdo aleatório em cada byte.
    # Em dry-run: imprime o que seria criado sem tocar no disco.
    # Modo de uso: criar_arquivo_aleatorio arquivo_teste.bin 512
    local nome_arquivo="$1"
    local tamanho="$2"
    if [[ -n "$nome_arquivo" && -n "$tamanho" ]]; then
        if [ "${DRYRUN:-}" = "1" ]; then
            echo "[DRY-RUN] criar_arquivo_aleatorio: dd if=/dev/urandom of='$nome_arquivo' bs=1K count=$tamanho" >&2
            return 0
        fi
        dd if=/dev/urandom of="$nome_arquivo" bs=1K count="$tamanho" status=none
    else
        echo "Uso: criar_arquivo_aleatorio NOME_DO_ARQUIVO TAMANHO_EM_KB"
        return 1
    fi
}

function criar_arquivo_aleatorio_head() {
    # Cria um arquivo com dados aleatórios reais usando head e /dev/urandom.
    # Alternativa ao dd para sistemas onde head é mais eficiente.
    # O arquivo terá exatamente <tamanho_kb> kilobytes de dados aleatórios.
    # Em dry-run: imprime o que seria criado sem tocar no disco.
    # Modo de uso: criar_arquivo_aleatorio_head arquivo_teste.bin 512
    local nome_arquivo="$1"
    local tamanho="$2"
    if [[ -n "$nome_arquivo" && -n "$tamanho" ]]; then
        if [ "${DRYRUN:-}" = "1" ]; then
            echo "[DRY-RUN] criar_arquivo_aleatorio_head: head -c $((tamanho * 1024)) /dev/urandom > '$nome_arquivo'" >&2
            return 0
        fi
        head -c $((tamanho * 1024)) /dev/urandom > "$nome_arquivo"
    else
        echo "Uso: criar_arquivo_aleatorio_head NOME_DO_ARQUIVO TAMANHO_EM_KB"
        return 1
    fi
}

function criar_arquivo_aleatorio_truncate() {
    # Cria um arquivo esparso do tamanho especificado usando truncate.
    # O arquivo é criado instantaneamente independente do tamanho, pois
    # o conteúdo é nulo (zeros) e não é fisicamente alocado em disco.
    # Ideal para testes de tamanho de arquivo sem necessidade de dados reais.
    # Em dry-run: imprime o que seria criado sem tocar no disco.
    # Modo de uso: criar_arquivo_aleatorio_truncate arquivo_teste.bin 1024
    local nome_arquivo="$1"
    local tamanho="$2"
    if [[ -n "$nome_arquivo" && -n "$tamanho" ]]; then
        if [ "${DRYRUN:-}" = "1" ]; then
            echo "[DRY-RUN] criar_arquivo_aleatorio_truncate: truncate -s $((tamanho * 1024)) '$nome_arquivo'" >&2
            return 0
        fi
        truncate -s $((tamanho * 1024)) "$nome_arquivo"
    else
        echo "Uso: criar_arquivo_aleatorio_truncate NOME_DO_ARQUIVO TAMANHO_EM_KB"
        return 1
    fi
}
