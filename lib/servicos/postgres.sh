# shellcheck shell=bash
# postgres.sh - Operações de alto nível para PostgreSQL
#
# Fornece funções para verificar disponibilidade, inspecionar bancos de dados
# e executar queries em instâncias PostgreSQL. As funções aceitam host e porta
# opcionais; quando omitidos, usam localhost e a porta padrão 5432.
#
# Requer que o cliente psql esteja instalado para operações além da verificação
# de porta. As funções de query usam autenticação via variáveis de ambiente
# padrão do PostgreSQL (PGUSER, PGPASSWORD, PGHOST, etc.) ou os parâmetros
# explícitos fornecidos.
#
# Este módulo pertence à camada de serviços da biblioteca (lib/servicos/).
#
# Dependências: redes.sh, alerta.sh, systemu.sh
#
# Funções disponíveis:
#   pg_esta_rodando       [host] [porta]        - Verifica se o PostgreSQL está acessível
#   pg_banco_existe       <banco> [host] [porta] - Verifica se um banco de dados existe
#   pg_executar_sql       <sql> [banco] [host] [porta] - Executa uma query e imprime o resultado
#   pg_contar_conexoes    [banco] [host] [porta] - Conta conexões ativas
#   pg_versao             [host] [porta]         - Retorna a versão do servidor
#   pg_checar_replicacao  [host] [porta]         - Verifica se há réplicas conectadas


[[ -n "${_SERVICOS_POSTGRES_SH_LOADED:-}" ]] && return 0
readonly _SERVICOS_POSTGRES_SH_LOADED=1

source "$(dirname "${BASH_SOURCE[0]}")/../redes.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../alerta.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../systemu.sh"

# Porta padrão do PostgreSQL
readonly _PG_PORTA_PADRAO=5432

function pg_esta_rodando() {
    # Verifica se o PostgreSQL está aceitando conexões TCP na porta informada.
    # Não requer psql instalado — usa apenas con_checar_porta.
    # Retorna 0 se a porta estiver aberta, 1 caso contrário.
    # Modo de uso: pg_esta_rodando
    #              pg_esta_rodando "db.prod.local"
    #              pg_esta_rodando "db.prod.local" 5433
    local host="${1:-localhost}"
    local porta="${2:-$_PG_PORTA_PADRAO}"
    con_checar_porta "$host" "$porta"
}

function pg_banco_existe() {
    # Verifica se um banco de dados existe na instância PostgreSQL.
    # Requer psql instalado e credenciais com acesso ao catálogo do sistema.
    # Retorna 0 se o banco existir, 1 caso contrário ou em caso de erro.
    # Modo de uso: pg_banco_existe "meubanco"
    #              pg_banco_existe "meubanco" "db.local" 5432
    local banco="$1"
    local host="${2:-localhost}"
    local porta="${3:-$_PG_PORTA_PADRAO}"

    if ! sys_programa_esta_instalado "psql"; then
        erro "psql não encontrado. Instale o cliente PostgreSQL para usar esta função."
        return 1
    fi

    local resultado
    resultado=$(psql -h "$host" -p "$porta" -tAc \
        "SELECT 1 FROM pg_database WHERE datname = '$banco'" 2>/dev/null)

    [[ "$resultado" == "1" ]]
}

function pg_executar_sql() {
    # Executa uma query SQL no PostgreSQL e imprime o resultado no stdout.
    # Requer psql instalado e credenciais adequadas.
    # Retorna 0 em caso de sucesso, 1 em caso de erro.
    # Modo de uso: pg_executar_sql "SELECT COUNT(*) FROM usuarios" "meubanco"
    #              pg_executar_sql "SELECT versao FROM config LIMIT 1" "app" "db.local"
    local sql="$1"
    local banco="${2:-postgres}"
    local host="${3:-localhost}"
    local porta="${4:-$_PG_PORTA_PADRAO}"

    if ! sys_programa_esta_instalado "psql"; then
        erro "psql não encontrado. Instale o cliente PostgreSQL para usar esta função."
        return 1
    fi

    psql -h "$host" -p "$porta" -d "$banco" -tAc "$sql" 2>/dev/null
}

function pg_contar_conexoes() {
    # Conta o número de conexões ativas na instância ou em um banco específico.
    # Quando banco é omitido ou vazio, conta todas as conexões da instância.
    # Requer psql instalado e acesso à view pg_stat_activity.
    # Imprime o número de conexões no stdout como inteiro puro.
    # Retorna 1 se psql não estiver disponível ou em caso de erro.
    # Modo de uso: pg_contar_conexoes
    #              pg_contar_conexoes "meubanco"
    #              total=$(pg_contar_conexoes "app" "db.local")
    local banco="${1:-}"
    local host="${2:-localhost}"
    local porta="${3:-$_PG_PORTA_PADRAO}"

    if ! sys_programa_esta_instalado "psql"; then
        erro "psql não encontrado. Instale o cliente PostgreSQL para usar esta função."
        return 1
    fi

    local filtro_banco=""
    if [[ -n "$banco" ]]; then
        filtro_banco="WHERE datname = '$banco'"
    fi

    pg_executar_sql \
        "SELECT COUNT(*) FROM pg_stat_activity $filtro_banco" \
        "postgres" "$host" "$porta"
}

function pg_versao() {
    # Retorna a versão do servidor PostgreSQL como string.
    # Requer psql instalado e acesso à instância.
    # Imprime a versão no stdout (ex: "PostgreSQL 15.3").
    # Retorna 1 se psql não estiver disponível ou em caso de erro.
    # Modo de uso: pg_versao
    #              pg_versao "db.prod.local"
    #              versao=$(pg_versao) && info "Versão: $versao"
    local host="${1:-localhost}"
    local porta="${2:-$_PG_PORTA_PADRAO}"

    if ! sys_programa_esta_instalado "psql"; then
        erro "psql não encontrado. Instale o cliente PostgreSQL para usar esta função."
        return 1
    fi

    pg_executar_sql "SELECT version()" "postgres" "$host" "$porta" | awk '{print $1, $2}'
}

function pg_checar_replicacao() {
    # Verifica se há réplicas (standby) conectadas ao servidor primário.
    # Consulta pg_stat_replication; retorna 0 se houver ao menos uma réplica ativa.
    # Retorna 1 se não houver réplicas ou em caso de erro.
    # Requer acesso ao servidor primário com permissão de leitura em pg_stat_replication.
    # Modo de uso: pg_checar_replicacao
    #              pg_checar_replicacao "db-primary.local" || alerta "Sem réplica ativa"
    local host="${1:-localhost}"
    local porta="${2:-$_PG_PORTA_PADRAO}"

    if ! sys_programa_esta_instalado "psql"; then
        erro "psql não encontrado. Instale o cliente PostgreSQL para usar esta função."
        return 1
    fi

    local contagem
    contagem=$(pg_executar_sql \
        "SELECT COUNT(*) FROM pg_stat_replication WHERE state = 'streaming'" \
        "postgres" "$host" "$porta")

    [[ "$contagem" =~ ^[0-9]+$ ]] && [[ "$contagem" -gt 0 ]]
}
