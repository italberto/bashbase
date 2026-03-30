# tempu — Arquivos e diretórios temporários com cleanup automático

**Arquivo:** `lib/tempu.sh`
**Dependências:** `sinais.sh`, `alerta.sh`
**Requer:** Bash 4.3+

Fornece funções para criar arquivos e diretórios temporários que são removidos automaticamente ao fim do script — seja por saída normal, SIGINT, SIGTERM ou SIGHUP — por meio da integração com a pilha de cleanup de `sinais.sh`.

## O problema do subshell

As funções `tmp_criar_arquivo` e `tmp_criar_diretorio` recebem o **nome de uma variável** como primeiro argumento e a preenchem com o caminho criado. Isso evita o uso de subshell (`$(...)`), que impediria o registro do cleanup no processo pai:

```bash
# ERRADO: subshell — cleanup não é registrado no processo pai
arq=$(tmp_criar_arquivo "prefixo")

# CORRETO: nameref — caminho em $arq, cleanup registrado no processo pai
tmp_criar_arquivo arq "prefixo"
```

Para arquivos criados via subshell ou `mktemp` diretamente, use `tmp_registrar`.

## Referência rápida

| Função | Descrição |
|--------|-----------|
| `tmp_criar_arquivo <variavel> [prefixo] [sufixo]` | Cria arquivo temporário com cleanup automático |
| `tmp_criar_diretorio <variavel> [prefixo]` | Cria diretório temporário com cleanup automático |
| `tmp_registrar <caminho>` | Registra caminho existente para cleanup automático |
| `tmp_limpar_tudo` | Remove imediatamente todos os temporários do módulo |

## Funções

### `tmp_criar_arquivo <variavel> [prefixo] [sufixo]`

Cria um arquivo temporário em `$TMPDIR` (ou `/tmp`) e armazena o caminho na variável indicada. O arquivo é removido automaticamente na saída do script.

O nome do arquivo segue o padrão `<prefixo>.XXXXXX<sufixo>`.

```bash
tmp_criar_arquivo config_arq "app-config" ".json"
echo '{"env":"prod"}' > "$config_arq"

tmp_criar_arquivo relatorio "relatorio" ".csv"
gerar_csv > "$relatorio"
```

---

### `tmp_criar_diretorio <variavel> [prefixo]`

Cria um diretório temporário em `$TMPDIR` (ou `/tmp`) e armazena o caminho na variável indicada. O diretório e **todo o seu conteúdo** são removidos com `rm -rf` na saída do script.

```bash
tmp_criar_diretorio staging "deploy"
cp artefatos/* "$staging/"
rsync -a "$staging/" servidor:/app/

tmp_criar_diretorio work_dir
tar -xf pacote.tar.gz -C "$work_dir"
processar "$work_dir/dados.csv"
```

---

### `tmp_registrar <caminho>`

Registra um arquivo ou diretório existente no cleanup automático. Útil quando o temporário foi criado fora do módulo (via `mktemp` diretamente, em subshells, ou por ferramentas externas).

Retorna 1 se o caminho não existir.

```bash
# Arquivo criado por ferramenta externa
openssl genrsa -out /tmp/chave_temp.pem 2048
tmp_registrar "/tmp/chave_temp.pem"

# Arquivo criado em subshell
arq=$(mktemp --suffix=".sql")
tmp_registrar "$arq"
gerar_sql > "$arq"
```

---

### `tmp_limpar_tudo`

Remove imediatamente todos os temporários registrados por este módulo, sem esperar o fim do script. Útil quando os temporários não são mais necessários e o espaço em disco é uma preocupação.

Os handlers em `sinais.sh` tentarão remover os caminhos novamente no EXIT, mas `rm` sobre caminho inexistente é inofensivo.

```bash
tmp_criar_arquivo dados "export" ".csv"
exportar_dados > "$dados"
enviar_relatorio "$dados"

# Não precisa mais dos temporários — libera espaço imediatamente
tmp_limpar_tudo

continuar_processamento_longo  # roda sem os arquivos temporários em disco
```

## Comportamento no cleanup

O cleanup é delegado à pilha de `sinais.sh`, garantindo que outros handlers registrados no script sejam respeitados:

| Evento | Cleanup executado? |
|---|---|
| Saída normal (`exit 0` ou fim do script) | Sim |
| `exit` com qualquer código | Sim |
| SIGINT (Ctrl+C) | Sim |
| SIGTERM | Sim |
| SIGHUP | Sim |
| SIGKILL (`kill -9`) | Não — limitação do Bash |

## Exemplo completo

```bash
#!/usr/bin/env bash
source "$BASHBASE/lib/tempu.sh"
source "$BASHBASE/lib/alerta.sh"

# Cria temporários com cleanup automático
tmp_criar_arquivo payload "api-payload" ".json"
tmp_criar_diretorio extracao "pkg"

info "Preparando payload..."
gerar_json > "$payload"

info "Extraindo pacote..."
tar -xf pacote.tar.gz -C "$extracao"

info "Enviando..."
curl -X POST -d "@$payload" https://api.exemplo.com/upload

# Ao sair (normalmente ou por sinal), $payload e $extracao são removidos
sucesso "Concluído."
```
