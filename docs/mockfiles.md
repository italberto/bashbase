# mockfiles — Criação de arquivos fictícios para testes

**Arquivo:** `mockfiles.sh`
**Dependências:** nenhuma

Fornece três métodos diferentes para gerar arquivos com dados aleatórios ou fictícios, úteis para testar scripts que manipulam arquivos sem depender de dados reais.

## Referência rápida

| Função | Método | Dados | Velocidade |
|--------|--------|-------|-----------|
| `criar_arquivo_aleatorio` | `dd` + `/dev/urandom` | Aleatórios reais | Mais lento |
| `criar_arquivo_aleatorio_head` | `head` + `/dev/urandom` | Aleatórios reais | Moderado |
| `criar_arquivo_aleatorio_truncate` | `truncate` | Nulos (zeros) | Instantâneo |

## Funções

### `criar_arquivo_aleatorio <nome> <tamanho_kb>`

Cria um arquivo com dados verdadeiramente aleatórios usando `dd` e `/dev/urandom`. Garante conteúdo aleatório em cada byte. Mais indicado quando é necessário testar parsing de conteúdo binário.

```bash
criar_arquivo_aleatorio /tmp/teste.bin 512    # cria arquivo de 512 KB
criar_arquivo_aleatorio /tmp/grande.bin 10240  # 10 MB
```

---

### `criar_arquivo_aleatorio_head <nome> <tamanho_kb>`

Alternativa ao `dd` para sistemas onde `head` é mais eficiente. Produz o mesmo resultado com dados verdadeiramente aleatórios.

```bash
criar_arquivo_aleatorio_head /tmp/teste.bin 512
```

---

### `criar_arquivo_aleatorio_truncate <nome> <tamanho_kb>`

Cria um arquivo esparso do tamanho especificado usando `truncate`. O arquivo é criado instantaneamente independente do tamanho, pois o conteúdo é nulo (zeros) e não é fisicamente alocado em disco. Ideal para testar verificações de tamanho e comportamento com arquivos grandes sem ocupar espaço real.

```bash
criar_arquivo_aleatorio_truncate /tmp/enorme.bin 1048576   # 1 GB instantâneo
```

## Escolhendo o método

| Cenário | Método recomendado |
|---------|--------------------|
| Testar parsing de conteúdo binário | `criar_arquivo_aleatorio` ou `_head` |
| Testar verificações de tamanho de arquivo | `criar_arquivo_aleatorio_truncate` |
| Ambiente com restrição de espaço em disco | `criar_arquivo_aleatorio_truncate` |
| Testar compressão com dados reais | `criar_arquivo_aleatorio` |

## Exemplo

```bash
source "$BASHBASE/mockfiles.sh"

# Criar arquivos de teste de diferentes tamanhos
criar_arquivo_aleatorio          /tmp/pequeno.bin 100    # 100 KB, dados reais
criar_arquivo_aleatorio_truncate /tmp/grande.bin  10240  # 10 MB, zeros, instantâneo

# Testar a função de backup com arquivo real
backup_arquivo /tmp/pequeno.bin /tmp/backups/

# Limpar
rm -f /tmp/pequeno.bin /tmp/grande.bin
```
