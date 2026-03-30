# spinner — Animações de progresso no terminal

**Arquivo:** `spinner.sh`
**Dependências:** `sinais.sh`

Todas as funções recebem o PID de um processo em background e exibem uma animação enquanto aguardam sua conclusão. O cursor é ocultado durante a animação e restaurado ao final — inclusive em caso de Ctrl+C (via integração com `sinais.sh`).

## Referência rápida

| Função | Tipo de animação |
|--------|-----------------|
| `spinner` | Frames customizáveis (qualquer conjunto de caracteres) |
| `spinner_pingpong` | Barra vertical que cresce e diminui |
| `spinner_bar` | Barra horizontal com bloco deslizante |

## Uso geral

Todas as funções de spinner seguem o mesmo padrão:

```bash
meu_comando &
spinner "$!" "frames" "mensagem"
echo "Exit code: $?"   # o wait já foi feito pelo spinner
```

## Funções

### `spinner <pid> <frames> [mensagem] [delay]`

Spinner genérico com frames configuráveis. Cada caractere da string `frames` representa um quadro da animação.

**Parâmetros:**
- `$1` — PID do processo a aguardar
- `$2` — string de frames (cada caractere = um quadro)
- `$3` — mensagem exibida ao lado do spinner (padrão: `"trabalhando..."`)
- `$4` — delay entre frames em segundos (padrão: `0.1`)

```bash
tar -czf backup.tar.gz /var/www &
spinner "$!" "⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏" "Compactando..."

rsync -av origem/ destino/ &>/dev/null &
spinner "$!" "|\-/" "Sincronizando..."
```

**Exemplos de frames:**
```
Braille:  "⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
Simples:  "|\-/"
Círculo:  "◐◓◑◒"
Relógio:  "🕛🕐🕑🕒🕓🕔🕕🕖🕗🕘🕙🕚"
```

**Saída:**
```
[⠙] Compactando...
[✓] concluído!
```

---

### `spinner_pingpong <pid> [mensagem] [delay]`

Exibe uma animação de barra vertical que cresce e diminui (efeito ping-pong) usando blocos Unicode (▁▂▃▄▅▆▇█).

```bash
apt install -y curl &>/dev/null &
spinner_pingpong "$!" "Instalando pacotes..."
```

---

### `spinner_bar <pid> [mensagem] [delay]`

Exibe uma barra horizontal com um bloco (`█`) deslizante que vai e volta em um trilho de hífens.

```bash
wget -q https://exemplo.com/arquivo.tar.gz &
spinner_bar "$!" "Baixando arquivo..."
```

**Saída:**
```
[---█------] Baixando arquivo...
[✓] concluído!
```

## Integração com sinais.sh

Ao ser carregado, `spinner.sh` registra automaticamente `_spinner_restaurar_cursor` no stack de cleanup de `sinais.sh`. Se o script for interrompido com Ctrl+C enquanto um spinner estiver ativo, o cursor do terminal é restaurado automaticamente.

A flag global `_SPINNER_CURSOR_OCULTO` indica se o cursor está atualmente oculto por qualquer spinner. Módulos como `retryu.sh` gerenciam esta flag ao usar `tput civis`/`tput cnorm` diretamente.
