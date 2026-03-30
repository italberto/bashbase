# dryrun — Modo dry-run global

**Arquivo:** `dryrun.sh`
**Dependências:** nenhuma

Quando `DRYRUN="1"`, todos os módulos da biblioteca que causam efeitos colaterais simulam suas operações sem executá-las, imprimindo no stderr o que seria feito. Quando `DRYRUN=""` (padrão), o comportamento é idêntico ao normal.

## Referência rápida

| Função | Descrição |
|--------|-----------|
| `dryrun_exec` | Executa um comando ou simula em dry-run |
| `dryrun_gravar` | Acrescenta linha a um arquivo ou simula |
| `dryrun_ativo` | Retorna 0 se dry-run estiver ativo |

**Variável global:**

| Variável | Valores | Padrão |
|----------|---------|--------|
| `DRYRUN` | `"1"` (ativo) ou `""` (normal) | `""` |

## Ativação

### Via linha de comando com `argsu.sh`

```bash
source "$BASHBASE/argsu.sh"
source "$BASHBASE/dryrun.sh"

arg_definir "--dry-run" DRYRUN "" "Simula operações sem executar nada" "boolean"
arg_parsear "$@" || exit 1
```

```bash
./meu_script.sh --dry-run
```

### Via variável de ambiente

```bash
DRYRUN=1 ./meu_script.sh
```

### Programaticamente

```bash
DRYRUN="1"
source "$BASHBASE/dryrun.sh"
```

## Funções

### `dryrun_exec <descricao> <cmd...>`

Executa um comando, ou em dry-run imprime `[DRY-RUN] <descricao>` no stderr e retorna 0 sem executar nada.

```bash
dryrun_exec "cp '$origem' '$destino'" cp "$origem" "$destino"
dryrun_exec "systemctl restart nginx" systemctl restart nginx
dryrun_exec "rm -rf '$dir'" rm -rf "$dir"
```

---

### `dryrun_gravar <arquivo> <conteudo>`

Acrescenta uma linha ao arquivo, ou em dry-run imprime o que seria escrito.

```bash
dryrun_gravar /etc/app/config.env "DB_HOST=localhost"
# Em dry-run: [DRY-RUN] escrever em '/etc/app/config.env': DB_HOST=localhost
```

---

### `dryrun_ativo`

Retorna 0 se `DRYRUN="1"`, útil para lógica condicional dentro das funções.

```bash
dryrun_ativo && echo "Modo simulação ativo — nenhuma alteração será feita"
```

## Cobertura por módulo

| Módulo | Operações simuladas | Operações não afetadas |
|--------|--------------------|-----------------------|
| `backupu.sh` | `backup_arquivo`, `backup_diretorio`, `limpar_backups_antigos` | — |
| `configu.sh` | `config_escrever`, `config_remover`, `config_carregar` | `config_ler`, `config_existe` |
| `downu.sh` | `dw_baixar_nativo`, `dw_download`, `dw_download_quieto` | `dw_comando_de_download` |
| `logu.sh` | `log_rodar` | `log_debug/info/warn/erro` (log é trilha de auditoria) |
| `mockfiles.sh` | `criar_arquivo_aleatorio`, `criar_arquivo_aleatorio_head`, `criar_arquivo_aleatorio_truncate` | — |
| `pkgu.sh` | `atualizar_pacote`, `instala_pacote`, `instala_pacote_quieto`, `remove_pacote`, `atualiza_pacote` | `procura_pacote` |
| `procesu.sh` | `matar_processo`, `lock_adquirir`, `lock_liberar` | `e_processo_rodando`, `aguardar_processo` |
| `runu.sh` | `executar`, `executar_remoto`, `executar_com_timeout` | — |
| `servicou.sh` | `servico_iniciar`, `servico_parar`, `servico_reiniciar`, `servico_habilitar`, `servico_desabilitar` | `servico_ativo`, `servico_status` |
| `textfilesu.sh` | `tf_substitui_tudo`, `tf_substitui_primeira`, `tf_substitui_ultima`, `tf_converte_para_fim_de_linha_unix`, `tf_converte_para_fim_de_linha_windows` | funções de contagem e leitura |

## Exemplo de saída em dry-run

```
$ DRYRUN=1 ./deploy.sh --host servidor01

[DRY-RUN] dw_download: wget -O 'app.tar.gz' 'https://releases.exemplo.com/app.tar.gz'
[DRY-RUN] backup_arquivo: cp '/etc/app/config.env' '/etc/app/config.env.20260329_143021.bak'
[DRY-RUN] config_escrever: substituir 'DB_HOST' em '/etc/app/config.env'
[DRY-RUN] servicou: systemctl restart 'app'
[DRY-RUN] pkgu: instalar pacote 'curl'
```

Nenhum arquivo é modificado, nenhum serviço é tocado, nenhum comando é executado.

## Comportamento especial

**`logu.sh`** — As funções de escrita (`log_info`, `log_erro` etc.) **não são suprimidas** em dry-run. O arquivo de log registra o que seria executado, servindo como trilha de auditoria da simulação. Apenas `log_rodar` (rotação física do arquivo) é simulada.

**`procesu.sh/lock_adquirir`** — Em dry-run, simula aquisição bem-sucedida sem criar o diretório de lock. A limpeza de locks fantasmas também é simulada. `lock_liberar` simula liberação sem deletar nada.

**`runu.sh/executar`** — Em dry-run, exibe a mensagem de conclusão com indicação `(dry-run)` para manter a consistência visual do terminal.
