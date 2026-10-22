# shellcheck shell=bash
# configu.sh - Funções para leitura e escrita de arquivos de configuração
#
# Trabalha com arquivos no formato CHAVE=valor, compatível com o padrão .env.
# Suporta valores com ou sem aspas e ignora comentários e linhas em branco.
#
# Quando DRYRUN="1", config_escrever, config_remover e config_carregar simulam
# suas operações sem modificar ou exportar nada.
#
# Dependências: dryrun.sh
#
# Funções disponíveis:
#   config_ler       <arquivo> <chave>         - Lê o valor de uma chave
#   config_existe    <arquivo> <chave>         - Verifica se uma chave existe
#   config_escrever  <arquivo> <chave> <valor> - Cria ou atualiza uma chave
#   config_remover   <arquivo> <chave>         - Remove uma chave do arquivo
#   config_carregar  <arquivo>                 - Exporta todas as chaves como variáveis de ambiente


[[ -n "${_CONFIGU_SH_LOADED:-}" ]] && return 0
readonly _CONFIGU_SH_LOADED=1

source "$(dirname "${BASH_SOURCE[0]}")/dryrun.sh"

function _config_primeira_linha() {
    # Imprime a primeira linha de <arquivo> que começa com "<chave>=".
    # A comparação é literal (a chave nunca é interpretada como regex),
    # mas ancorada no início da linha via index()==1.
    # Retorna 1 se o arquivo não existir ou nenhuma linha casar.
    local arquivo="$1"
    local chave="$2"
    awk -v k="${chave}=" 'index($0, k) == 1 { print; achou=1; exit } END { exit !achou }' "$arquivo" 2>/dev/null
}

function _config_reescrever() {
    # Reescreve <arquivo> aplicando o filtro awk recebido, preservando o
    # arquivo original (inode/permissões) via cópia do conteúdo.
    # Usado por config_escrever e config_remover. Não usa regex: a chave é
    # sempre comparada literalmente com index(), evitando injeção de padrões.
    local arquivo="$1"
    shift
    local tmp rc
    tmp=$(mktemp) || return 1
    if awk "$@" "$arquivo" > "$tmp"; then
        cat "$tmp" > "$arquivo"
        rc=$?
    else
        rc=1
    fi
    rm -f "$tmp"
    return "$rc"
}

function config_ler() {
    # Lê e retorna o valor de uma chave em um arquivo de configuração.
    # Remove aspas simples e duplas simétricas ao redor do valor, se presentes.
    # Retorna 1 se o arquivo não existir ou a chave não for encontrada.
    # Distingue corretamente chave ausente de chave com valor vazio.
    # Modo de uso: valor=$(config_ler /etc/app/config.env DB_HOST)
    local arquivo="$1"
    local chave="$2"

    if [ ! -f "$arquivo" ]; then
        return 1
    fi

    # Localiza a primeira linha "chave=..." e extrai o valor. O retorno 1 do
    # helper distingue corretamente chave ausente de chave com valor vazio.
    local linha valor
    linha=$(_config_primeira_linha "$arquivo" "$chave") || return 1
    valor="${linha#*=}"

    # Remove aspas simétricas ao redor do valor
    if [[ ( "$valor" == \"*\" ) || ( "$valor" == \'*\' ) ]]; then
        valor="${valor:1:${#valor}-2}"
    fi

    echo "$valor"
}

function config_existe() {
    # Retorna 0 se a chave existir no arquivo de configuração, 1 caso contrário.
    # Não lê nem retorna o valor — use config_ler para isso.
    # Retorna 1 também se o arquivo não existir.
    # Modo de uso: config_existe /etc/app.conf "DATABASE_URL" || erro "Configuração incompleta"
    local arquivo="$1"
    local chave="$2"
    [[ ! -f "$arquivo" ]] && return 1
    _config_primeira_linha "$arquivo" "$chave" >/dev/null
}

function config_escrever() {
    # Cria ou atualiza uma chave no arquivo de configuração.
    # Se a chave já existir, seu valor é substituído na mesma linha.
    # Se não existir, a chave é adicionada ao final do arquivo.
    # O arquivo é criado automaticamente se não existir.
    # Modo de uso: config_escrever /etc/app/config.env DB_PORT 5432
    local arquivo="$1"
    local chave="$2"
    local valor="$3"

    if _config_primeira_linha "$arquivo" "$chave" >/dev/null; then
        # Substitui a primeira ocorrência de "chave=..." por "chave=valor".
        # Comparação literal via index(); chave e valor passam por variáveis
        # awk (-v), sem interpretação de regex.
        dryrun_exec "config_escrever: substituir '${chave}' em '$arquivo'" \
            _config_reescrever "$arquivo" \
            -v k="${chave}=" -v nova="${chave}=${valor}" \
            '!feito && index($0, k) == 1 { print nova; feito=1; next } { print }'
    else
        dryrun_gravar "$arquivo" "${chave}=${valor}"
    fi
}

function config_remover() {
    # Remove uma chave e seu valor do arquivo de configuração.
    # Retorna 1 se o arquivo não existir.
    # Modo de uso: config_remover /etc/app/config.env DB_PASSWORD
    local arquivo="$1"
    local chave="$2"

    if [ ! -f "$arquivo" ]; then
        return 1
    fi

    # Remove toda linha "chave=...". Comparação literal via index(), sem regex.
    dryrun_exec "config_remover: remover '${chave}' de '$arquivo'" \
        _config_reescrever "$arquivo" \
        -v k="${chave}=" 'index($0, k) == 1 { next } { print }'
}

function config_carregar() {
    # Importa todas as chaves do arquivo como variáveis de ambiente exportadas.
    # Linhas em branco e comentários (iniciados com #) são ignorados.
    # Aspas simples e duplas simétricas ao redor dos valores são removidas.
    # Chaves com formato inválido são ignoradas com aviso no stderr.
    # Modo de uso: config_carregar /etc/app/config.env
    #              echo $DB_HOST   # variável agora disponível no script
    local arquivo="$1"

    if [ ! -f "$arquivo" ]; then
        echo "Arquivo não encontrado: $arquivo" >&2
        return 1
    fi

    if [ "${DRYRUN:-}" = "1" ]; then
        echo "[DRY-RUN] config_carregar: não exportar variáveis de '$arquivo'" >&2
        return 0
    fi

    local linha chave valor
    while IFS= read -r linha || [[ -n "$linha" ]]; do
        # Ignora linhas vazias e comentários
        [[ -z "$linha" || "$linha" =~ ^[[:space:]]*# ]] && continue

        # Extrai chave e valor separando apenas no primeiro =
        chave="${linha%%=*}"
        valor="${linha#*=}"

        # Remove espaços ao redor da chave
        chave="${chave//[[:space:]]/}"

        # Valida formato da chave: letras, números e underscore; não pode iniciar com número
        if [[ ! "$chave" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
            echo "config_carregar: chave inválida ignorada: '$chave'" >&2
            continue
        fi

        # Remove aspas simétricas ao redor do valor
        if [[ ( "$valor" == \"*\" ) || ( "$valor" == \'*\' ) ]]; then
            valor="${valor:1:${#valor}-2}"
        fi

        export "$chave=$valor"
    done < "$arquivo"
}
