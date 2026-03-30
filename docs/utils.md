# utils — Manipulação de strings e extração de campos

**Arquivo:** `utils.sh`
**Dependências:** nenhuma

Fornece operações básicas sobre strings que não estão disponíveis nativamente no Bash de forma conveniente, além de wrappers awk para extração e soma de campos em fluxos de texto. As implementações de string usam apenas recursos nativos do Bash, sem dependências externas.

## Referência rápida

| Função | Descrição |
|--------|-----------|
| `concatena` | Une elementos com um delimitador |
| `separa` | Divide uma string em elementos |
| `trim` | Remove espaços nas duas extremidades |
| `maiusculas` | Converte para maiúsculas |
| `minusculas` | Converte para minúsculas |
| `comeca_com` | Retorna 0 se a string começa com o prefixo |
| `termina_com` | Retorna 0 se a string termina com o sufixo |
| `contem` | Retorna 0 se a string contém a substring |
| `preenche_esquerda` | Alinha à direita preenchendo à esquerda |
| `preenche_direita` | Alinha à esquerda preenchendo à direita |
| `repete` | Repete a string N vezes |
| `campo` | Extrai campo N de stdin usando awk |
| `total` | Soma campo N de todas as linhas do stdin |

## Funções de string

### `concatena <elementos...> <delimitador>`

O último argumento é usado como delimitador.

```bash
concatena "a" "b" "c" ","   # → a,b,c
concatena "foo" "bar" "-"   # → foo-bar
concatena "x" "y" " "      # → x y
```

---

### `separa <string> [delimitador]`

Divide a string pelo delimitador. Se omitido, usa espaço.

```bash
separa "a,b,c" ","    # → a b c
separa "foo bar baz"  # → foo bar baz
```

---

### `trim <string>`

Remove espaços (e outros whitespace) do início e do fim.

```bash
trim "  olá mundo  "   # → olá mundo
nome=$(trim "$nome")
```

---

### `maiusculas <string>` / `minusculas <string>`

Converte a string inteira para maiúsculas ou minúsculas.

```bash
maiusculas "hello world"   # → HELLO WORLD
minusculas "HELLO WORLD"   # → hello world
```

---

### `comeca_com <string> <prefixo>`

```bash
comeca_com "arquivo.log" "arquivo"  # → 0 (verdadeiro)
comeca_com "arquivo.log" "log"      # → 1 (falso)

comeca_com "$var" "http" && echo "É uma URL"
```

---

### `termina_com <string> <sufixo>`

```bash
termina_com "arquivo.log" ".log"   # → 0 (verdadeiro)
termina_com "arquivo.log" ".txt"   # → 1 (falso)

termina_com "$arquivo" ".sh" || { erro "Esperado arquivo .sh"; exit 1; }
```

---

### `contem <string> <substring>`

```bash
contem "erro crítico no sistema" "crítico"   # → 0 (verdadeiro)
contem "erro crítico no sistema" "aviso"     # → 1 (falso)

contem "$linha" "FALHOU" && alerta "Linha com erro: $linha"
```

---

### `preenche_esquerda <string> <largura> [char]`

Preenche à esquerda para alinhar à direita. O caractere de preenchimento padrão é espaço.

```bash
preenche_esquerda "42" 6        # → "    42"
preenche_esquerda "42" 6 "0"   # → "000042"
preenche_esquerda "texto" 3    # → "texto"  (já maior que a largura)
```

---

### `preenche_direita <string> <largura> [char]`

Preenche à direita para alinhar à esquerda.

```bash
preenche_direita "nome" 10          # → "nome      "
preenche_direita "nome" 10 "-"      # → "nome------"
```

---

### `repete <string> <n>`

Repete a string N vezes sem separador.

```bash
repete "ab" 3    # → ababab
repete "-" 20    # → --------------------
```

## Funções de campos (stdin)

### `campo <num> [delimitador]`

Lê do stdin e extrai o campo N de cada linha usando awk. O delimitador padrão é espaço.

```bash
df -h | campo 5           # coluna "Use%" de cada linha
echo "a:b:c" | campo 2 ":"  # → b
ps aux | campo 1          # coluna de usuário
```

---

### `total <num> [delimitador]`

Lê do stdin e soma os valores numéricos do campo N em todas as linhas.

```bash
du -sb /var/log/* | total 1         # → soma dos tamanhos em bytes
cat vendas.csv | total 3 ","        # → soma da coluna 3
ps aux | campo 3 | total 1          # → soma do uso de CPU de todos os processos
```
