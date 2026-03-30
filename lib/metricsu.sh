# shellcheck shell=bash
# metricsu.sh - Observabilidade de execução: contadores, tempos e detecção de comandos lentos
#
# Registra métricas de execução de comandos (contadores e tempos) em arquivos
# no diretório de métricas. Contadores usam flock para garantir atomicidade
# em contextos de execução paralela (paralelo.sh). A saída pode ser exibida
# em formato legível ou exportada no formato Prometheus text format.
#
# O diretório de métricas é isolado por PID por padrão, evitando colisão
# entre scripts distintos rodando simultaneamente.
#
# Quando DRYRUN="1", nenhuma métrica é gravada: as funções descrevem no
# stderr o que seria registrado e retornam 0.
#
# Dependências: dryrun.sh
#
# Variáveis configuráveis:
#   _METRICSU__DIR      - Diretório de armazenamento (padrão: /tmp/bashbase_metrics_PID)
#   _METRICSU__SLOW_MS  - Threshold em ms para alerta de comando lento (padrão: 5000, 0=desativado)
#
# Funções disponíveis:
#   metric_iniciar              [dir]                 - Inicializa (opcional: diretório personalizado)
#   metric_incrementar          <nome> [delta]        - Incrementa um contador
#   metric_registrar_tempo      <nome> <ms>           - Registra uma amostra de tempo
#   metric_wrap                 <nome> <cmd...>       - Cronometra e conta automaticamente um comando
#   metric_exibir                                     - Exibe todas as métricas de forma legível
#   metric_resetar                                    - Remove e recria o diretório de métricas
#   metric_exportar_prometheus                        - Exporta métricas no formato Prometheus text


[[ -n "${_METRICSU_SH_LOADED:-}" ]] && return 0
readonly _METRICSU_SH_LOADED=1

source "$(dirname "${BASH_SOURCE[0]}")/dryrun.sh"

# Diretório isolado por PID para evitar colisão entre processos distintos
_METRICSU__DIR="${TMPDIR:-/tmp}/bashbase_metrics_$$"

# Threshold em ms para detecção de comandos lentos (0 = desativado)
_METRICSU__SLOW_MS=5000

# ---------------------------------------------------------------------------
# Funções internas
# ---------------------------------------------------------------------------

function _metricsu_garantir_dir() {
    [[ -d "$_METRICSU__DIR" ]] || mkdir -p "$_METRICSU__DIR"
}

# ---------------------------------------------------------------------------
# Funções públicas
# ---------------------------------------------------------------------------

function metric_iniciar() {
    # Inicializa o diretório de métricas e cria a estrutura necessária.
    # Se não for chamada explicitamente, o diretório é criado automaticamente
    # na primeira operação de registro. Use esta função para definir um
    # diretório persistente (ex: para integração com node_exporter).
    # Modo de uso:
    #   metric_iniciar                         # usa padrão /tmp/bashbase_metrics_PID
    #   metric_iniciar /var/lib/node_exporter  # diretório persistente para Prometheus
    local dir="${1:-$_METRICSU__DIR}"
    _METRICSU__DIR="$dir"
    mkdir -p "$_METRICSU__DIR"
}

function metric_incrementar() {
    # Incrementa um contador pelo nome. O arquivo de contador é atualizado
    # de forma atômica via flock, garantindo segurança em execuções paralelas.
    # O delta padrão é 1; valores maiores podem ser passados como segundo argumento.
    # Modo de uso:
    #   metric_incrementar "deploy.sucesso"
    #   metric_incrementar "retry.tentativa"
    #   metric_incrementar "itens.processados" 10
    local nome="$1"
    local delta="${2:-1}"

    if dryrun_ativo; then
        echo "[DRY-RUN] metric_incrementar: ${nome} += ${delta}" >&2
        return 0
    fi

    _metricsu_garantir_dir
    local arquivo="$_METRICSU__DIR/${nome}.count"

    (
        flock 9
        local valor=0
        [[ -f "$arquivo" ]] && valor=$(<"$arquivo")
        echo $(( valor + delta )) > "$arquivo"
    ) 9>"$_METRICSU__DIR/${nome}.lock"
}

function metric_registrar_tempo() {
    # Registra uma amostra de tempo em milissegundos para uma métrica nomeada.
    # Cada chamada acrescenta uma linha ao arquivo de tempos da métrica.
    # Use metric_wrap para registrar tempo automaticamente ao executar um comando.
    # Modo de uso:
    #   metric_registrar_tempo "backup" 3420
    #   metric_registrar_tempo "deploy.etapa1" "$duracao_ms"
    local nome="$1"
    local ms="$2"

    if dryrun_ativo; then
        echo "[DRY-RUN] metric_registrar_tempo: ${nome} = ${ms}ms" >&2
        return 0
    fi

    _metricsu_garantir_dir
    echo "$ms" >> "$_METRICSU__DIR/${nome}.time"
}

