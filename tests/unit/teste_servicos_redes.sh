#!/usr/bin/env bash
# Testes unitários para lib/redes.sh e lib/servicos/conectividade.sh
# Verifica comportamento com portas fechadas e funções auxiliares sem
# dependência de serviço externo real.

BASHBASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$BASHBASE/lib/redes.sh"
source "$BASHBASE/lib/servicos/conectividade.sh"

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

echo "=== redes.sh ==="

assert_retorna_1 "con_checar_porta: porta 1 em localhost deve falhar" \
    con_checar_porta localhost 1 1

assert_retorna_1 "con_checar_porta: host inexistente deve falhar" \
    con_checar_porta "host.invalido.local" 80 1

assert_retorna_1 "con_checar_interface: interface inexistente deve retornar 1" \
    con_checar_interface "iface_inexistente_xyz"

assert_retorna_0 "con_checar_interface: interface lo deve existir" \
    con_checar_interface lo

assert_retorna_0 "con_checar_gateway: deve haver gateway em ambiente normal" \
    con_checar_gateway

echo ""
echo "=== servicos/conectividade.sh ==="

assert_retorna_1 "con_ssh_disponivel: host inválido deve retornar 1" \
    con_ssh_disponivel "host.invalido.local"

assert_retorna_1 "con_http_disponivel: host inválido deve retornar 1" \
    con_http_disponivel "host.invalido.local"

assert_retorna_1 "con_https_disponivel: host inválido deve retornar 1" \
    con_https_disponivel "host.invalido.local"

echo ""
echo "=== Resultado ==="
echo "Passou: $passou | Falhou: $falhou"
[ "$falhou" -eq 0 ]
