# procesu — Gerenciamento de processos e lock de execução exclusiva

**Arquivo:** `procesu.sh`
**Dependências:** `systemu.sh`, `sinais.sh`

Fornece utilitários para verificar, encerrar e aguardar processos, além de mecanismo de lock para evitar execuções paralelas de um mesmo script.

## Referência rápida

| Função | Descrição |
|--------|-----------|
| `e_processo_rodando` | Verifica se um processo está ativo pelo nome |
| `matar_processo` | Encerra processo com fallback SIGTERM → SIGKILL |
| `lock_adquirir` | Cria lock para execução exclusiva |
| `lock_liberar` | Remove o arquivo de lock |
| `lock_adquirir_com_cleanup` | Adquire lock e registra liberação automática |
| `aguardar_processo` | Espera um processo terminar |

## Funções

### `e_processo_rodando <nome>`

Verifica se um processo está em execução pelo nome exato (via `pgrep -x`).

**Retorno:** 0 se estiver rodando, 1 caso contrário.

```bash
e_processo_rodando "nginx" && echo "nginx ativo"
e_processo_rodando "mysqld" || { erro "MySQL não está rodando"; exit 1; }
```

---

### `matar_processo <nome> [timeout]`

Encerra todos os processos com o nome informado. Envia SIGTERM primeiro e aguarda até `timeout` segundos (padrão: 5). Se o processo não terminar, envia SIGKILL.

**Retorno:** 0 se processos foram encontrados e encerrados, 1 se nenhum processo foi encontrado.

```bash
matar_processo "meu_script"
matar_processo "java" 30   # aguarda até 30 segundos antes do SIGKILL
```

---

### `lock_adquirir <lock>`

Adquire um lock de execução exclusiva usando um **diretório** como sentinela. `mkdir` é atômico no kernel, eliminando a race condition entre verificar e criar que existe com arquivos comuns. O PID do processo dono é gravado em `<lock>/pid`.

Se o lock existir mas o processo dono não existir mais (crash, kill -9), o lock fantasma é removido automaticamente e um novo lock é adquirido.

**Retorno:** 0 se o lock foi adquirido, 1 se outro processo válido já possui o lock.

```bash
lock_adquirir /tmp/meu_script.lock || {
    erro "Já existe uma instância em execução."
    exit 1
}
trap "lock_liberar /tmp/meu_script.lock" EXIT
```

---

### `lock_liberar <lock>`

Remove o lock. Verifica se o processo atual é o dono antes de remover.

**Retorno:** 0 se liberado, 1 se o processo atual não é o dono.

```bash
lock_liberar /tmp/meu_script.lock
```

---

### `lock_adquirir_com_cleanup <lock>`

Versão conveniente que adquire o lock **e** registra automaticamente sua liberação no stack de cleanup de `sinais.sh`. Garante que o lock será removido mesmo em caso de Ctrl+C, kill ou erro não tratado.

**Retorno:** 0 se adquirido, 1 caso contrário.

```bash
source "$BASHBASE/procesu.sh"

lock_adquirir_com_cleanup /tmp/app.lock || {
    erro "Já existe uma instância em execução."
    exit 1
}

# lock é liberado automaticamente ao sair, mesmo com Ctrl+C
info "Executando..."
```

---

### `aguardar_processo <nome_ou_pid> [timeout]`

Espera um processo terminar, verificando a cada segundo. Aceita tanto o nome quanto o PID. O timeout padrão é 30 segundos.

**Retorno:** 0 se o processo terminou, 1 se o timeout foi atingido.

```bash
aguardar_processo "rsync" 60
aguardar_processo 1234 30
aguardar_processo "backup.sh" 120 || erro "Timeout: backup não concluiu"
```
