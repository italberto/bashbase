# sinais — Stack de cleanup garantido via traps de sinal

**Arquivo:** `sinais.sh`
**Dependências:** nenhuma

Implementa o padrão acumulador de handlers: múltiplos módulos e scripts podem registrar funções de limpeza sem sobrescrever uns aos outros. Os handlers são executados em **ordem reversa de registração (LIFO)**, garantindo que o último recurso adquirido seja o primeiro a ser liberado.

Um único trap central é instalado para `EXIT`, `INT`, `TERM` e `HUP`.

## Referência rápida

| Função | Descrição |
|--------|-----------|
| `registrar_cleanup` | Adiciona um comando ao stack de limpeza |
| `registrar_cleanup_cmd` | Versão segura para argumentos com espaços |
| `cancelar_cleanup` | Remove um comando do stack de limpeza |

## Variável disponível aos handlers

`_SINAIS_CODIGO_SAIDA` — código de saída que disparou a limpeza. Permite que handlers distingam saída normal (`0`) de saída por sinal (`130`=INT, `143`=TERM, `129`=HUP).

## Funções

### `registrar_cleanup <comando>`

Adiciona um comando shell ao stack de limpeza. Aceita qualquer string de comando válida.

```bash
registrar_cleanup "rm -f /tmp/dados.tmp"
registrar_cleanup "lock_liberar /tmp/app.lock"
registrar_cleanup "tput cnorm 2>/dev/null"
```

**Ordem de execução (LIFO):** se A for registrado antes de B, B é executado primeiro na saída.

```bash
registrar_cleanup "echo primeiro"
registrar_cleanup "echo segundo"
# Na saída: "segundo" é exibido antes de "primeiro"
```

---

### `registrar_cleanup_cmd <cmd> [args...]`

Versão segura para comandos cujos argumentos podem conter espaços, aspas ou outros caracteres especiais. Cada argumento é escapado com `printf '%q'` antes do registro.

```bash
# Caminhos com espaços:
registrar_cleanup_cmd rm -f "/tmp/meu arquivo.tmp"
registrar_cleanup_cmd lock_liberar "/var/run/meu app.lock"
```

---

### `cancelar_cleanup <comando>`

Remove um comando do stack de limpeza. Útil quando o recurso já foi liberado manualmente antes da saída do script.

```bash
tput civis
registrar_cleanup "tput cnorm 2>/dev/null"

# ... operação interativa ...

tput cnorm
cancelar_cleanup "tput cnorm 2>/dev/null"  # já restaurado manualmente
```

## Exemplo completo

```bash
source "$BASHBASE/sinais.sh"

# Arquivo temporário — garantir remoção em qualquer saída
tmp=$(mktemp)
registrar_cleanup "rm -f $tmp"

# Processamento
echo "dados" > "$tmp"
processar "$tmp"

# Se chegou aqui sem erro, o cleanup ainda acontece no EXIT
```

## Módulos que usam sinais.sh

- **`spinner.sh`** — registra `_spinner_restaurar_cursor` para restaurar o cursor do terminal
- **`inputs.sh`** — `menu_interativo` registra `tput cnorm` enquanto o menu está ativo
- **`procesu.sh`** — `lock_adquirir_com_cleanup` registra `lock_liberar`
