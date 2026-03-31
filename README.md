# bashbase

![License](https://img.shields.io/github/license/italberto/bashbase)
![Version](https://img.shields.io/github/v/release/italberto/bashbase)
![Shell](https://img.shields.io/badge/shell-bash-green)
![Stars](https://img.shields.io/github/stars/italberto/bashbase)
![Maintained](https://img.shields.io/badge/maintained-yes-brightgreen)

Biblioteca de funções Bash para automação de sistemas. Agrupa utilitários comuns em módulos independentes e reutilizáveis — saída colorida, logging, retry, spinners, inputs interativos, gerenciamento de processos, backups, conectividade e muito mais.

A biblioteca é organizada em duas camadas:

- **Primitivos** (`lib/`) — funções genéricas que dependem apenas do SO e de outros primitivos. Funcionam em qualquer host com Bash.
- **Serviços** (`lib/servicos/`) — funções de alto nível para sistemas externos específicos (PostgreSQL, JBoss, etc.). Dependem do serviço estar instalado e acessível.

## Pré-requisitos

- **Bash 4.0 ou superior** (arrays associativos, `${var^^}`, `printf -v`)
- Variável de ambiente `BASHBASE` apontando para o diretório do repositório

## Instalação

```bash
git clone https://github.com/italberto/bashbase.git ~/bashbase
cd ~/bashbase && bash install.sh
```

O script `install.sh` detecta o shell atual e adiciona `BASHBASE` ao `~/.bashrc` ou `~/.zshrc` automaticamente. Para aplicar na sessão atual:

```bash
source ~/.bashrc   # ou ~/.zshrc
```

## Uso básico

Carregue os módulos desejados com `source` no início do script:

```bash
#!/usr/bin/env bash
source "$BASHBASE/lib/alerta.sh"
source "$BASHBASE/lib/logu.sh"
source "$BASHBASE/lib/retryu.sh"

log_set_arquivo /var/log/meu_script.log

info "Iniciando sincronização..."
tentar 3 5 rsync -av origem/ destino/ || { erro "Sincronização falhou."; exit 1; }
sucesso "Sincronização concluída."
```

## Exemplo completo

```bash
#!/usr/bin/env bash
source "$BASHBASE/lib/alerta.sh"
source "$BASHBASE/lib/argsu.sh"
source "$BASHBASE/lib/sinais.sh"
source "$BASHBASE/lib/procesu.sh"

arg_definir "--host"  HOST  "localhost" "Endereço do servidor"
arg_definir "--porta" PORTA 8080        "Porta de conexão"
arg_parsear "$@" || exit 1

lock_adquirir_com_cleanup /tmp/meu_script.lock || {
    erro "Já existe uma instância em execução."
    exit 1
}

info "Conectando em $HOST:$PORTA..."
# ... lógica do script ...
sucesso "Concluído."
```

## Índice de módulos

### Primitivos (`lib/`)

| Módulo | Arquivo | Descrição |
|--------|---------|-----------|
| [alerta](docs/alerta.md) | `lib/alerta.sh` | Mensagens coloridas e categorizadas no terminal |
| [argsu](docs/argsu.md) | `lib/argsu.sh` | Parsing declarativo de argumentos de linha de comando |
| [backupu](docs/backupu.md) | `lib/backupu.sh` | Backup de arquivos e diretórios com timestamp |
| [configu](docs/configu.md) | `lib/configu.sh` | Leitura e escrita de arquivos `.env` / `CHAVE=valor` |
| [cores](docs/cores.md) | `lib/cores.sh` | Colorização de texto com códigos ANSI |
| [crypto](docs/crypto.md) | `lib/crypto.sh` | Hashes e chaves criptográficas via OpenSSL |
| [datau](docs/datau.md) | `lib/datau.sh` | Timestamps, formatação de datas e cálculo de durações |
| [diru](docs/diru.md) | `lib/diru.sh` | Inspeção e metadados de diretórios |
| [distu](docs/distu.md) | `lib/distu.sh` | Detecção de distribuição Linux e informações do SO |
| [downu](docs/downu.md) | `lib/downu.sh` | Download de arquivos via wget, curl ou TCP nativo |
| [filesu](docs/filesu.md) | `lib/filesu.sh` | Verificação, metadados e comparação de arquivos |
| [inputs](docs/inputs.md) | `lib/inputs.sh` | Coleta interativa de dados do usuário |
| [logu](docs/logu.md) | `lib/logu.sh` | Logging estruturado com níveis e rotação de arquivo |
| [metricsu](docs/metricsu.md) | `lib/metricsu.sh` | Observabilidade: contadores, tempos e exportação Prometheus |
| [mockfiles](docs/mockfiles.md) | `lib/mockfiles.sh` | Criação de arquivos fictícios para testes |
| [pkgu](docs/pkgu.md) | `lib/pkgu.sh` | Abstração para gerenciadores de pacotes (apt/dnf/pacman…) |
| [procesu](docs/procesu.md) | `lib/procesu.sh` | Gerenciamento de processos e lock de execução exclusiva |
| [redes](docs/redes.md) | `lib/redes.sh` | Primitivos de rede: porta, interface, gateway, Wi-Fi, DNS |
| [resourcesu](docs/resourcesu.md) | `lib/resourcesu.sh` | Monitoramento de CPU, memória e disco |
| [retryu](docs/retryu.md) | `lib/retryu.sh` | Retry automático com delay fixo ou backoff exponencial |
| [runu](docs/runu.md) | `lib/runu.sh` | Execução de comandos com spinner e timeout |
| [servicou](docs/servicou.md) | `lib/servicou.sh` | Gerenciamento de serviços systemd |
| [sinais](docs/sinais.md) | `lib/sinais.sh` | Stack de cleanup garantido via traps de sinal |
| [spinner](docs/spinner.md) | `lib/spinner.sh` | Animações de progresso no terminal |
| [systemu](docs/systemu.md) | `lib/systemu.sh` | Utilitários gerais de sistema (root, PATH, exit codes) |
| [tempu](docs/tempu.md) | `lib/tempu.sh` | Arquivos e diretórios temporários com cleanup automático |
| [textfilesu](docs/textfilesu.md) | `lib/textfilesu.sh` | Contagem, busca e substituição em arquivos de texto |
| [utils](docs/utils.md) | `lib/utils.sh` | Manipulação de strings e extração de campos |
| [validau](docs/validau.md) | `lib/validau.sh` | Validação de IP, e-mail, URL, porta e variáveis |
| paralelo | `lib/paralelo.sh` | Execução concorrente de comandos com controle de concorrência |
| version | `lib/version.sh` | Metadados e informações de versão da biblioteca |

### Serviços (`lib/servicos/`)

Módulos que encapsulam operações de alto nível sobre sistemas externos. Requerem o serviço instalado e acessível.

| Módulo | Arquivo | Descrição |
|--------|---------|-----------|
| [conectividade](docs/servicos/conectividade.md) | `lib/servicos/conectividade.sh` | Disponibilidade de serviços de rede por porta (SSH, HTTP, FTP…) |
| [postgres](docs/servicos/postgres.md) | `lib/servicos/postgres.sh` | Verificação, queries e replicação em instâncias PostgreSQL |
| [jboss](docs/servicos/jboss.md) | `lib/servicos/jboss.sh` | Deployments, saúde e management de instâncias JBoss/WildFly |

## Criando novos módulos

### Primitivo ou serviço?

| Critério | Primitivo (`lib/`) | Serviço (`lib/servicos/`) |
|---|---|---|
| Depende de sistema externo em execução? | Não | Sim |
| Funciona em qualquer host com Bash? | Sim | Não necessariamente |
| Exemplos de dependência | SO, ferramentas padrão POSIX | psql, curl, jboss-cli |
| Localização | `lib/` | `lib/servicos/` |

Se a função precisa que um processo externo (banco de dados, servidor de aplicação, etc.) esteja rodando para funcionar, é um módulo de serviço. Se opera apenas sobre o SO e ferramentas POSIX/GNU, é um primitivo.

---

### Primitivos

#### Nomenclatura

| Elemento | Convenção | Exemplos |
|---|---|---|
| Nome do arquivo | minúsculas, sem separadores; sufixo `u` para utilitários genéricos | `filesu.sh`, `datau.sh`, `redes.sh` |
| Prefixo de funções | 2–4 letras derivadas do nome, seguidas de `_` | `tf_` (textfilesu), `sys_` (systemu), `con_` (redes) |
| Funções internas | prefixo `_` antes do prefixo do módulo | `_log_escrever`, `_spinner_restaurar_cursor` |
| Guard variable | `_NOMEMODULO_SH_LOADED` (maiúsculas, underscores) | `_TEXTFILESU_SH_LOADED` |
| Constantes do módulo | `_PREFIXO_NOME_CONSTANTE` (readonly) | `_PG_PORTA_PADRAO` |

#### Estrutura do arquivo

```bash
# shellcheck shell=bash
# nomemodulo.sh - Descrição em uma linha
#
# Parágrafo descrevendo o propósito do módulo, comportamento em DRYRUN
# se aplicável, e quaisquer limitações relevantes.
#
# Dependências: dep1.sh, dep2.sh
#
# Funções disponíveis:
#   prefixo_funcao1  <obrigatorio> [opcional]  - Descrição
#   prefixo_funcao2  <obrigatorio>             - Descrição


[[ -n "${_NOMEMODULO_SH_LOADED:-}" ]] && return 0
readonly _NOMEMODULO_SH_LOADED=1

source "$(dirname "${BASH_SOURCE[0]}")/dep1.sh"
source "$(dirname "${BASH_SOURCE[0]}")/dep2.sh"

function prefixo_funcao1() {
    # Descrição do que a função faz.
    # Retorna 0 em caso de sucesso, 1 caso contrário.
    # Modo de uso: prefixo_funcao1 valor
    #              resultado=$(prefixo_funcao1 valor)
    local param="$1"
    ...
}
```

#### Regras

- Cada função deve ter um comentário de cabeçalho com descrição, semântica de retorno e ao menos um exemplo de uso em "Modo de uso".
- Funções de predicado retornam `0` para verdadeiro e `1` para falso — nunca imprimem no stdout.
- Funções de contagem/extração imprimem o resultado no stdout como valor puro, sem unidade.
- Funções que recebem um arquivo ou diretório retornam `1` se o recurso não existir, com mensagem via `alerta` ou `erro`.
- O guard variable (`_MODULO_SH_LOADED`) deve ser verificado e setado como `readonly` antes de qualquer código executável.
- Primitivos não devem depender de módulos de serviço.

---

### Serviços

#### Nomenclatura

| Elemento | Convenção | Exemplos |
|---|---|---|
| Nome do arquivo | nome do serviço, minúsculas, sem sufixo `u` | `postgres.sh`, `jboss.sh`, `redis.sh` |
| Localização | `lib/servicos/` | `lib/servicos/postgres.sh` |
| Prefixo de funções | sigla curta do serviço seguida de `_` | `pg_` (postgres), `jboss_` (jboss), `redis_` (redis) |
| Funções internas | prefixo `_` antes do prefixo do módulo | `_jboss_curl_mgmt` |
| Guard variable | `_SERVICOS_NOMESERVICO_SH_LOADED` | `_SERVICOS_POSTGRES_SH_LOADED` |
| Constantes de porta | `_PREFIXO_PORTA_NOME_PADRAO` (readonly) | `_PG_PORTA_PADRAO`, `_JBOSS_PORTA_HTTP_PADRAO` |

#### Estrutura do arquivo

```bash
# shellcheck shell=bash
# nomeservico.sh - Operações de alto nível para NomeServico
#
# Descrição do que o módulo cobre. Mencionar portas padrão, cliente
# externo requerido e como configurar autenticação se necessário.
#
# Este módulo pertence à camada de serviços da biblioteca (lib/servicos/).
#
# Dependências: redes.sh, alerta.sh, systemu.sh
#
# Funções disponíveis:
#   prefixo_esta_rodando   [host] [porta]  - Verifica se o serviço está acessível
#   prefixo_outra_funcao   <param> [host]  - Descrição


[[ -n "${_SERVICOS_NOMESERVICO_SH_LOADED:-}" ]] && return 0
readonly _SERVICOS_NOMESERVICO_SH_LOADED=1

source "$(dirname "${BASH_SOURCE[0]}")/../redes.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../alerta.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../systemu.sh"

readonly _PREFIXO_PORTA_PADRAO=XXXX

function prefixo_esta_rodando() {
    # Verifica se o serviço está aceitando conexões TCP na porta informada.
    # Não requer cliente externo instalado.
    # Retorna 0 se a porta estiver aberta, 1 caso contrário.
    # Modo de uso: prefixo_esta_rodando
    #              prefixo_esta_rodando "servidor.local" 5433
    local host="${1:-localhost}"
    local porta="${2:-$_PREFIXO_PORTA_PADRAO}"
    con_checar_porta "$host" "$porta"
}

function prefixo_outra_funcao() {
    # Descrição.
    # Requer <cliente> instalado.
    # Retorna 0 em caso de sucesso, 1 caso contrário.
    # Modo de uso: prefixo_outra_funcao "param" "servidor.local"
    local param="$1"
    local host="${2:-localhost}"
    local porta="${3:-$_PREFIXO_PORTA_PADRAO}"

    if ! sys_programa_esta_instalado "<cliente>"; then
        erro "<cliente> não encontrado. Instale <cliente> para usar esta função."
        return 1
    fi

    ...
}
```

#### Regras

- A primeira função do módulo deve ser `prefixo_esta_rodando`, verificando apenas a porta via `con_checar_porta` — sem cliente externo.
- Todas as funções que usam cliente externo (`psql`, `curl`, `redis-cli`, etc.) devem verificar com `sys_programa_esta_instalado` antes de usá-lo e emitir `erro` claro se ausente.
- `host` e `porta` são sempre parâmetros opcionais, com `localhost` e a porta padrão do serviço como defaults.
- Credenciais e configurações de autenticação devem ser lidas de variáveis de ambiente, nunca hardcoded.
- Módulos de serviço não devem depender de outros módulos de serviço.

---

### Arquivos obrigatórios por módulo

Ao criar um módulo, os seguintes arquivos devem ser criados junto:

| Arquivo | Primitivo | Serviço |
|---|---|---|
| `lib/modulo.sh` ou `lib/servicos/modulo.sh` | Sim | Sim |
| `docs/modulo.md` ou `docs/servicos/modulo.md` | Sim | Sim |
| `examples/exemplo_modulo.sh` ou `examples/servicos/exemplo_modulo.sh` | Recomendado | Recomendado |
| `tests/unit/teste_modulo.sh` | Recomendado | Sim |

#### Estrutura do arquivo de documentação

```markdown
# nomemodulo — Descrição em uma linha

**Arquivo:** `lib/[servicos/]modulo.sh`
[**Camada:** serviços]   ← apenas para módulos de serviço
**Dependências:** `dep1.sh`, `dep2.sh`

Parágrafo descritivo.

## Referência rápida

| Função | Descrição |
|--------|-----------|
| `prefixo_funcao1 <param>` | Descrição |

## Funções

### `prefixo_funcao1 <param> [opcional]`

Descrição detalhada.

```bash
# exemplos de uso
prefixo_funcao1 "valor"
resultado=$(prefixo_funcao1 "valor")
```
```

## Dependências entre módulos

```
# Primitivos
sinais.sh          ← (nenhuma)
systemu.sh         ← (nenhuma)
cores.sh           ← (nenhuma)
logu.sh            ← (nenhuma)
alerta.sh          ← cores.sh, logu.sh
spinner.sh         ← sinais.sh
retryu.sh          ← spinner.sh
runu.sh            ← spinner.sh
inputs.sh          ← validau.sh, sinais.sh
procesu.sh         ← systemu.sh, sinais.sh
servicou.sh        ← systemu.sh, alerta.sh
redes.sh           ← systemu.sh, alerta.sh
tempu.sh           ← sinais.sh, alerta.sh
pkgu.sh            ← distu.sh
crypto.sh          ← systemu.sh, alerta.sh
textfilesu.sh      ← alerta.sh, backupu.sh
paralelo.sh        ← sinais.sh, dryrun.sh
metricsu.sh        ← dryrun.sh

# Serviços
servicos/conectividade.sh  ← redes.sh
servicos/postgres.sh       ← redes.sh, alerta.sh, systemu.sh
servicos/jboss.sh          ← redes.sh, alerta.sh, systemu.sh
```

## Convenções

- Funções de predicado (`e_*`, `arquivo_*`) retornam **0 para verdadeiro** e **1 para falso**, permitindo uso direto em condicionais.
- Funções de contagem imprimem o resultado no **stdout como inteiro puro**, sem unidade.
- Funções que modificam arquivos realizam a operação **in-place** a menos que indicado o contrário.
- Todas as funções retornam **1** se o arquivo ou diretório informado não existir.
- Guard variables (`_MODULO_SH_LOADED`) protegem contra importações circulares e duplas.

## Convenções de Booleanos

Este projeto possui três padrões de booleanos. Entenda qual usar:

### Padrão 1: Flags de CLI (argsu.sh)
- **Verdadeiro:** `"1"` (string)  
- **Falso:** `""` (vazio)
- **Verificação:** `[ "$VAR" = "1" ]`
- **Uso:** Argumentos de linha de comando (`--verbose`)

### Padrão 2: Nivelação (logu.sh)
- **Valores:** Números inteiros (0, 1, 2, 3)
- **Verificação:** `[ $VAR -lt $OUTRO ]` (comparação numérica)
- **Uso:** Níveis de log (DEBUG=0, INFO=1, etc.)

### Padrão 3: Predicados (filesu.sh, validau.sh)
- **Verdadeiro:** `return 0`
- **Falso:** `return 1`  
- **Verificação:** `if predicate; then ... fi`
- **Uso:** Validações e testes

### NÃO recomendado
- ❌ Não use `"true"` / `"false"`  
- ❌ Não misture padrões em uma função
- ❌ Não compare string com `-lt` / `-gt`