# argsu — Parsing declarativo de argumentos de linha de comando

**Arquivo:** `argsu.sh`
**Dependências:** nenhuma

Permite declarar os argumentos aceitos por um script e parsear `$@` de forma automática, com suporte a `--flag valor`, `--flag=valor`, flags booleanas, argumentos posicionais e geração automática de `--help`.

## Referência rápida

| Função | Descrição |
|--------|-----------|
| `arg_definir` | Declara um argumento aceito pelo script |
| `arg_parsear` | Parseia os argumentos recebidos (`$@`) |
| `arg_ajuda` | Imprime a lista de argumentos e descrições |
| `arg_resetar` | Limpa todas as definições registradas |

**Variável global:**

| Variável | Descrição |
|----------|-----------|
| `_ARG_POSICIONAIS` | Array com os argumentos posicionais capturados por `arg_parsear` |

## Uso típico

```bash
source "$BASHBASE/argsu.sh"

arg_definir "--host"    HOST    "localhost" "Endereço do servidor"
arg_definir "--porta"   PORTA   8080        "Porta de conexão"
arg_definir "--verbose" VERBOSE ""          "Ativar saída detalhada" "boolean"
arg_definir "--saida"   SAIDA   ""          "Arquivo de saída"       "valor"
arg_parsear "$@" || exit 1

echo "Conectando em $HOST:$PORTA"
[ "$VERBOSE" = "1" ] && echo "Modo verboso ativado"
echo "Arquivos: ${_ARG_POSICIONAIS[*]}"
```

## Funções

### `arg_definir <--flag> <VAR> [padrao] [descricao] [tipo]`

Declara um argumento aceito e define seu valor padrão imediatamente.

**Parâmetros:**
- `$1` — flag da linha de comando (ex: `--host`)
- `$2` — nome da variável de destino (ex: `HOST`)
- `$3` — valor padrão (opcional; `""` ou omitido indica ausência de padrão)
- `$4` — descrição exibida no `--help`
- `$5` — tipo: `"boolean"` ou `"valor"` (opcional; inferido automaticamente se omitido)

**Inferência automática do tipo:**
- Padrão vazio (`""` ou omitido) → `boolean`: recebe `"1"` quando presente, permanece vazio quando ausente.
- Padrão não vazio → `valor`: exige um valor explícito na linha de comando; erro se ausente.

O tipo pode ser passado explicitamente quando a inferência não for suficiente — por exemplo, uma flag do tipo `valor` que não tem padrão definido.

```bash
arg_definir "--host"    HOST    "localhost" "Endereço do servidor"          # tipo: valor (inferido)
arg_definir "--verbose" VERBOSE ""          "Modo verboso"        "boolean" # tipo: boolean (explícito)
arg_definir "--saida"   SAIDA   ""          "Arquivo de saída"    "valor"   # tipo: valor (explícito)
```

---

### `arg_parsear "$@"`

Parseia os argumentos e preenche as variáveis declaradas. Retorna 1 em caso de argumento desconhecido, flag do tipo `valor` sem valor fornecido, ou se `--help`/`-h` for passado.

Argumentos posicionais (que não começam com `-`) são acumulados no array `_ARG_POSICIONAIS`. O marcador `--` força que todos os tokens seguintes sejam tratados como posicionais, mesmo que comecem com `-`.

**Sintaxe aceita:**
```bash
./script.sh --host api.exemplo.com --porta 9000
./script.sh --host=api.exemplo.com --porta=9000
./script.sh --verbose
./script.sh arquivo1 arquivo2              # posicionais → _ARG_POSICIONAIS
./script.sh --host srv -- -arquivo-raro   # após "--", tudo é posicional
```

**Tratamento de erros:**
```bash
arg_parsear "$@" || exit 1
```

---

### `arg_ajuda`

Imprime a lista de argumentos com descrições e valores padrão. Chamada automaticamente por `arg_parsear` ao receber `--help`/`-h` ou argumento inválido. Flags booleanas não exibem valor padrão.

```
Opções disponíveis:
  --host                 Endereço do servidor (padrão: localhost)
  --porta                Porta de conexão (padrão: 8080)
  --verbose              Modo verboso
  --saida                Arquivo de saída
  --help, -h             Exibe esta mensagem de ajuda
```

---

### `arg_resetar`

Remove todas as definições registradas e limpa `_ARG_POSICIONAIS`. Útil quando `argsu.sh` é reutilizado em múltiplos contextos dentro de um mesmo processo.

```bash
arg_resetar
```
