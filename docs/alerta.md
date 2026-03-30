# alerta — Mensagens coloridas e categorizadas no terminal

**Arquivo:** `alerta.sh`
**Dependências:** `cores.sh`, `logu.sh`

Fornece funções de alerta categorizadas por tipo com suporte a recuo (indentação) para hierarquia visual. Se `log_set_arquivo` tiver sido chamado, todas as funções gravam automaticamente no arquivo de log com timestamp e sem cores.

## Referência rápida

| Função | Cor | Nível de log | Saída |
|--------|-----|-------------|-------|
| `msg_alerta` | Amarelo | WARN | stdout |
| `msg_erro` | Vermelho | ERRO | stderr |
| `msg_sucesso` | Verde | INFO | stdout |
| `msg_info` | Azul | INFO | stdout |
| `msg_debug` | Cinza | DEBUG | stdout (somente se `DEBUG=1`) |

## Funções

### `alerta <mensagem> [recuo]`

Exibe uma mensagem de aviso em amarelo.

**Parâmetros:**
- `$1` — mensagem a exibir
- `$2` — número de tabulações de recuo (opcional)

**Exemplo:**
```bash
alerta "Arquivo de configuração não encontrado"
alerta "Item ignorado" 2   # com 2 tabulações de recuo
```

---

### `erro <mensagem> [recuo]`

Exibe uma mensagem de erro em vermelho no **stderr**.

**Parâmetros:**
- `$1` — mensagem a exibir
- `$2` — número de tabulações de recuo (opcional)

**Exemplo:**
```bash
erro "Falha ao conectar ao servidor"
erro "Permissão negada" 1
```

---

### `sucesso <mensagem> [recuo]`

Exibe uma mensagem de sucesso em verde.

**Exemplo:**
```bash
sucesso "Instalação concluída"
sucesso "Arquivo copiado" 1
```

---

### `info <mensagem> [recuo]`

Exibe uma mensagem informativa em azul.

**Exemplo:**
```bash
info "Iniciando sincronização dos arquivos..."
info "Processando item 3 de 10" 1
```

---

### `debug <mensagem> [recuo]`

Exibe uma mensagem de diagnóstico em cinza, prefixada com `[DEBUG]`.

Só produz saída no terminal quando `DEBUG=1`. A gravação em arquivo de log respeita o nível mínimo configurado em `logu.sh` e acontece independentemente da variável `DEBUG`.

**Ativar debug sem modificar o script:**
```bash
DEBUG=1 ./meu_script.sh
```

**Exemplo:**
```bash
debug "variável x = $x"
debug "entrando na função foo" 1
```

## Integração com logu.sh

```bash
source "$BASHBASE/alerta.sh"

log_set_arquivo /var/log/meu_script.log
log_set_nivel 1   # ignora DEBUG, registra INFO em diante

info "Iniciando..."     # exibe em azul no terminal + grava no arquivo
erro "Algo falhou"      # exibe em vermelho no stderr + grava no arquivo
debug "valor=$x"        # grava no arquivo (nível 0 < mínimo 1, logo suprimido)
```