function metric_wrap() {
    # Executa um comando e registra automaticamente seu tempo de execução
    # e resultado (sucesso/erro) como métricas nomeadas.
    # Cria as métricas <nome>.time, <nome>.sucesso e <nome>.erro.
    # Emite aviso no stderr se o tempo ultrapassar _METRICSU__SLOW_MS.
    # Retorna o mesmo exit code do comando executado.
    # Modo de uso:
    #   metric_wrap "backup"  rsync -av /src/ /dst/
    #   metric_wrap "deploy"  bash deploy.sh --env prod
    #   metric_wrap "sync"    minha_funcao arg1 arg2
    local nome="$1"
    shift

    if dryrun_ativo; then
        echo "[DRY-RUN] metric_wrap: ${nome} → $*" >&2
        return 0
    fi

    local inicio fim duracao_ms
    inicio=$(date +%s%N)

    "$@"
    local status=$?

    fim=$(date +%s%N)
    duracao_ms=$(( (fim - inicio) / 1000000 ))

    metric_registrar_tempo "$nome" "$duracao_ms"

    if [[ "$status" -eq 0 ]]; then
        metric_incrementar "${nome}.sucesso"
    else
        metric_incrementar "${nome}.erro"
    fi

    if [[ "$_METRICSU__SLOW_MS" -gt 0 && "$duracao_ms" -gt "$_METRICSU__SLOW_MS" ]]; then
        echo "[METRICSU] Comando lento detectado: ${nome} (${duracao_ms}ms > threshold ${_METRICSU__SLOW_MS}ms)" >&2
    fi

    return "$status"
}

function metric_exibir() {
    # Exibe todas as métricas registradas em formato legível.
    # Contadores mostram o valor acumulado.
    # Tempos mostram número de amostras, mínimo, máximo e média em ms.
    # Modo de uso: metric_exibir
    _metricsu_garantir_dir

    local tem_dados=0

    # Contadores
    local contadores=()
    for f in "$_METRICSU__DIR"/*.count; do
        [[ -f "$f" ]] && contadores+=("$f")
    done

    if [[ ${#contadores[@]} -gt 0 ]]; then
        tem_dados=1
        echo "Contadores:"
        for f in "${contadores[@]}"; do
            local nome valor
            nome=$(basename "$f" .count)
            valor=$(<"$f")
            printf "  %-44s %s\n" "$nome" "$valor"
        done
        echo ""
    fi

    # Tempos
    local tempos=()
    for f in "$_METRICSU__DIR"/*.time; do
        [[ -f "$f" ]] && tempos+=("$f")
    done

    if [[ ${#tempos[@]} -gt 0 ]]; then
        tem_dados=1
        echo "Tempos (ms):"
        for f in "${tempos[@]}"; do
            local nome
            nome=$(basename "$f" .time)
            awk -v nome="$nome" '
                BEGIN { min = 2^31; max = 0; sum = 0; count = 0 }
                /^[0-9]+$/ {
                    val = $1 + 0
                    if (val < min) min = val
                    if (val > max) max = val
                    sum += val
                    count++
                }
                END {
                    if (count == 0) exit
                    printf "  %-44s n=%-5d min=%-7dms max=%-7dms avg=%dms\n",
                        nome, count, min, max, int(sum / count)
                }
            ' "$f"
        done
        echo ""
    fi

    if [[ "$tem_dados" -eq 0 ]]; then
        echo "  (nenhuma métrica registrada em $_METRICSU__DIR)"
    fi
}

function metric_resetar() {
    # Remove todas as métricas registradas e recria o diretório vazio.
    # Útil para reiniciar a contagem entre execuções num mesmo processo.
    # Modo de uso: metric_resetar
    if dryrun_ativo; then
        echo "[DRY-RUN] metric_resetar: removeria e recriaria '$_METRICSU__DIR'" >&2
        return 0
    fi

    [[ -d "$_METRICSU__DIR" ]] && rm -rf "$_METRICSU__DIR"
    mkdir -p "$_METRICSU__DIR"
}

function metric_exportar_prometheus() {
    # Exporta todas as métricas no formato Prometheus text (exposition format).
    # Contadores são exportados com sufixo _total e TYPE counter.
    # Tempos são exportados como _sum e _count com TYPE gauge/counter,
    # permitindo calcular a média no PromQL com sum/count.
    # Pontos e hífens nos nomes são convertidos para underscores.
    # Modo de uso:
    #   metric_exportar_prometheus                         # imprime no stdout
    #   metric_exportar_prometheus > /var/lib/node_exporter/bashbase.prom
    _metricsu_garantir_dir

    # Contadores
    for f in "$_METRICSU__DIR"/*.count; do
        [[ -f "$f" ]] || continue
        local nome valor nome_prom
        nome=$(basename "$f" .count)
        valor=$(<"$f")
        nome_prom="bashbase_$(echo "$nome" | tr '.-' '__')_total"

        echo "# HELP ${nome_prom} Contador bashbase: ${nome}"
        echo "# TYPE ${nome_prom} counter"
        echo "${nome_prom} ${valor}"
    done

    # Tempos: sum e count para permitir avg = sum/count no PromQL
    for f in "$_METRICSU__DIR"/*.time; do
        [[ -f "$f" ]] || continue
        local nome nome_prom
        nome=$(basename "$f" .time)
        nome_prom="bashbase_$(echo "$nome" | tr '.-' '__')_duration_milliseconds"

        awk -v base="$nome_prom" -v metrica="$nome" '
            BEGIN { sum = 0; count = 0 }
            /^[0-9]+$/ { sum += $1; count++ }
            END {
                if (count == 0) exit
                print "# HELP " base "_sum Soma dos tempos de execucao em ms: " metrica
                print "# TYPE " base "_sum gauge"
                print base "_sum " sum
                print "# HELP " base "_count Total de execucoes cronometradas: " metrica
                print "# TYPE " base "_count counter"
                print base "_count " count
            }
        ' "$f"
    done
}
