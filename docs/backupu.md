# backupu — Backup de arquivos e diretórios com timestamp

**Arquivo:** `backupu.sh`
**Dependências:** nenhuma

Fornece utilitários para criar cópias de segurança com timestamps automáticos e limpeza periódica de backups antigos.

## Referência rápida

| Função | Descrição |
|--------|-----------|
| `backup_arquivo` | Copia arquivo com timestamp no nome |
| `backup_diretorio` | Compacta diretório em `.tar.gz` com timestamp |
| `limpar_backups_antigos` | Remove backups com mais de N dias |

## Funções

### `backup_arquivo <arquivo> [destino]`

Cria uma cópia de segurança de um arquivo adicionando timestamp ao nome. O arquivo de backup é criado no mesmo diretório do original por padrão, ou no diretório de destino informado. Em caso de sucesso, imprime o caminho do backup criado.

**Formato do nome:** `<nome_original>.<YYYYMMDD_HHMMSS>.bak`

**Retorno:** 1 se o arquivo não existir.

**Exemplo:**
```bash
backup_arquivo /etc/nginx/nginx.conf
# → /etc/nginx/nginx.conf.20241215_143022.bak

backup_arquivo /etc/nginx/nginx.conf /var/backups
# → /var/backups/nginx.conf.20241215_143022.bak

# Capturar o caminho do backup criado:
bak=$(backup_arquivo /etc/app.conf) && echo "Backup em: $bak"
```

---

### `backup_diretorio <diretorio> [destino]`

Compacta um diretório inteiro em um arquivo `.tar.gz` com timestamp. O arquivo resultante é criado no diretório de destino, ou no diretório atual se não for informado. Em caso de sucesso, imprime o caminho do arquivo criado.

**Formato do nome:** `<nome_dir>_<YYYYMMDD_HHMMSS>.tar.gz`

**Retorno:** 1 se o diretório não existir.

**Exemplo:**
```bash
backup_diretorio /var/www/html
# → ./html_20241215_143022.tar.gz

backup_diretorio /var/www/html /var/backups
# → /var/backups/html_20241215_143022.tar.gz
```

---

### `limpar_backups_antigos <diretorio> [dias]`

Remove arquivos `.bak` e `.tar.gz` com mais de N dias em um diretório. A busca é feita apenas no nível raiz (sem recursão). O valor padrão é 30 dias.

**Retorno:** 1 se o diretório não existir.

**Exemplo:**
```bash
limpar_backups_antigos /var/backups 15   # remove backups com mais de 15 dias
limpar_backups_antigos /var/backups      # usa o padrão de 30 dias
```

## Uso com textfilesu.sh

As funções de substituição em `textfilesu.sh` chamam `backup_arquivo` automaticamente antes de modificar arquivos. O módulo `backupu.sh` é carregado como dependência de `textfilesu.sh`.
