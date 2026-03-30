# retryu — Retry automático com delay fixo ou backoff exponencial

**Arquivo:** `retryu.sh`
**Dependências:** `spinner.sh`

Útil para operações instáveis como chamadas de rede, acesso a serviços externos ou qualquer comando que possa falhar transitoriamente.

## Referência rápida

| Função | Delay | Spinner | Descrição |
|--------|-------|---------|-----------|
| `tentar` | Fixo | Não | Retry silencioso com delay fixo |
| `tentar_com_backoff` | Exponencial | Não | Retry silencioso com backoff |
| `tentar_spinner` | Fixo | Sim | Retry com delay fixo e spinner |
| `tentar_backoff_spinner` | Exponencial | Sim | Retry com backoff e spinner |

## Funções

### `tentar <tentativas> <delay> <comando...>`

Executa um comando até N vezes com delay fixo entre tentativas. Mensagens de progresso vão para **stderr**.

**Retorno:** 0 na primeira execução bem-sucedida, 1 se todas as tentativas falharem.

```bash
tentar 3 5 curl -s https://api.exemplo.com/health
tentar 5 2 ping -c 1 gateway.local
tentar 3 10 rsync -av origem/ destino/ || { erro "Sincronização falhou."; exit 1; }
```

**Saída no stderr:**
```
Tentativa 1/3 falhou. Aguardando 5s...
Tentativa 2/3 falhou. Aguardando 5s...
Todas as 3 tentativas falharam: curl -s https://...
```

---

### `tentar_com_backoff <tentativas> <delay_inicial> <comando...>`

Executa um comando até N vezes com espera exponencial: `delay`, `2×delay`, `4×delay`, etc. Ideal para evitar sobrecarga em serviços que estão se recuperando.

```bash
tentar_com_backoff 4 2 wget -q https://exemplo.com/arquivo.tar.gz
# Esperas: 2s, 4s, 8s
```

---

### `tentar_spinner <tentativas> <delay> <comando...>`

Versão com spinner visual. A saída do comando é descartada para não quebrar o layout. O cursor é restaurado em caso de interrupção (Ctrl+C).

```bash
tentar_spinner 3 5 curl -s https://api.exemplo.com/health
```

**Saída no terminal:**
```
[⠙] Tentativa 1/3: curl -s https://api.exemplo.com/health
[✗] Tentativa 1/3 falhou.
[⠹] Aguardando 5s antes da próxima tentativa...
[✓] Concluído na tentativa 2/3.
```

---

### `tentar_backoff_spinner <tentativas> <delay_inicial> <comando...>`

Combina backoff exponencial com spinner visual.

```bash
tentar_backoff_spinner 4 2 wget -q https://exemplo.com/arquivo.tar.gz
```

## Escolhendo a função

| Cenário | Função recomendada |
|---------|--------------------|
| Script não interativo, logs em arquivo | `tentar` ou `tentar_com_backoff` |
| Script interativo com feedback visual | `tentar_spinner` ou `tentar_backoff_spinner` |
| Serviço que precisa de tempo para reiniciar | `tentar_com_backoff` |
| Verificação rápida de disponibilidade | `tentar` |

## Parâmetros de delay

**Delay fixo** (`tentar`, `tentar_spinner`): o script espera exatamente `delay` segundos entre cada tentativa.

**Backoff exponencial** (`tentar_com_backoff`, `tentar_backoff_spinner`): a espera dobra a cada falha.

| Tentativa | delay=2 (backoff) |
|-----------|-------------------|
| Após 1ª falha | 2s |
| Após 2ª falha | 4s |
| Após 3ª falha | 8s |
| Após 4ª falha | 16s |
