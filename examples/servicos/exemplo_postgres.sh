#!/usr/bin/env bash

set -euo pipefail

if [ -z "$BASHBASE" ]; then
    echo "Variável BASHBASE não definida."
    exit 1
fi

source "$BASHBASE/lib/servicos/postgres.sh"
source "$BASHBASE/lib/alerta.sh"

HOST="${1:-localhost}"
PORTA="${2:-5432}"

info "=== Diagnóstico PostgreSQL: ${HOST}:${PORTA} ==="

# 1. Verificar se o servidor está rodando
if ! pg_esta_rodando "$HOST" "$PORTA"; then
    erro "PostgreSQL não está acessível em ${HOST}:${PORTA}"
    exit 1
fi
sucesso "Servidor acessível" 1

# 2. Versão
versao=$(pg_versao "$HOST" "$PORTA")
info "Versão: $versao" 1

# 3. Conexões ativas
total=$(pg_contar_conexoes "" "$HOST" "$PORTA")
info "Conexões ativas: $total" 1

# 4. Verificar banco de exemplo
BANCO="${3:-postgres}"
if pg_banco_existe "$BANCO" "$HOST" "$PORTA"; then
    sucesso "Banco '$BANCO' encontrado" 1
    conexoes_banco=$(pg_contar_conexoes "$BANCO" "$HOST" "$PORTA")
    info "Conexões em '$BANCO': $conexoes_banco" 2
else
    alerta "Banco '$BANCO' não encontrado" 1
fi

# 5. Replicação
if pg_checar_replicacao "$HOST" "$PORTA"; then
    sucesso "Replicação ativa" 1
else
    alerta "Sem réplicas conectadas" 1
fi
