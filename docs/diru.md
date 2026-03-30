# diru — Inspeção e metadados de diretórios

**Arquivo:** `diru.sh`
**Dependências:** nenhuma

Fornece operações de contagem, listagem e consulta de metadados sobre diretórios. Todas as funções operam recursivamente (incluindo subdiretórios) salvo indicação em contrário. Erros de permissão em subdiretórios são suprimidos silenciosamente.

## Referência rápida

| Função | Descrição |
|--------|-----------|
| `dir_tamanho_do_diretorio` | Tamanho total em formato legível (ex: `1.4G`) |
| `dir_contar_arquivos` | Número de arquivos regulares (recursivo) |
| `dir_contar_diretorios` | Número de diretórios (recursivo, inclui o próprio) |
| `dir_contar_links_simbolicos` | Número de links simbólicos (recursivo) |
| `dir_contar_tudo` | Total de todos os itens (recursivo, inclui o próprio) |
| `dir_listar_arquivos` | Caminhos completos de todos os arquivos regulares |
| `dir_listar_diretorios` | Caminhos completos de todos os diretórios |
| `dir_listar_links_simbolicos` | Caminhos completos de todos os links simbólicos |
| `dir_listar_tudo` | Caminhos completos de todos os itens |
| `dir_permissoes_do_diretorio` | Permissões no formato `drwxr-xr-x` |
| `dir_dono_do_diretorio` | Nome do usuário proprietário |
| `dir_grupo_do_diretorio` | Nome do grupo proprietário |
| `dir_get_data_hora_ultima_modificacao` | Data e hora da última modificação |

Todas as funções retornam **1** se o diretório informado não existir.

## Funções

### `dir_tamanho_do_diretorio <dir>`

Retorna o tamanho total do diretório e seu conteúdo em formato humano (`du -sh`).

```bash
dir_tamanho_do_diretorio /var/log
# → 234M

echo "Logs ocupam: $(dir_tamanho_do_diretorio /var/log)"
```

---

### `dir_contar_arquivos <dir>`

Conta arquivos regulares (`-type f`) recursivamente. Links e diretórios não são contados.

```bash
dir_contar_arquivos /etc    # → 312
[ "$(dir_contar_arquivos /tmp)" -gt 100 ] && alerta "Muitos arquivos em /tmp"
```

---

### `dir_contar_diretorios <dir>`

Conta diretórios recursivamente. **Atenção:** o próprio diretório raiz é incluído na contagem. Um diretório vazio retorna `1`.

```bash
dir_contar_diretorios /etc
subdirs=$(( $(dir_contar_diretorios /etc) - 1 ))  # descontar o próprio dir
```

---

### `dir_contar_links_simbolicos <dir>`

Conta links simbólicos recursivamente. Links quebrados também são contados.

```bash
dir_contar_links_simbolicos /usr/bin
```

---

### `dir_contar_tudo <dir>`

Conta todos os itens (arquivos, diretórios e links) recursivamente. O próprio diretório raiz é incluído.

```bash
dir_contar_tudo /home/usuario
```

---

### `dir_listar_arquivos <dir>`

Lista os caminhos completos de todos os arquivos regulares, um por linha.

```bash
dir_listar_arquivos /etc/nginx
dir_listar_arquivos /var/log | grep "\.log$"
dir_listar_arquivos /tmp | xargs rm -f
```

---

### `dir_listar_diretorios <dir>`

Lista os caminhos completos de todos os diretórios. O próprio diretório raiz é incluído como primeiro item.

```bash
dir_listar_diretorios /etc
dir_listar_diretorios /var | grep "cache"
```

---

### `dir_listar_links_simbolicos <dir>`

Lista os caminhos completos de todos os links simbólicos. Links quebrados também são incluídos.

```bash
dir_listar_links_simbolicos /usr/bin
dir_listar_links_simbolicos /etc | xargs ls -la
```

---

### `dir_listar_tudo <dir>`

Lista os caminhos completos de todos os itens (arquivos, diretórios, links). O próprio diretório raiz é incluído como primeiro item.

```bash
dir_listar_tudo /etc/nginx
dir_listar_tudo /var/log | wc -l
```

---

### `dir_permissoes_do_diretorio <dir>`

Retorna as permissões no formato simbólico de 10 caracteres (`drwxr-xr-x`).

```bash
dir_permissoes_do_diretorio /etc/ssh
# → drwxr-xr-x

if [[ "$(dir_permissoes_do_diretorio /var/secret)" == "drwx------" ]]; then
    echo "Acesso restrito ao dono"
fi
```

---

### `dir_dono_do_diretorio <dir>`

Retorna o nome de usuário do proprietário.

```bash
dir_dono_do_diretorio /var/www/html
if [[ "$(dir_dono_do_diretorio /app)" != "www-data" ]]; then
    erro "Diretório com dono incorreto"
fi
```

---

### `dir_grupo_do_diretorio <dir>`

Retorna o nome do grupo proprietário.

```bash
dir_grupo_do_diretorio /var/www/html
```

---

### `dir_get_data_hora_ultima_modificacao <dir>`

Retorna a data e hora da última modificação no formato `YYYY-MM-DD HH:MM:SS.NNNNNNNNN +ZZZZ`. A modificação do diretório ocorre quando arquivos são criados, renomeados ou removidos diretamente nele (não em subdirectórios).

```bash
dir_get_data_hora_ultima_modificacao /var/spool/cron
echo "Último acesso: $(dir_get_data_hora_ultima_modificacao /tmp)"
```
