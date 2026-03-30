# datau — Timestamps, formatação de datas e cálculo de durações

**Arquivo:** `datau.sh`
**Dependências:** nenhuma

Fornece funções para formatação de datas, geração de timestamps para nomes de arquivo e cálculo de durações.

## Referência rápida

| Função | Formato de saída | Exemplo |
|--------|-----------------|---------|
| `timestamp` | `YYYYMMDD_HHMMSS` | `20241215_143022` |
| `data_formatada` | `DD/MM/YYYY HH:MM:SS` | `15/12/2024 14:30:22` |
| `data_iso` | `YYYY-MM-DDTHH:MM:SS` | `2024-12-15T14:30:22` |
| `data_unix` | Segundos desde epoch | `1734265822` |
| `duracao` | Segundos (inteiro) | `3600` |
| `duracao_formatada` | `HH:MM:SS` | `01:00:00` |

## Funções

### `timestamp`

Retorna a data e hora atual em formato compacto, sem espaços, adequado para nomes de arquivos.

```bash
arquivo="backup_$(timestamp).tar.gz"
# → backup_20241215_143022.tar.gz

mkdir "relatorio_$(timestamp)"
```

---

### `data_formatada`

Retorna a data e hora atual em formato legível para exibição ao usuário.

```bash
echo "Iniciado em: $(data_formatada)"
# → Iniciado em: 15/12/2024 14:30:22
```

---

### `data_iso`

Retorna a data e hora atual no formato ISO 8601, amplamente usado em APIs e sistemas externos.

```bash
echo "Timestamp ISO: $(data_iso)"
# → Timestamp ISO: 2024-12-15T14:30:22
```

---

### `data_unix`

Retorna o timestamp Unix atual (segundos desde 01/01/1970 UTC). Útil como referência para calcular durações.

```bash
inicio=$(data_unix)
# ... operações demoradas ...
fim=$(data_unix)
echo "Duração: $(duracao $inicio $fim) segundos"
```

---

### `duracao <inicio> <fim>`

Calcula a diferença em segundos entre dois timestamps Unix.

```bash
inicio=$(data_unix)
sleep 2
fim=$(data_unix)
echo "$(duracao $inicio $fim) segundos"  # → 2
```

---

### `duracao_formatada <segundos>`

Converte uma duração em segundos para o formato `HH:MM:SS`.

```bash
duracao_formatada 3661    # → 01:01:01
duracao_formatada 90      # → 00:01:30
duracao_formatada 0       # → 00:00:00
```

## Exemplo: medir tempo de execução

```bash
source "$BASHBASE/datau.sh"

inicio=$(data_unix)
info "Iniciando processamento em $(data_formatada)..."

# ... operações demoradas ...

fim=$(data_unix)
tempo=$(duracao "$inicio" "$fim")
sucesso "Concluído em $(duracao_formatada $tempo)"
```
