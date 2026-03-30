# filesu — Verificação, metadados e comparação de arquivos

**Arquivo:** `filesu.sh`
**Dependências:** nenhuma

Fornece predicados de existência, tipo e permissão, funções de conversão de tamanho, comparação entre arquivos e espera por eventos no sistema de arquivos. As funções de predicado retornam **0 para verdadeiro** e **1 para falso**, permitindo uso direto em condicionais.

## Referência rápida

| Função | Descrição |
|--------|-----------|
| `arquivo_existe` | Verdadeiro se o arquivo existir (arquivo regular) |
| `e_arquivo_vazio` | Verdadeiro se existir e tiver 0 bytes |
| `e_arquivo_regular` | Verdadeiro se for arquivo regular (não dir, não link) |
| `e_diretorio` | Verdadeiro se for diretório |
| `e_link_simbolico` | Verdadeiro se for link simbólico |
| `e_executavel` | Verdadeiro se tiver permissão de execução |
| `e_legivel` | Verdadeiro se tiver permissão de leitura |
| `e_gravavel` | Verdadeiro se tiver permissão de escrita |
| `e_de_propriedade_do_usuario` | Verdadeiro se o usuário for o dono |
| `e_de_propriedade_do_grupo` | Verdadeiro se o grupo for o dono |
| `bytes_legivel` | Converte bytes para formato humano (ex: `1.4 GB`) |
| `tamanho_do_arquivo` | Tamanho em bytes (inteiro) |
| `bytes_em_kilobytes` | Converte bytes para KB (divisão inteira) |
| `bytes_em_megabytes` | Converte bytes para MB (divisão inteira) |
| `bytes_em_gigabytes` | Converte bytes para GB (divisão inteira) |
| `compara_tamanho_dos_arquivo_ab` | Compara tamanhos via exit code |
| `diretorio_do_arquivo` | Diretório pai do arquivo |
| `nome_do_arquivo` | Nome sem o caminho |
| `extensao_do_arquivo` | Extensão sem o ponto |
| `get_data_hora_ultima_modificacao` | Data e hora da última modificação |
| `aguardar_arquivo` | Aguarda arquivo aparecer ou sumir |

## Funções

### Predicados de existência e tipo

```bash
arquivo_existe /etc/hosts       && echo "existe"
e_arquivo_vazio /tmp/saida.txt  && erro "Nenhum resultado gerado"
e_arquivo_regular "$entrada"    || erro "Esperado arquivo regular"
e_diretorio /var/backups        || mkdir -p /var/backups
e_link_simbolico /usr/bin/python && echo "python é um link"
```

### Predicados de permissão

```bash
e_executavel /usr/bin/curl  || erro "curl sem permissão de execução"
e_legivel /etc/shadow       || erro "Sem permissão de leitura"
e_gravavel "$config"        || erro "Arquivo somente leitura"
```

### Predicados de propriedade

```bash
e_de_propriedade_do_usuario /var/www/html "www-data" || alerta "Dono incorreto"
e_de_propriedade_do_grupo   /dados "deploy"          || alerta "Grupo incorreto"
e_de_propriedade_do_usuario "$arq" "$(whoami)"       || erro "Arquivo não é seu"
```

### `bytes_legivel <bytes>`

Converte um valor em bytes para formato humano com unidade automática.

```bash
bytes_legivel 512         # → 512 B
bytes_legivel 1500        # → 1.5 KB
bytes_legivel 1503238553  # → 1.4 GB
echo "Tamanho: $(bytes_legivel "$(tamanho_do_arquivo /var/log/syslog)")"
```

### `tamanho_do_arquivo <arquivo>`

Retorna o tamanho em bytes como inteiro puro.

```bash
tam=$(tamanho_do_arquivo "$arq")
[ "$tam" -gt 1048576 ] && alerta "Arquivo maior que 1 MB"
```

### Conversões de tamanho

```bash
bytes_em_kilobytes 2048     # → 2
bytes_em_megabytes 5242880  # → 5
bytes_em_gigabytes 10737418240  # → 10
```

> Todas usam divisão inteira (truncamento, sem arredondamento). Para formato com unidade, prefira `bytes_legivel`.

### `compara_tamanho_dos_arquivo_ab <A> <B>`

Compara tamanhos via exit code. Não imprime nada.

| Exit code | Significado |
|-----------|------------|
| `0` | A e B têm o mesmo tamanho |
| `1` | A é maior que B |
| `2` | A é menor que B |
| `3` | Um ou ambos os arquivos não existem |

```bash
compara_tamanho_dos_arquivo_ab original.tar backup.tar
case $? in
    0) echo "Tamanhos idênticos" ;;
    1) echo "Original é maior"   ;;
    2) echo "Backup é maior"     ;;
    3) erro "Um dos arquivos não existe" ;;
esac
```

### Metadados de caminho

```bash
diretorio_do_arquivo /etc/nginx/nginx.conf  # → /etc/nginx
nome_do_arquivo      /etc/nginx/nginx.conf  # → nginx.conf
extensao_do_arquivo  /var/log/app.log       # → log
extensao_do_arquivo  /usr/bin/bash          # → bash  (sem extensão: retorna o nome)
```

### `get_data_hora_ultima_modificacao <arquivo>`

Retorna a data e hora da última modificação no formato `YYYY-MM-DD HH:MM:SS.NNNNNNNNN +ZZZZ`. Funciona também com diretórios.

```bash
echo "Modificado em: $(get_data_hora_ultima_modificacao /etc/hosts)"
```

### `aguardar_arquivo <arquivo> <modo> [timeout]`

Aguarda um arquivo aparecer ou desaparecer, verificando a cada segundo. Modos: `"aparecer"` ou `"desaparecer"`. O timeout padrão é 30 segundos.

**Retorno:** 0 se a condição for satisfeita, 1 se o timeout for atingido.

```bash
# Aguardar até 60s que um processo crie um arquivo de conclusão:
aguardar_arquivo /tmp/processo.done aparecer 60 || erro "Timeout: processo não concluiu"

# Aguardar até 30s que um lockfile seja liberado:
aguardar_arquivo /var/run/app.lock desaparecer 30 || erro "Timeout: lock não liberado"
```
