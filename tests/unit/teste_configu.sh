#!/usr/bin/env bash
# Testes unitários para lib/configu.sh
# Cobre leitura, escrita, existência e remoção de chaves, incluindo os casos
# que regrediram em 1.2.1 (ver config_ler/config_existe/config_escrever).

BASHBASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$BASHBASE/lib/configu.sh"

passou=0
falhou=0

function assert_retorna_0() {
    local descricao="$1"
    shift
    if "$@"; then
        echo "[OK] $descricao"
        (( passou++ ))
    else
        echo "[FALHOU] $descricao"
        (( falhou++ ))
    fi
}

function assert_retorna_1() {
    local descricao="$1"
    shift
    if ! "$@"; then
        echo "[OK] $descricao"
        (( passou++ ))
    else
        echo "[FALHOU] $descricao"
        (( falhou++ ))
    fi
}

function assert_igual() {
    local descricao="$1" esperado="$2" obtido="$3"
    if [ "$esperado" = "$obtido" ]; then
        echo "[OK] $descricao"
        (( passou++ ))
    else
        echo "[FALHOU] $descricao (esperado='$esperado' obtido='$obtido')"
        (( falhou++ ))
    fi
}

ARQ="$(mktemp)"
trap 'rm -f "$ARQ"' EXIT
printf 'DB_HOST=localhost\nDB_PORT=5432\n# comentario\nVAZIO=\nCITADO="com espaco"\n' > "$ARQ"

echo "=== config_ler ==="

assert_igual "config_ler lê chave existente" \
    "localhost" "$(config_ler "$ARQ" DB_HOST)"

assert_igual "config_ler lê segunda chave" \
    "5432" "$(config_ler "$ARQ" DB_PORT)"

assert_igual "config_ler remove aspas simétricas" \
    "com espaco" "$(config_ler "$ARQ" CITADO)"

assert_igual "config_ler distingue valor vazio de ausente" \
    "" "$(config_ler "$ARQ" VAZIO)"

assert_retorna_0 "config_ler: chave com valor vazio retorna 0" \
    config_ler "$ARQ" VAZIO

assert_retorna_1 "config_ler: chave ausente retorna 1" \
    config_ler "$ARQ" NAO_EXISTE

assert_retorna_1 "config_ler: arquivo inexistente retorna 1" \
    config_ler "/nao/existe.env" DB_HOST

echo ""
echo "=== config_existe ==="

assert_retorna_0 "config_existe: chave existente" \
    config_existe "$ARQ" DB_HOST

assert_retorna_1 "config_existe: chave ausente" \
    config_existe "$ARQ" NAO_EXISTE

assert_retorna_1 "config_existe: não casa prefixo parcial" \
    config_existe "$ARQ" DB_HO

echo ""
echo "=== config_escrever ==="

config_escrever "$ARQ" DB_HOST novohost
assert_igual "config_escrever atualiza valor existente" \
    "novohost" "$(config_ler "$ARQ" DB_HOST)"

assert_igual "config_escrever atualiza in-place sem duplicar" \
    "1" "$(grep -c '^DB_HOST=' "$ARQ")"

config_escrever "$ARQ" NOVA_CHAVE valor123
assert_igual "config_escrever adiciona chave nova" \
    "valor123" "$(config_ler "$ARQ" NOVA_CHAVE)"

# Chave/valor com caracteres que seriam especiais em regex/sed devem ser
# tratados literalmente (motivação do endurecimento de segurança do módulo).
config_escrever "$ARQ" "A.B*C" "val&com|pipe"
assert_igual "config_escrever trata chave com metacaracteres literalmente" \
    "val&com|pipe" "$(config_ler "$ARQ" "A.B*C")"
assert_retorna_1 "metacaracteres não casam como regex (A.B*C não casa AXBC)" \
    config_existe "$ARQ" "AXBBBC"

echo ""
echo "=== config_remover ==="

config_remover "$ARQ" DB_PORT
assert_retorna_1 "config_remover remove a chave" \
    config_existe "$ARQ" DB_PORT

assert_retorna_0 "config_remover preserva outras chaves" \
    config_existe "$ARQ" DB_HOST

echo ""
echo "=== Resultado ==="
echo "Passou: $passou | Falhou: $falhou"
[ "$falhou" -eq 0 ]
