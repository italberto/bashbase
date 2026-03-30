# downu — Download de arquivos via wget, curl ou TCP nativo

**Arquivo:** `downu.sh`
**Dependências:** `systemu.sh`

Detecta automaticamente a ferramenta de download disponível no sistema (`wget`, `curl` ou TCP nativo via `/dev/tcp`) e realiza o download com a sintaxe correta de cada ferramenta.

## Referência rápida

| Função | Descrição |
|--------|-----------|
| `comando_de_download` | Detecta e retorna o nome da ferramenta disponível |
| `download` | Download com saída no terminal |
| `download_quieto` | Download sem saída no terminal |
| `baixar_nativo` | Download via TCP puro sem wget/curl (apenas HTTP) |

## Funções

### `comando_de_download`

Detecta qual ferramenta de download está disponível no PATH e retorna seu nome. Prioridade: `wget` → `curl` → `baixar_nativo`.

```bash
cmd=$(comando_de_download)
echo "Usando: $cmd"   # → wget  (ou curl, ou baixar_nativo)
```

---

### `download <url> [destino]`

Realiza o download de uma URL com saída no terminal. Se o destino não for informado, usa o nome do arquivo extraído da URL.

```bash
download https://exemplo.com/arquivo.tar.gz
download https://exemplo.com/arquivo.tar.gz /tmp/meu_arquivo.tar.gz
```

---

### `download_quieto <url> [destino]`

Realiza o download sem exibir saída no terminal. Wrapper para `download` com stdout e stderr redirecionados para `/dev/null`.

```bash
download_quieto https://exemplo.com/script.sh /tmp/script.sh
```

---

### `baixar_nativo <url> <destino>`

Realiza o download via conexão TCP pura usando o built-in `/dev/tcp` do Bash. Suporta apenas HTTP (não HTTPS). Útil em ambientes mínimos sem `wget` ou `curl`.

**Limitações:** apenas HTTP, sem suporte a redirecionamentos, sem verificação TLS.

```bash
baixar_nativo http://exemplo.com/arquivo.txt /tmp/arquivo.txt
```
