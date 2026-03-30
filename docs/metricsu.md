# metricsu — Observabilidade de execução: contadores, tempos e detecção de comandos lentos

**Arquivo:** `lib/metricsu.sh`
**Dependências:** `dryrun.sh`

Registra métricas de execução (contadores e tempos) em arquivos locais. Contadores são atualizados com `flock` para garantir atomicidade em execuções paralelas. A saída pode ser exibida em formato legível ou exportada no formato Prometheus text para integração com node_exporter.

## Referência rápida

| Função | Descrição |
|--------|-----------|
| `metric_iniciar` | Inicializa o diretório de métricas (opcional) |
| `metric_incrementar` | Incrementa um contador por nome |
| `metric_registrar_tempo` | Registra uma amostra de tempo em ms |
| `metric_wrap` | Cronometra e conta automaticamente um comando |
| `metric_exibir` | Exibe todas as métricas em formato legível |
| `metric_resetar` | Remove e recria o diretório de métricas |
| `metric_exportar_prometheus` | Exporta métricas no formato Prometheus text |

## Variáveis configuráveis

| Variável | Padrão | Descrição |
|----------|--------|-----------|
| `_METRICSU__DIR` | `/tmp/bashbase_metrics_PID` | Diretório de armazenamento das métricas |
| `_METRICSU__SLOW_MS` | `5000` | Threshold em ms para alerta de comando lento (`0` desativa) |

O diretório padrão é isolado por PID para evitar colisão entre scripts distintos rodando simultaneamente.

## Funções

### `metric_iniciar [dir]`

Inicializa o diretório de métricas. Se não for chamada explicitamente, o diretório é criado automaticamente na primeira operação de registro. Use esta função para definir um diretório persistente (ex: integração com node_exporter).

```bash
metric_iniciar                          # usa padrão /tmp/bashbase_metrics_PID
metric_iniciar /var/lib/node_exporter   # diretório persistente para Prometheus
```

---

### `metric_incrementar <nome> [delta]`

Incrementa um contador pelo nome. Usa `flock` para garantir atomicidade mesmo com múltiplos processos rodando em paralelo. O delta padrão é `1`.

```bash
metric_incrementar "deploy.sucesso"
metric_incrementar "retry.tentativa"
metric_incrementar "itens.processados" 10
```

---

### `metric_registrar_tempo <nome> <ms>`

Registra uma amostra de tempo em milissegundos. Cada chamada acrescenta uma linha ao arquivo de tempos da métrica — `metric_exibir` calcula min/max/avg sobre todas as amostras.

```bash
metric_registrar_tempo "backup" 3420
metric_registrar_tempo "query.db" "$duracao_ms"
```

---

### `metric_wrap <nome> <cmd...>`

Executa um comando e registra automaticamente tempo de execução e resultado. Cria as métricas `<nome>.time`, `<nome>.sucesso` e `<nome>.erro`. Emite aviso no stderr se o tempo ultrapassar `_METRICSU__SLOW_MS`. Retorna o mesmo exit code do comando.

```bash
metric_wrap "backup"  rsync -av /src/ /dst/
metric_wrap "deploy"  bash deploy.sh --env prod
metric_wrap "sync"    minha_funcao arg1 arg2
```

**Saída no stderr se lento:**
```
[METRICSU] Comando lento detectado: backup (7823ms > threshold 5000ms)
```

---

### `metric_exibir`

Exibe todas as métricas registradas em formato legível. Contadores mostram o valor acumulado; tempos mostram número de amostras, mínimo, máximo e média.

```bash
metric_exibir
```

**Saída exemplo:**
```
Contadores:
  backup.sucesso                               3
  backup.erro                                  1
  deploy.sucesso                               2

Tempos (ms):
  backup                n=4     min=1200   ms max=7823   ms avg=3412ms
  deploy                n=2     min=890    ms max=1240   ms avg=1065ms
```

---

### `metric_resetar`

Remove todas as métricas e recria o diretório vazio. Útil para reiniciar a contagem entre execuções num mesmo processo.

```bash
metric_resetar
```

---

### `metric_exportar_prometheus`

Exporta métricas no formato [Prometheus text](https://prometheus.io/docs/instrumenting/exposition_formats/). Contadores recebem sufixo `_total` e `TYPE counter`. Tempos são exportados como `_sum` e `_count`, permitindo calcular média no PromQL com `sum/count`. Pontos e hífens nos nomes são convertidos para underscores.

```bash
metric_exportar_prometheus                               # imprime no stdout
metric_exportar_prometheus > /var/lib/node_exporter/bashbase.prom
```

**Saída exemplo:**
```
# HELP bashbase_backup_sucesso_total Contador bashbase: backup.sucesso
# TYPE bashbase_backup_sucesso_total counter
bashbase_backup_sucesso_total 3
# HELP bashbase_backup_duration_milliseconds_sum Soma dos tempos de execucao em ms: backup
# TYPE bashbase_backup_duration_milliseconds_sum gauge
bashbase_backup_duration_milliseconds_sum 13648
# HELP bashbase_backup_duration_milliseconds_count Total de execucoes cronometradas: backup
# TYPE bashbase_backup_duration_milliseconds_count counter
bashbase_backup_duration_milliseconds_count 4
```

## Uso típico

```bash
source "$BASHBASE/lib/metricsu.sh"

# Envolve operações críticas com metric_wrap
metric_wrap "sync"    rsync -av /origem/ /destino/
metric_wrap "backup"  tar -czf backup.tar.gz /dados/

# Contadores manuais em pontos de controle
if validar_configuracao; then
    metric_incrementar "config.valida"
else
    metric_incrementar "config.invalida"
fi

# Exibe relatório ao final
metric_exibir
```

## Integração com paralelo.sh

`metric_incrementar` usa `flock` e é seguro para chamadas concorrentes de múltiplos workers:

```bash
source "$BASHBASE/lib/paralelo.sh"
source "$BASHBASE/lib/metricsu.sh"

export -f processar minha_funcao
export _METRICSU__DIR   # compartilha o diretório entre subshells

paralelo_pool 4 \
    "metric_wrap 'proc' processar arquivo1.dat" \
    "metric_wrap 'proc' processar arquivo2.dat" \
    "metric_wrap 'proc' processar arquivo3.dat"

metric_exibir
```

## Integração com Prometheus / node_exporter

Configure o `textfile_collector` do node_exporter para ler de um diretório e grave as métricas periodicamente:

```bash
metric_iniciar /var/lib/node_exporter/textfile_collector
# ... execução do script ...
metric_exportar_prometheus > /var/lib/node_exporter/textfile_collector/bashbase.prom
```

## Ajustando o threshold de comandos lentos

```bash
_METRICSU__SLOW_MS=10000   # alertar apenas acima de 10s
_METRICSU__SLOW_MS=0       # desativar detecção de lentidão
```
