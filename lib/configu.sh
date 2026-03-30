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

function config_ler() {
    # Lê e retorna o valor de uma chave em um arquivo de configuração.
    # Remove aspas simples e duplas ao redor do valor, se presentes.
    # Retorna 1 se o arquivo não existir ou a chave não for encontrada.
    # Modo de uso: valor=$(config_ler /etc/app/config.env DB_HOST)
    local arquivo="$1"
    local chave="$2"

    if [ ! -f "$arquivo" ]; then
        return 1
    fi


    local valor
    valor=$(grep -F "^${chave}=" "$arquivo" | cut -d'=' -f2-)

    if [ -z "$valor" ]; then
        return 1
    fi

    # Remove aspas ao redor do valor
    local valor
    valor="${valor#[\'\"]}"
    valor="${valor%[\'\"]}"

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
    grep -qE "^${chave}=" "$arquivo"
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

    if grep -qE "^${chave}=" "$arquivo" 2>/dev/null; then
        local valor_esc="${valor//\\/\\\\}"
        valor_esc="${valor_esc//&/\\&}"
        valor_esc="${valor_esc//|/\\|}"
        dryrun_exec "config_escrever: substituir '${chave}' em '$arquivo'" \
            sed -i "s|^${chave}=.*|${chave}=${valor_esc}|" "$arquivo"
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

    dryrun_exec "config_remover: remover '${chave}' de '$arquivo'" \
        sed -i "/^${chave}=/d" "$arquivo"
}

function config_carregar() {
    # Importa todas as chaves do arquivo como variáveis de ambiente exportadas.
    # Linhas em branco e comentários (iniciados com #) são ignorados.
    # Aspas simples e duplas ao redor dos valores são removidas automaticamente.
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

    while IFS='=' read -r chave valor; do
        # Ignora linhas vazias e comentários
        [[ -z "$chave" || "$chave" =~ ^[[:space:]]*# ]] && continue

        # Remove espaços ao redor da chave
        chave="${chave//[[:space:]]/}"

        # Remove aspas ao redor do valor
        valor="${valor#[\'\"]}"
        valor="${valor%[\'\"]}"

        export "$chave=$valor"
    done < "$arquivo"
}
