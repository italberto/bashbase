# logu — Logging estruturado com níveis e rotação de arquivo

**Arquivo:** `logu.sh`
**Dependências:** nenhuma

Grava mensagens com timestamp, nível e opcionalmente em arquivo. Suporta quatro níveis de log (DEBUG, INFO, WARN, ERRO) e rotação automática por tamanho.

## Referência rápida

| Função | Descrição |
|--------|-----------|
| `log_set_arquivo` | Define o arquivo de destino dos logs |
| `log_set_nivel` | Define o nível mínimo de filtragem |
| `log_debug` | Registra mensagem de nível DEBUG |
| `log_info` | Registra mensagem de nível INFO |
| `log_warn` | Registra mensagem de nível WARN |
| `log_erro` | Registra mensagem de nível ERRO |
| `log_rodar` | Rotaciona o log ao atingir o tamanho limite |
| `log_escrever_apenas_arquivo` | Grava no arquivo sem output no terminal (API pública) |

## Níveis de log

| Constante | Valor | Função |
|-----------|-------|--------|
| `_LOG_DEBUG` | 0 | `log_debug` |
| `_LOG_INFO` | 1 | `log_info` |
| `_LOG_WARN` | 2 | `log_warn` |
| `_LOG_ERRO` | 3 | `log_erro` |

## Formato das entradas

```
[2024-12-15 14:30:22] [INFO ] Serviço iniciado com sucesso
[2024-12-15 14:30:23] [WARN ] Arquivo de configuração não encontrado
[2024-12-15 14:30:24] [ERRO ] Falha ao conectar ao banco de dados
```

## Funções

### `log_set_arquivo <caminho>`

Define o arquivo de destino. Se o diretório não existir, tenta criá-lo automaticamente.

```bash
log_set_arquivo /var/log/meu_script.log
log_set_arquivo /tmp/debug.log
```

---

### `log_set_nivel <nivel>`

Define o nível mínimo. Mensagens com nível abaixo do mínimo são silenciadas.

```bash
log_set_nivel 0   # DEBUG e acima (padrão)
log_set_nivel 1   # INFO e acima (ignora DEBUG)
log_set_nivel 2   # WARN e acima
log_set_nivel 3   # apenas ERRO
```

---

### `log_debug`, `log_info`, `log_warn`, `log_erro`

Registram mensagens nos respectivos níveis. Mensagens de ERRO são enviadas para **stderr**; as demais vão para stdout.

```bash
log_debug "variavel x = $x"
log_info  "Serviço iniciado com sucesso"
log_warn  "Arquivo de configuração não encontrado, usando padrão"
log_erro  "Falha ao conectar ao banco de dados"
```

---

### `log_rodar <arquivo> [limite]`

Rotaciona o arquivo de log quando seu tamanho ultrapassa o limite. Copia o conteúdo atual para um arquivo com timestamp e zera o arquivo original via `truncate`, **preservando o inode**. Processos com o descritor já aberto continuam escrevendo no arquivo ativo sem perda de dados. Aceita sufixos `K`, `M` e `G`.

```bash
log_rodar /var/log/app.log 10M    # rotaciona quando atingir 10 MB
log_rodar /var/log/app.log 100K
log_rodar /var/log/app.log 1G
```

---

### `log_escrever_apenas_arquivo <nivel_num> <nivel_str> <mensagem>`

API pública que grava diretamente no arquivo sem exibir no terminal. Usada por `alerta.sh` para integrar com o sistema de log sem acessar a função interna `_log_escrever`.

```bash
log_escrever_apenas_arquivo $_LOG_WARN "WARN " "mensagem interna"
```

## Uso típico

```bash
source "$BASHBASE/logu.sh"

log_set_arquivo /var/log/deploy.log
log_set_nivel 1   # INFO e acima

log_info "Iniciando deploy..."
log_warn "Versão anterior não encontrada, deploy completo"
log_info "Deploy concluído em $(date)"
```

## Integração com alerta.sh

Ao carregar `alerta.sh`, as funções `alerta`, `erro`, `sucesso`, `info` e `debug` gravam automaticamente no arquivo de log se `log_set_arquivo` tiver sido chamado. O nível mínimo definido por `log_set_nivel` controla quais mensagens são gravadas.

```bash
source "$BASHBASE/alerta.sh"  # inclui logu.sh automaticamente

log_set_arquivo /var/log/app.log
log_set_nivel 1

info "Esta mensagem aparece no terminal em azul e no log como INFO"
erro "Esta vai para stderr e para o log como ERRO"
```
