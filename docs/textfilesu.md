# textfilesu — Contagem, busca e substituição em arquivos de texto

**Arquivo:** `textfilesu.sh`
**Dependências:** `alerta.sh`, `backupu.sh`

Fornece operações de contagem de linhas/palavras/bytes, busca por conteúdo, substituição de texto com backup automático e conversão de line endings.

As funções de contagem imprimem o resultado no stdout como **inteiro puro**, sem unidade, para facilitar comparações aritméticas. As funções de substituição modificam o arquivo em disco (in-place). Todas retornam 1 se o arquivo não existir.

## Referência rápida

| Função | Descrição |
|--------|-----------|
| `tf_conta_linhas` | Número total de linhas |
| `tf_conta_palavras` | Número total de palavras |
| `tf_conta_caracteres` | Número de caracteres Unicode |
| `tf_conta_bytes` | Número de bytes (tamanho bruto) |
| `tf_conta_linhas_nao_vazias` | Linhas com ao menos um caractere não-espaço |
| `tf_conta_linhas_unicas` | Número de linhas distintas |
| `tf_conta_ocorrencias` | Número de ocorrências de uma palavra/padrão |
| `tf_arquivo_contem` | Verdadeiro se o arquivo contiver a palavra |
| `tf_substitui_tudo` | Substitui todas as ocorrências (com backup) |
| `tf_substitui_primeira` | Substitui apenas a primeira ocorrência |
| `tf_substitui_ultima` | Substitui apenas a última ocorrência |
| `tf_e_fim_de_linha_unix` | Verdadeiro se line ending for LF (Unix) |
| `tf_e_fim_de_linha_windows` | Verdadeiro se line ending for CRLF (Windows) |
| `tf_converte_para_fim_de_linha_unix` | Converte CRLF → LF |
| `tf_converte_para_fim_de_linha_windows` | Converte LF → CRLF |

## Contagem

### `tf_conta_linhas <arquivo>`

```bash
tf_conta_linhas /var/log/syslog    # → 1842
total=$(tf_conta_linhas "$arq")
echo "$arq tem $total linhas"
```

### `tf_conta_palavras <arquivo>`

Uma "palavra" é qualquer sequência de caracteres não-espaço separada por espaço, tab ou newline (definição de `wc -w`).

```bash
tf_conta_palavras relatorio.txt
[ "$(tf_conta_palavras "$arq")" -gt 500 ] && alerta "Texto longo"
```

### `tf_conta_caracteres <arquivo>`

Conta caracteres Unicode (`wc -m`). Diferente de `conta_bytes`: acentos e emojis contam como 1 caractere mesmo ocupando múltiplos bytes. Depende do locale do sistema estar configurado para UTF-8.

```bash
tf_conta_caracteres artigo.txt
```

### `tf_conta_bytes <arquivo>`

Tamanho bruto em bytes (`wc -c`). Para arquivos com caracteres multibyte, difere de `tf_conta_caracteres`.

```bash
[ "$(tf_conta_bytes "$arq")" -gt 1048576 ] && alerta "Arquivo maior que 1 MB"
```

### `tf_conta_linhas_nao_vazias <arquivo>`

Linhas compostas apenas por espaços e tabs são tratadas como vazias e não entram na contagem.

```bash
cod=$(tf_conta_linhas_nao_vazias "$arq")
vaz=$(( $(tf_conta_linhas "$arq") - cod ))
echo "$vaz linhas em branco no arquivo"
```

### `tf_conta_linhas_unicas <arquivo>`

Linhas duplicadas são contadas apenas uma vez, independente de quantas vezes apareçam. A comparação é feita após ordenação interna (`sort -u`).

```bash
unicos=$(tf_conta_linhas_unicas ips.txt)
total=$(tf_conta_linhas ips.txt)
echo "$unicos entradas distintas de $total total"
```

### `tf_conta_ocorrencias <arquivo> <padrão>`

Conta quantas vezes um padrão aparece no arquivo (não apenas linhas, mas cada ocorrência individualmente). O padrão é tratado como BRE do grep.

```bash
tf_conta_ocorrencias /var/log/auth.log "Failed password"
tf_conta_ocorrencias config.yaml "host:"
```

## Busca

### `tf_arquivo_contem <arquivo> <padrão>`

Retorna 0 se o arquivo contiver o padrão, 1 caso contrário. Para no primeiro match.

```bash
tf_arquivo_contem /etc/fstab "UUID" && echo "fstab usa UUID"
tf_arquivo_contem "$config" "^DEBUG=1" || alerta "Debug não ativado"
```

## Substituição

As funções de substituição escapam automaticamente `\`, `&` e `|` para uso seguro com `sed`, aceitando literais como URLs e caminhos.

### `tf_substitui_tudo <arquivo> <antigo> <novo>`

Substitui **todas** as ocorrências. Cria backup automático via `backupu.sh` antes de modificar. Se o backup falhar, a substituição é cancelada.

```bash
tf_substitui_tudo /etc/app/config.env "host_antigo" "host_novo"
tf_substitui_tudo nginx.conf "http://api.local" "https://api.prod.com"
```

### `tf_substitui_primeira <arquivo> <antigo> <novo>`

Substitui apenas a **primeira** ocorrência. Útil quando o padrão aparece múltiplas vezes mas apenas a primeira instância deve ser alterada.

```bash
tf_substitui_primeira /etc/hosts "127.0.0.1 localhost" "127.0.0.1 meuhost"
```

### `tf_substitui_ultima <arquivo> <antigo> <novo>`

Substitui apenas a **última** ocorrência. A implementação lê o arquivo inteiro em memória — evite em arquivos muito grandes (> algumas dezenas de MB).

```bash
tf_substitui_ultima deploy.log "status: pending" "status: done"
```

## Conversão de line endings

### `tf_e_fim_de_linha_unix <arquivo>` / `e_fim_de_linha_windows <arquivo>`

Verificam o tipo de line ending do arquivo. Retornam 0 se o tipo corresponder, 1 caso contrário.

```bash
tf_e_fim_de_linha_unix script.sh    || tf_converte_para_fim_de_linha_unix script.sh
tf_e_fim_de_linha_windows "$arq"    && tf_converte_para_fim_de_linha_unix "$arq"
```

### `tf_converte_para_fim_de_linha_unix <arquivo>`

Remove os `\r` de cada linha (CRLF → LF). Arquivos que já usam LF não são afetados.

```bash
tf_converte_para_fim_de_linha_unix config.env
```

### `tf_converte_para_fim_de_linha_windows <arquivo>`

Adiciona `\r` ao final de cada linha (LF → CRLF). **Atenção:** aplicar em um arquivo que já tem CRLF duplica o `\r`. Verifique com `tf_e_fim_de_linha_unix` antes de converter.

```bash
tf_e_fim_de_linha_unix "$arq" && tf_converte_para_fim_de_linha_windows "$arq"
```
