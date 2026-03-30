#!/usr/bin/env bash

set -euo pipefail

if [ -z "$BASHBASE" ]; then
    echo "Variável BASHBASE não definida."
    exit 1
fi

source "$BASHBASE/lib/servicos/jboss.sh"
source "$BASHBASE/lib/alerta.sh"

HOST="${1:-localhost}"
PORTA_HTTP="${2:-8080}"
PORTA_MGMT="${3:-9990}"

info "=== Diagnóstico JBoss/WildFly: ${HOST} ==="

# 1. Verificar se o servidor HTTP está respondendo
if ! jboss_esta_rodando "$HOST" "$PORTA_HTTP"; then
    erro "JBoss não está acessível em ${HOST}:${PORTA_HTTP}"
    exit 1
fi
sucesso "Servidor HTTP acessível (porta ${PORTA_HTTP})" 1

# 2. Verificar porta de management
if jboss_management_disponivel "$HOST" "$PORTA_MGMT"; then
    sucesso "Management acessível (porta ${PORTA_MGMT})" 1

    # 3. Versão (requer management)
    versao=$(jboss_versao "$HOST" "$PORTA_MGMT")
    if [ -n "$versao" ]; then
        info "Versão: $versao" 1
    fi

    # 4. Estado de saúde
    if jboss_checar_saude "$HOST" "$PORTA_MGMT"; then
        sucesso "Estado: running" 1
    else
        erro "Servidor não está no estado 'running'" 1
    fi

    # 5. Deployments
    info "Deployments:" 1
    jboss_listar_deployments "$HOST" "$PORTA_MGMT" | while IFS= read -r linha; do
        if echo "$linha" | grep -q "OK"; then
            sucesso "$linha" 2
        else
            alerta "$linha" 2
        fi
    done
else
    alerta "Management inacessível em ${HOST}:${PORTA_MGMT} — pulando verificações avançadas" 1
fi
