#!/usr/bin/env bash
# exemplo_metricsu.sh - Demonstração das funções do módulo metricsu.sh
#
# Cenário: pipeline de processamento de dados com observabilidade completa.
# Ao final exibe relatório de métricas e exporta no formato Prometheus.
#
# Uso:
#   bash exemplo_metricsu.sh           # execução normal
#   DRYRUN=1 bash exemplo_metricsu.sh  # simulação sem efeitos

set -euo pipefail

if [ -z "$BASHBASE" ]; then
    echo "Variável BASHBASE não definida."
    exit 1
fi

source "$BASHBASE/lib/metricsu.sh"
source "$BASHBASE/lib/alerta.sh"

# Diretório de métricas explícito para facilitar inspeção após execução
metric_iniciar "/tmp/bashbase_metrics_exemplo"

# Threshold de lentidão reduzido para o exemplo disparar o aviso
_METRICSU__SLOW_MS=300

# ---------------------------------------------------------------------------
# Funções que simulam operações reais
# ---------------------------------------------------------------------------

validar_arquivo() {
    local arquivo="$1"
    sleep 0.1
    # Simula falha de validação em arquivos com "corrompido" no nome
    [[ "$arquivo" == *corrompido* ]] && { echo "Validação falhou: $arquivo" >&2; return 1; }
    echo "Validado: $arquivo"
}

processar_lote() {
    local lote="$1"
    local n_itens="$2"
    sleep 0.2
    echo "Lote $lote: $n_itens itens processados"
    metric_incrementar "itens.processados" "$n_itens"
}

sincronizar_destino() {
    local destino="$1"
    sleep 0.4
    echo "Sincronizado com $destino"
}

operacao_lenta() {
    sleep 0.5   # ultrapassa o threshold de 300ms para disparar aviso
    echo "Operação lenta concluída"
}

export -f validar_arquivo processar_lote sincronizar_destino operacao_lenta
export _METRICSU__DIR _METRICSU__SLOW_MS

# ---------------------------------------------------------------------------
# Exemplo 1 — metric_wrap
# Envolve comandos individualmente, registrando tempo e contadores
# de sucesso/erro automaticamente.
# ---------------------------------------------------------------------------

msg_alerta "Exemplo 1: metric_wrap — cronometragem e contagem automáticas"

arquivos=("dados_jan.csv" "dados_fev.csv" "dados_corrompido.csv" "dados_mar.csv")

for arq in "${arquivos[@]}"; do
    metric_wrap "validacao" validar_arquivo "$arq" && \
        metric_incrementar "arquivos.aceitos" || \
        metric_incrementar "arquivos.rejeitados"
done

# ---------------------------------------------------------------------------
# Exemplo 2 — metric_incrementar
# Contadores manuais em pontos de controle do fluxo.
# ---------------------------------------------------------------------------

msg_alerta "Exemplo 2: metric_incrementar — contadores manuais"

lotes=(
    "lote_A 150"
    "lote_B 240"
    "lote_C 180"
)

for entrada in "${lotes[@]}"; do
    lote="${entrada% *}"
    n="${entrada#* }"
    metric_wrap "processamento" processar_lote "$lote" "$n"
    metric_incrementar "lotes.concluidos"
done

# ---------------------------------------------------------------------------
# Exemplo 3 — metric_registrar_tempo
# Registro manual de tempo quando você já controla a medição.
# ---------------------------------------------------------------------------

msg_alerta "Exemplo 3: metric_registrar_tempo — registro manual"

inicio=$(date +%s%N)
sincronizar_destino "s3://bucket-producao"
fim=$(date +%s%N)
duracao_ms=$(( (fim - inicio) / 1000000 ))

metric_registrar_tempo "sincronizacao" "$duracao_ms"
metric_incrementar "sincronizacoes.realizadas"

# ---------------------------------------------------------------------------
# Exemplo 4 — detecção de comando lento
# metric_wrap emite aviso no stderr quando o tempo ultrapassa
# _METRICSU__SLOW_MS (configurado para 300ms no início deste script).
# ---------------------------------------------------------------------------

msg_alerta "Exemplo 4: detecção de comando lento (threshold: ${_METRICSU__SLOW_MS}ms)"

metric_wrap "compactacao" operacao_lenta

# ---------------------------------------------------------------------------
# Relatório final
# ---------------------------------------------------------------------------

echo ""
msg_alerta "Relatório de métricas"
echo "---"
metric_exibir

# ---------------------------------------------------------------------------
# Exportação Prometheus
# ---------------------------------------------------------------------------

PROM_FILE="/tmp/bashbase_exemplo.prom"
msg_alerta "Exportação Prometheus → $PROM_FILE"
metric_exportar_prometheus > "$PROM_FILE"
echo ""
cat "$PROM_FILE"

rm -f "$PROM_FILE"
metric_resetar

exit 0
