#!/usr/bin/env bash
# exemplo_paralelo.sh - Demonstração das funções do módulo paralelo.sh
#
# Cenário simulado: pipeline de deploy em múltiplos servidores.
# Cada etapa ilustra uma função diferente do módulo.
#
# Uso:
#   bash exemplo_paralelo.sh           # execução normal
#   DRYRUN=1 bash exemplo_paralelo.sh  # simulação sem efeitos

set -euo pipefail

if [ -z "$BASHBASE" ]; then
    echo "Variável BASHBASE não definida."
    exit 1
fi

source "$BASHBASE/lib/paralelo.sh"
source "$BASHBASE/lib/alerta.sh"

# ---------------------------------------------------------------------------
# Funções auxiliares que simulam operações reais
# ---------------------------------------------------------------------------

verificar_host() {
    local host="$1"
    sleep 0.3
    # Simula falha no host srv3 para demonstrar detecção de erros
    [[ "$host" == "srv3" ]] && { echo "Host $host inacessível"; return 1; }
    echo "Host $host respondendo"
}

fazer_backup() {
    local origem="$1"
    sleep 0.2
    echo "Backup de $origem concluído: ${origem##*/}_$(date +%Y%m%d).tar.gz"
}

processar_arquivo() {
    local arquivo="$1"
    sleep 0.1
    echo "Processado: $arquivo"
}

deploy_servidor() {
    local servidor="$1"
    sleep 0.4
    echo "Deploy em $servidor: versão 1.0.0 instalada"
}

# Exporta funções auxiliares para que os subshells criados pelo paralelo.sh
# tenham acesso a elas ao executar os jobs em background.
export -f verificar_host fazer_backup processar_arquivo deploy_servidor

# ---------------------------------------------------------------------------
# Exemplo 1 — paralelo_executar
# Checagem de saúde em múltiplos hosts ao mesmo tempo.
# Todos os jobs são disparados sem limite de concorrência.
# ---------------------------------------------------------------------------

msg_alerta "Exemplo 1: checagem de hosts em paralelo (paralelo_executar)"

paralelo_executar \
    "verificar_host srv1" \
    "verificar_host srv2" \
    "verificar_host srv3" \
    "verificar_host srv4"

if [ $? -eq 0 ]; then
    msg_sucesso "Todos os hosts responderam"
else
    msg_info "Um ou mais hosts falharam — verificar antes de continuar"
fi

separador() { printf '\n%.0s' {1..1}; }
separador

# ---------------------------------------------------------------------------
# Exemplo 2 — paralelo_map
# Backup de múltiplos diretórios aplicando a mesma operação a cada um.
# Concorrência limitada a 2 para não sobrecarregar o disco.
# ---------------------------------------------------------------------------

msg_alerta "Exemplo 2: backup de diretórios em paralelo (paralelo_map)"

paralelo_map 2 "fazer_backup" \
    /var/log/app \
    /var/log/nginx \
    /var/lib/postgres \
    /var/lib/redis \
    /etc/app

msg_sucesso "Backups concluídos"
separador

# ---------------------------------------------------------------------------
# Exemplo 3 — paralelo_pool
# Processamento de arquivos de log com pool fixo de workers.
# Novos jobs entram na fila à medida que os anteriores terminam.
# ---------------------------------------------------------------------------

msg_alerta "Exemplo 3: processamento de logs com pool (paralelo_pool)"

arquivos=(
    "access_2026-03-01.log"
    "access_2026-03-02.log"
    "access_2026-03-03.log"
    "access_2026-03-04.log"
    "access_2026-03-05.log"
    "access_2026-03-06.log"
)

cmds=()
for arq in "${arquivos[@]}"; do
    cmds+=("processar_arquivo $arq")
done

paralelo_pool 3 "${cmds[@]}"
msg_sucesso "Todos os logs processados"
separador

# ---------------------------------------------------------------------------
# Exemplo 4 — paralelo_com_timeout
# Deploy em servidores com tempo máximo garantido.
# Se algum servidor travar, o timeout encerra tudo e retorna 124.
# ---------------------------------------------------------------------------

msg_alerta "Exemplo 4: deploy com timeout global (paralelo_com_timeout)"

paralelo_com_timeout 10 2 \
    "deploy_servidor prod-us-east-1" \
    "deploy_servidor prod-us-west-1" \
    "deploy_servidor prod-eu-west-1" \
    "deploy_servidor prod-ap-south-1"

status=$?
if [ "$status" -eq 0 ]; then
    msg_sucesso "Deploy concluído em todos os servidores"
elif [ "$status" -eq 124 ]; then
    msg_erro "Deploy abortado: timeout atingido"
    exit 1
else
    msg_erro "Deploy falhou em um ou mais servidores (código $status)"
    exit "$status"
fi

exit 0
